# Schema & Engine dùng chung cho Track YLE + Track TOEIC — Mimi English Pet

## 1. Mục tiêu

Cho phép app **Mimi English Pet** phục vụ 2 lộ trình khác nhau (YLE cho Bé
Bông hiện tại, TOEIC là lộ trình tương lai) mà chỉ cần **1 bộ code** cho:
ngân hàng câu hỏi, engine tạo đề, engine chấm điểm, và engine sinh báo cáo.
Chỉ **nội dung câu hỏi** và **cấu hình đề thi** khác nhau giữa 2 track — toàn
bộ logic xử lý là chung.

## 2. Sơ đồ tổng quan

```
QuestionBank (nạp từ JSON)
      │  .query(track, level, skill, topic, partNumber, questionType)
      ▼
MockTestEngine.startSession(TrackLevelConfig, mode)
      │  chọn ngẫu nhiên đủ số câu mỗi section theo config
      ▼
TestSession (đang làm bài — timer, lưu đáp án)
      │  .submitAnswer(questionId, answer)  x N lần
      ▼
MockTestEngine.finishAndScore(session, config)
      │  chọn ScoringStrategy theo config.scoringStrategyId
      ▼
TestScore  →  buildReport()  →  JSON hiển thị màn hình kết quả
```

## 3. Schema dữ liệu (file `lib/question_bank_models.dart`)

### `Question` — 1 câu hỏi trong ngân hàng
| Field | Ý nghĩa |
|---|---|
| `track` | `yle` \| `toeic` |
| `level` | YLE: `Starters`/`Movers`/`Flyers`/`KET`/`PET`. TOEIC: cố định `Standard` (xem mục 6.1) |
| `skill` | `vocabulary`/`grammar`/`listening`/`reading`/`writing`/`speaking` |
| `topic` | Dùng cho YLE, ví dụ `Animals`, `Food` (theo đúng các chủ đề Cambridge YLE công bố công khai) |
| `partNumber` | Dùng cho TOEIC, 1..7 |
| `questionType` | `multipleChoice`, `fillBlank`, `matching`, `ordering`, `shortAnswer`, `speakingPrompt`, `listenAndColor`, `listenAndNumber`, `trueFalse` |
| `media` | `{type: 'audio'|'image'|'none', url}` |
| `options` / `correctAnswer` | `correctAnswer` luôn là `List<String>` để dùng chung mọi dạng câu hỏi (xem comment trong code) |
| `tags` | Gắn thêm nhãn tự do, ví dụ `needsAudio` để đánh dấu câu chưa có file âm thanh thật |

### `SectionConfig` + `TrackLevelConfig` — cấu hình 1 đề thi/luyện tập
Một `TrackLevelConfig` (ví dụ "YLE Movers" hay "TOEIC Full Test") gồm nhiều
`SectionConfig` (ví dụ "Vocabulary", "TOEIC Part 5"), mỗi section quy định
lấy bao nhiêu câu, giới hạn giờ bao nhiêu, lọc theo topic/part nào.
→ Thêm 1 track/level mới (ví dụ sau này thêm `KET for Schools`) chỉ cần thêm
1 object JSON, **không cần sửa code**.

## 4. Engine (file `lib/mock_test_engine.dart`)

- **`TestSession`**: giữ danh sách câu hỏi đã chọn, đáp án của user, và đồng
  hồ đếm ngược (`remainingSeconds`, `isTimeUp`). Chế độ `practice` luôn bỏ
  qua giới hạn giờ dù config có set.
- **`ScoringStrategy`** (interface) — 3 cách chấm đã cài sẵn, chọn qua
  `scoringStrategyId` trong config:
  - `rawPercentage`: % đúng theo skill/tag, dùng chung/fallback.
  - `yleShield`: quy đổi ra khiên 1-5 theo từng skill (**thang tự thiết kế
    cho mục đích luyện tập, không phải thang điểm chính thức của Cambridge**).
  - `toeicScaled`: quy đổi gần đúng ra thang 10-990 theo đúng cấu trúc
    100 câu Listening / 100 câu Reading của đề thật (**xấp xỉ tuyến tính,
    ETS không công bố công thức quy đổi chính thức — cần ghi rõ trên UI
    rằng đây là điểm ước lượng**).
- **Câu hỏi Speaking** không bị chấm đúng/sai tự động — được tách riêng vào
  `TestScore.ungradedCount` để không làm sai lệch % của các kỹ năng khác.
  Trong tương lai, phần này có thể nối vào 1 dịch vụ chấm phát âm (speech-to-
  text + so khớp) mà không phải sửa lại phần lõi.
- **`buildReport()`**: gom điểm số + danh sách `weakTags` (chủ đề/kỹ năng có
  độ chính xác < 60%) thành 1 JSON để UI vẽ màn hình kết quả và gợi ý "Ôn lại
  ngay". Bạn tự nối `weakTags` → id bài học thật qua tham số
  `lessonRecommendationsByTag`.

## 5. Giai đoạn 1 đã triển khai — Nội dung track YLE (Movers → Flyers)

File `data/yle_movers_flyers_seed.json`: **31 câu hỏi mẫu**, trải đều:
- Movers (20 câu): vocabulary, grammar, reading, listening (placeholder chờ
  audio), writing (ordering), speaking (1 prompt), matching.
- Flyers (10 câu, khó hơn): idioms, passive voice, suy luận (inference),
  câu ghép dài hơn.
- Chủ đề bám theo đúng danh sách **chủ đề chính thức của Cambridge YLE**
  (Animals, Food, Family, Clothes, Weather, Places, Sport, Health...) để khi
  bạn bổ sung nội dung thật, cấu trúc topic vẫn nhất quán.

**Giới hạn cần biết**: đây là bộ **mẫu để bootstrap & kiểm chứng schema**,
không phải ngân hàng câu hỏi hoàn chỉnh — đề Movers/Flyers thật có hàng trăm
câu và nhiều audio thật. Các câu listening hiện đang đánh dấu tag
`needsAudio` (media.url = null) — cần thu âm hoặc dùng TTS chất lượng cao rồi
điền `url` thật vào.

## 6. Giai đoạn 2 đã triển khai — Mock Test Engine tổng quát

Đã có đầy đủ: chọn câu hỏi theo cấu hình, timer, 3 chiến lược chấm điểm, tách
riêng câu speaking, và sinh báo cáo điểm yếu. File `demo/demo_usage.dart`
minh hoạ chạy thử với dữ liệu mẫu (1 lượt YLE Movers + 1 lượt TOEIC Full
Test), in ra JSON kết quả để bạn xem đúng hình dạng dữ liệu trước khi vẽ UI.

### 6.1. Lưu ý riêng cho TOEIC
TOEIC không có khái niệm "level" như YLE (Starters/Movers/Flyers) — cả bài
thi chỉ có 1 mức, chia theo **Part 1-7**. Vì vậy mọi câu hỏi TOEIC trong
seed data dùng `level: "Standard"` cố định, và việc lọc theo phần thi dựa
hoàn toàn vào `partNumber`. Đây là điểm dễ nhầm khi bạn tự thêm câu hỏi
TOEIC — nhớ luôn để `level = "Standard"`.

Cấu trúc đề `TOEIC Full Test` trong `track_configs.json` đã theo đúng số
câu thật: Part 1 = 6, Part 2 = 25, Part 3 = 39, Part 4 = 30 (Listening,
100 câu), Part 5 = 30, Part 6 = 16, Part 7 = 54 (Reading, 100 câu).

**Giới hạn đã biết**: đề thật kiểm soát giờ theo 2 khối riêng (Listening 45
phút phát liên tục không tua lại, Reading 75 phút tự phân bổ) — engine hiện
tại chỉ hỗ trợ 1 đồng hồ tổng (`totalTimeLimitSeconds`). Với 11 câu mẫu hiện
có thì chưa cần độ chính xác này; khi build đủ nội dung thật cho track
TOEIC, nên nâng cấp `TestSession` thêm khái niệm "phase" (Listening phase /
Reading phase) để mô phỏng đúng trải nghiệm thi thật.

## 7. Cách tích hợp vào app Flutter hiện tại

1. Copy `lib/question_bank_models.dart` và `lib/mock_test_engine.dart` vào
   thư mục `lib/` của app (ví dụ `lib/exam_engine/`) — 2 file này thuần Dart,
   không đụng tới Flutter nên không xung đột với code hiện tại.
2. Copy 3 file JSON trong `data/` vào `assets/data/` của app, khai báo trong
   `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/data/yle_movers_flyers_seed.json
       - assets/data/toeic_seed.json
       - assets/data/track_configs.json
   ```
3. Nạp dữ liệu lúc khởi động (ví dụ trong 1 Provider/Riverpod/Bloc bạn đang
   dùng):
   ```dart
   final raw = await rootBundle.loadString('assets/data/yle_movers_flyers_seed.json');
   final bank = QuestionBank.fromJsonList(jsonDecode(raw) as List<dynamic>);
   ```
4. Màn hình "Làm đề thi thử" chỉ cần gọi `engine.startSession(...)`, render
   `session.questions`, gọi `session.submitAnswer(...)` mỗi khi user chọn,
   và hiển thị `session.remainingSeconds` cho đồng hồ đếm ngược.
5. Màn hình "Kết quả" gọi `engine.finishAndScore(...)` rồi `buildReport(...)`
   để lấy dữ liệu vẽ biểu đồ/khiên/điểm TOEIC + danh sách gợi ý ôn tập.

## 8. Danh sách file trong gói

```
mimi_common_schema/
├── THIET_KE_SCHEMA_CHUNG.md          (tài liệu này)
├── lib/
│   ├── question_bank_models.dart     (schema dữ liệu dùng chung)
│   └── mock_test_engine.dart         (engine tạo đề / chấm điểm / báo cáo)
├── data/
│   ├── track_configs.json            (cấu hình YLE Movers, Flyers, TOEIC Full Test)
│   ├── yle_movers_flyers_seed.json   (31 câu mẫu track YLE)
│   └── toeic_seed.json               (11 câu mẫu track TOEIC, đủ cả 7 part)
└── demo/
    └── demo_usage.dart               (script test độc lập ngoài Flutter)
```

## 9. Bước tiếp theo đề xuất

1. **Nội dung thật cho YLE Movers→Flyers**: mở rộng từ 31 câu mẫu lên đủ số
   lượng theo từng chủ đề, thu âm hoặc sinh audio TTS cho các câu listening.
2. **Chấm Speaking**: tích hợp speech-to-text (ví dụ Google Speech-to-Text
   hoặc Whisper) để tự động gợi ý điểm, vẫn giữ khả năng phụ huynh nghe lại
   và chỉnh tay.
3. **UI màn hình làm bài / kết quả**: dùng chung 1 bộ widget cho cả 2 track,
   chỉ đổi theme (pet-game cho YLE, dashboard nghiêm túc cho TOEIC) — vì dữ
   liệu đầu vào (`TestSession`, `TestScore`) đã có hình dạng giống nhau.
4. **TOEIC**: khi có nhu cầu thật, bổ sung nội dung Part 5-7 trước (dễ sinh
   bằng AI + kiểm duyệt), Part 1-4 cần audio chất lượng cao; đồng thời nâng
   cấp timer theo "phase" như nêu ở mục 6.1.

## 10. Cập nhật (2026-09-15) — đã bổ sung nội dung thật

Đã thực hiện mục 1 và phần đầu mục 4 ở trên. Số liệu trong mục 5/6.1/8 (31 câu
YLE, 11 câu TOEIC) **đã lỗi thời** — số liệu hiện tại trong
`assets/exam/*.json` của app:

- **YLE**: 111 câu (Movers 70, Flyers 41), phủ đủ các skill
  vocabulary/grammar/listening/reading/writing/speaking. `track_configs.json`
  cũng tăng số câu mỗi đề (Movers 24→37 câu, Flyers 10→19 câu) và giờ làm bài
  tương ứng để có chỗ cho việc chọn ngẫu nhiên (pool luôn lớn hơn số câu đề
  yêu cầu).
- **TOEIC**: 74 câu, tăng chủ yếu ở **Part 5 (30 câu — đã đủ số thật), Part 6
  (16 câu — đã đủ số thật), Part 7 (24/54 câu — mới đạt ~44%)**. Part 1-4
  (Listening) **giữ nguyên 1 câu/part** — đúng theo quyết định trong mục 9.4:
  chưa mở rộng vì cần thu âm/TTS chất lượng cao trước, thêm câu hỏi text-only
  không có audio thật không mang lại nhiều giá trị luyện tập.
- **Xác nhận phạm vi TOEIC**: track này chỉ mô phỏng **2 kỹ năng Listening +
  Reading** (đúng bài "TOEIC Listening & Reading" tiêu chuẩn) — KHÔNG có
  Speaking/Writing (bài thi 4 kỹ năng là "TOEIC Speaking & Writing", một kỳ
  thi khác, không nằm trong phạm vi app này). Ngân hàng câu hỏi TOEIC vì vậy
  không có `skill: speaking/writing` cho track `toeic`.

**Còn thiếu/việc tiếp theo**: Part 1-4 vẫn cần audio thật hoặc TTS chất lượng
cao để có giá trị luyện tập thật sự; Part 7 mới đạt gần một nửa số câu thật
(cần thêm khoảng 30 câu nữa để đạt 54); nội dung YLE vẫn là "nhiều hơn" chứ
chưa "đầy đủ như đề thật" (đề Movers/Flyers thật có hàng trăm câu).

## 11. Cập nhật (2026-09-16) — audioScript + mở rộng TOEIC Part 1-4/7

Giải quyết tiếp phần "còn thiếu" ở mục 10.

**Thay đổi schema/engine** (`lib/exam_engine/question_bank_models.dart`):
thêm field `audioScript` (optional) vào `Question` — nội dung THẬT được đọc
bằng TTS (hội thoại/thông báo/mô tả tranh), tách riêng khỏi `prompt` (chỉ
chứa câu hỏi/hướng dẫn hiển thị). Trước đây `prompt` của MỌI câu nghe (cả
YLE lẫn TOEIC) đều LỘ SẴN nội dung cần nghe ngay trên chữ hiển thị — về bản
chất chưa luyện nghe thật sự. Đã patch lại toàn bộ 19 câu nghe có từ trước
(15 YLE + 4 TOEIC Part 1-4) theo mẫu prompt/audioScript mới, và mọi câu nghe
thêm mới từ nay đều theo mẫu này.

**`TtsService.speak()`** (`lib/services/tts_service.dart`) nhận thêm tham số
tuỳ chọn `rate`/`pitch` — nội dung TOEIC dùng giọng tự nhiên hơn (rate 0.5,
pitch 1.0) thay vì giọng chậm + cao kiểu trẻ con mặc định (hợp bé 8 tuổi ở
track YLE, không hợp ngữ cảnh công sở). Xem cách dùng trong
`exam_screen.dart` (`_QuestionCard`).

**Mẫu nội dung mới cho từng Part TOEIC** (đúng tinh thần định dạng thật hơn):
- **Part 1** (không có ảnh thật): `prompt` = mô tả cảnh bằng chữ (thay ảnh),
  `audioScript` = 4 câu A/B/C/D đọc to — bé phải NGHE cả 4 câu rồi đối chiếu
  với mô tả cảnh để chọn đúng, không chỉ đọc chữ suông.
- **Part 2**: `prompt` chỉ là hướng dẫn chung ("Listen to the question..."),
  câu hỏi THẬT nằm trong `audioScript` — bé bắt buộc phải bấm nghe mới biết
  câu hỏi. Đúng số lựa chọn thật: **3 đáp án (A/B/C)**, không phải 4.
- **Part 3/4**: `prompt` = câu hỏi in sẵn (đúng định dạng thật), `audioScript`
  = toàn bộ hội thoại/bài nói — chỉ nghe được qua nút, không hiện trên UI.

**Số liệu mới** trong `assets/exam/*.json`:
- **TOEIC**: 74 → **154/200 câu (77%)**. Part 1 = 6/6, Part 2 = 25/25,
  Part 5 = 30/30, Part 6 = 16/16 (**4 part đã đủ số thật**). Part 3 = 13/39
  (33%), Part 4 = 10/30 (33%), Part 7 = 54/54 (**đủ số thật**, tăng từ 24).
- **YLE**: 111 → **136 câu** (Movers 85, Flyers 51) — thêm ở vocab/grammar/
  reading/writing/speaking; không thêm câu listening mới (pool hiện có đã đủ
  cho `track_configs.json`), chỉ nâng chất lượng 15 câu nghe cũ.

**Còn thiếu (thành thật)**: Part 1-4 dùng TTS mô phỏng — CHƯA phải audio
người thật (giọng TTS dù đã chỉnh tự nhiên hơn vẫn không thay được audio thu
âm chuẩn thi thật); YLE vẫn chưa đạt quy mô "hàng trăm câu" như đề thật.

## 12. Cập nhật (2026-09-16, tiếp) — TOEIC đạt ĐỦ 200/200 câu

Đã hoàn thiện nốt Part 3 (13 → **39/39**) và Part 4 (10 → **30/30**) theo
đúng yêu cầu ưu tiên. TOEIC giờ đạt **200/200 câu — đúng 100 câu Listening +
100 câu Reading theo cấu trúc đề thật ở cả 7 Part** (Part 1=6, Part 2=25,
Part 3=39, Part 4=30, Part 5=30, Part 6=16, Part 7=54). File
`track_configs.json` không cần đổi vì đã sẵn đúng số liệu thật này từ đầu -
giờ pool = đúng số cần, mỗi lượt "Thi thử có giờ" dùng trọn bộ 200 câu (đúng
tinh thần 1 đề full test thật, không phải rút ngẫu nhiên 1 phần).

Nội dung Part 3 (hội thoại 2 người, 2-4 lượt thoại) và Part 4 (bài nói/thông
báo 1 người) phủ đa dạng bối cảnh công sở: giao hàng, họp hành, khách sạn,
IT, tuyển dụng, sự kiện công ty, dịch vụ khách hàng, giao thông, du lịch...

**Giới hạn duy nhất còn lại của track TOEIC**: nội dung Part 1-4 mô phỏng
bằng TTS (giọng đọc máy, dù đã chỉnh tốc độ/cao độ tự nhiên hơn ở mục 11),
KHÔNG phải audio thu âm người thật như đề thi chính thức. Đây là giới hạn kỹ
thuật (không có ngân sách/hạ tầng thu âm), không phải thiếu nội dung — nếu
muốn audio thật, cần thuê thu âm hoặc dùng dịch vụ TTS trả phí chất lượng
cao hơn (ví dụ ElevenLabs, Google Cloud TTS WaveNet) rồi export file mp3 gắn
vào `media.url`.

## 13. Cập nhật (2026-09-16, tiếp) — mở rộng thêm YLE

Theo đúng yêu cầu: **YLE giữ đủ 6 hạng mục kỹ năng** (vocabulary, grammar,
listening, reading, writing, speaking — ứng với 4 kỹ năng nghe/nói/đọc/viết
truyền thống + từ vựng/ngữ pháp hỗ trợ), KHÁC với track TOEIC chỉ mô phỏng 2
kỹ năng Listening + Reading (đã xác nhận lại ở mục 10 — không đổi).

**Số liệu mới**: YLE 136 → **240 câu** (Movers 143, Flyers 97), tăng đều ở
cả 6 hạng mục kỹ năng cho cả 2 track. Câu nghe mới tiếp tục theo đúng mẫu
prompt/audioScript đã thiết lập ở mục 11 (không lộ đáp án trên chữ hiển
thị). `track_configs.json` cũng tăng số câu mỗi đề để dùng nhiều hơn ngân
hàng câu hỏi lớn hơn này (Movers 37→51 câu, Flyers 19→36 câu), vẫn giữ pool
lớn hơn số câu đề yêu cầu (khoảng 2.5 lần) để mỗi lượt "Luyện tập" vẫn ra bộ
câu khác nhau.

Chủ đề mới bổ sung bám theo danh sách chủ đề chính thức Cambridge YLE (ví
dụ: Kitchen, Farm Animals, Celebrations, Geography, Weather Phenomena, Used
To, Second Conditional...) để không trùng lặp với nội dung đã có.

**Còn thiếu (thành thật)**: dù đã tăng đáng kể, YLE **vẫn chưa đạt quy mô
"hàng trăm câu mỗi track" như đề thi thật đầy đủ** (đề Movers/Flyers chính
thức có ngân hàng câu hỏi lớn hơn nhiều, đủ để không lặp lại qua nhiều năm
thi) — 240 câu là bước tiến lớn so với 31 câu ban đầu, nhưng vẫn là tập mẫu
đang được mở rộng dần, không phải ngân hàng câu hỏi hoàn chỉnh.
