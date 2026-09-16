# Mimi English Pet 🐰

Ứng dụng cho bé gái 8 tuổi vừa chơi vừa học tiếng Anh cùng thú cưng ảo Mimi
(tham khảo trải nghiệm của Buddy AI). Xây bằng Flutter, kiến trúc Clean
Architecture (UI / Business Logic / Data tách riêng), MIỄN PHÍ hoàn toàn.

**CẬP NHẬT (2026-09-16)**: app KHÔNG còn "offline-first thuần" như mô tả ở
các mục bên dưới (viết từ giai đoạn MVP đầu tiên, giữ nguyên làm nhật ký xây
dựng) - đã thêm **backend (FastAPI, thư mục `backend/`) + đăng nhập +
đồng bộ cloud** để chạy được trên cả web public (không chỉ app di động), chủ
yếu vì gia đình dùng iOS không cài được app iOS miễn phí. Mọi
`Local*Repository` nhắc tới bên dưới nay là `Cloud*Repository` (đọc/ghi qua
backend, vẫn giữ cache cục bộ để dùng tạm khi mất mạng). Xem `deployment.md`
để biết kiến trúc mới + cách deploy, `backend/README.md` cho phần backend.
Giai đoạn 4 (AI qua proxy giấu key) và Giai đoạn 6 (đồng bộ cloud) ở phần
"Đề xuất bước tiếp theo" cuối file coi như ĐÃ HOÀN THÀNH.

## Đã có gì trong MVP v0.1 này

- **Home**: bé chào hỏi thú cưng, bấm mic nói "Hello!" và thú cưng nghe/trả
  lời lại bằng giọng nói (nhận diện & đọc tiếng Anh ngay trên máy). Bé có thể
  **chọn 1 trong 5 nhân vật** - 🐰 Bunny, 🐱 Mimi (mặc định), 🐢 Moni, 🐿️ Ran
  (sóc, mới 2026-08-23), 🐧 Pingo (chim cánh cụt, mới 2026-08-23) - xem mục
  "Hình ảnh thú cưng & chọn nhân vật" bên dưới. Mỗi nhân vật có **1 màu mặc
  định riêng** (2026-08-22: Bunny hồng phấn, Mimi trắng, Moni da trời; Ran/
  Pingo mặc định đúng màu tự nhiên của loài - nâu/đen - đổi nhân vật KHÔNG đổi
  màu của nhân vật kia) nhưng bé vẫn tự chọn màu khác cho từng con bất cứ lúc
  nào qua hàng chấm màu. Thú cưng còn có thể **mặc phụ kiện** (mũ/nơ/vòng
  hoa...) mở khoá từ tab Rewards - xem mục "Phụ kiện thời trang cho thú cưng"
  bên dưới. Ngoài 3 nút chơi cùng gốc (Xoay vòng/Nhảy chơi/Cho ăn), từ
  2026-08-23 có thêm **3 nút Tắm 🛁/Đi ngủ 🌙/Tập thể dục 🤸** - xem mục "Vòng
  11" bên dưới.
- **Play**: **bản đồ bài học** kiểu Duolingo - hiện có **9 bài** (3 bài nhập
  môn: Animals & Colors - 10 từ, Family - 6 từ, Numbers 1-5 - 6 từ; + 6 bài
  mức **Movers** thêm ngày 2026-08-21: Weather & Seasons, Feelings, Actions &
  Sports, Food & Drinks, Clothes, Transportation - mỗi bài 10 từ), mỗi bài là
  1 điểm dừng trên con đường. Toàn bộ 9 bài đang **mở khoá sẵn** để bé chủ
  động chọn bài học bất kỳ (không cần hoàn thành bài trước mới mở bài sau) -
  xem mục "Gamification: Tim, Streak, bản đồ bài học" bên dưới để biết cách
  bật lại khoá tuần tự nếu sau này cần. Trong 1 bài, câu hỏi **xen kẽ 6
  KIỂU** khác nhau (nói, chọn trắc nghiệm, điền từ, sắp xếp câu, chính tả,
  luyện phát âm) - xem mục "6 kiểu bài tập trong 1 bài học" bên dưới để biết
  chi tiết. Trả lời sai sẽ **mất 1 tim** (bài ôn lại - đã thuộc hết từ - thì
  không mất tim); hết tim phải chờ hồi phục mới học tiếp được. Có **âm thanh
  hiệu ứng** khi đúng/sai/mất tim/hoàn thành bài.
- **Chat**: tab mới - bé **tâm sự tự do** với thú cưng (gõ chữ hoặc nói),
  dùng Gemini AI với System Prompt kiểm soát nội dung chặt chẽ khi đã có API
  key, và **tự động** dùng chatbot offline (câu trả lời có sẵn) khi CHƯA có
  key - tab Chat luôn dùng được ngay, không cần chờ cấu hình gì. Xem mục
  "LLM: Tâm sự với thú cưng (Gemini)" bên dưới để lấy API key miễn phí. Từ
  2026-08-22, màn Chat có thêm **thú cưng động** ở đầu màn hình (đúng nhân
  vật/màu/phụ kiện đã chọn ở Home, tự "diễn" nghe/suy nghĩ/nói theo đúng lúc),
  1 avatar tròn nhỏ cạnh mỗi tin nhắn của thú cưng, và nút **"Nghe lại"** (🔁)
  để phát lại giọng đọc + animation của 1 câu trả lời cũ MÀ KHÔNG gọi lại AI -
  xem mục "Thú cưng động & Nghe lại ở Chat" bên dưới. Từ 2026-08-23, tin nhắn
  của bé cũng có **avatar riêng** (chọn ở Settings) và có thể được **gợi ý sửa
  ngữ pháp** nhẹ nhàng (💡) - xem mục "Avatar của bé & Gợi ý ngữ pháp ở Chat"
  bên dưới. Từ 2026-08-23, mỗi tin nhắn của thú cưng còn có **nút dịch 🌐**
  (dịch câu thoại sang tiếng Việt ngay khi bấm) - xem mục "Vòng 11" bên dưới.
- **Rewards**: tổng số sao, **Cửa hàng phụ kiện** (mở khoá dần bằng sao, mặc
  cho thú cưng - xem mục "Phụ kiện thời trang cho thú cưng" bên dưới), và bộ
  sưu tập các từ bé đã thuộc.
- **Từ điển** (tab mới, 2026-08-23): tra nghĩa 1 từ/câu 2 CHIỀU Anh-Việt, nghe
  phát âm chuẩn (TTS) và kiểm tra bé đọc theo có đúng không (mic) - xem mục
  "Vòng 11" bên dưới.
- **Settings**: kiểm tra mic/giọng đọc, làm lại từ đầu, **chọn avatar riêng
  cho bé** (emoji hoặc ảnh từ máy, 2026-08-23) - xem mục "Avatar của bé & Gợi
  ý ngữ pháp ở Chat" bên dưới - và (mới, 2026-08-23) **đặt tên riêng cho bé**
  để thú cưng gọi tên khi tương tác - xem mục "Vòng 11" bên dưới.
- Thanh trên cùng có 3 huy hiệu: ⭐ số sao, ❤️ số tim còn lại, 🔥 số ngày học
  liên tiếp (streak) - xem mục "Gamification: Tim, Streak, bản đồ bài học"
  bên dưới để biết chi tiết cách hoạt động. Từ 2026-08-23, đạt 1 streak MỚI có
  thêm **hiệu ứng ăn mừng** (confetti + âm thanh) - xem mục "Vòng 11" bên dưới.
- Mimi có 6 trạng thái cảm xúc (idle/listening/thinking/talking/happy/
  encourage), mỗi trạng thái dùng **ảnh nhân vật thật** (tách từ character
  sheet Mimi do ChatGPT tạo - xem `assets/images/README.md`), kèm hoạt ảnh
  thở nhẹ + "nảy lên" khi đổi mood.
- Tiến độ (số sao, từ đã thuộc) được lưu ngay trên máy, không mất khi tắt app.

## Cách chạy thử

```bash
cd mimi_pet
flutter pub get
flutter run -d chrome   # hoặc -d <tên máy ảo/điện thoại>
```

Lần đầu chạy trên điện thoại thật, hệ điều hành sẽ hỏi quyền **Micro** - bé
cần đồng ý thì Mimi mới nghe được. Voice input hoạt động tốt nhất trên
điện thoại/tablet thật; trên Chrome cần cấp quyền micro cho trình duyệt.

Muốn đưa bản web lên mạng để xem qua link (Vercel/GitHub Pages, miễn phí),
xem hướng dẫn chi tiết trong [`deployment.md`](deployment.md).

## Xuất file APK để cài trực tiếp lên điện thoại Android

```bash
cd mimi_pet
flutter build apk --release
```

File APK nằm ở `build\app\outputs\flutter-apk\app-release.apk` (khoảng vài
chục MB). Project đã cấu hình sẵn để bản release dùng chung "debug signing
key" (xem `android/app/build.gradle.kts`) nên cài được ngay, không cần tự
tạo keystore riêng - chỉ dùng để cài cho gia đình dùng, KHÔNG dùng để đăng
lên Google Play (đăng Play Store cần tự tạo keystore ký riêng, nhiều bước
hơn, chưa cần thiết ở giai đoạn này).

Đưa file này sang điện thoại bằng 1 trong các cách: cắm cáp USB kéo-thả vào
thư mục Download của điện thoại, gửi qua Zalo/Google Drive/email cho chính
mình rồi tải về, hoặc (nhanh nhất nếu điện thoại đã bật **USB debugging** và
đang cắm cáp) chạy thẳng:

```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

Trên điện thoại, mở file APK vừa tải/copy về - Android sẽ hỏi "Cho phép cài
đặt từ nguồn không xác định" (vì không cài từ CH Play) - bật quyền đó cho
ứng dụng bạn dùng để mở file (Files/Chrome/Zalo...) rồi bấm Cài đặt. Lần đầu
mở app, nhớ đồng ý quyền **Micro** khi được hỏi thì Mimi mới nghe được.

Muốn file nhẹ hơn (vì 1 file APK "chuẩn" chứa mã cho mọi loại chip CPU), có
thể build riêng theo kiến trúc máy:

```bash
flutter build apk --release --split-per-abi
```

Lệnh này tạo ra 3 file nhỏ hơn trong cùng thư mục (`app-armeabi-v7a-release.apk`,
`app-arm64-v8a-release.apk`, `app-x86_64-release.apk`) - điện thoại đời mới
hầu hết dùng `arm64-v8a`, nhưng nếu không chắc thì cứ dùng file APK "chuẩn"
(không split) ở trên cho đơn giản, khỏi phải chọn đúng file.

## Kiến trúc thư mục (Clean Architecture)

```
lib/
  domain/            # Entity + interface thuần Dart, không phụ thuộc Flutter/plugin
    entities/         Word, Lesson, PetMood, PetCharacter (5 con), PetPalette,
                        PetAccessory, ChildAvatar (avatar riêng của bé),
                        DictionaryLookupResult (mới - kết quả tra từ điển)
    repositories/      interface ProgressRepository, PetCharacterRepository,
                        HeartsRepository, StreakRepository, LessonRepository,
                        ChildAvatarRepository, ChildNameRepository (mới - tên
                        riêng của bé)...
    usecases/          EvaluateAnswer (chấm đúng/sai - có thêm `callPhrase`
                        cho câu dài, dùng ở Từ điển)
  data/               # Cài đặt cụ thể cho domain
    content/           lessons_data.dart - ĐÃ NGỪNG DÙNG, xem ghi chú trong file
    repositories/       LocalProgressRepository, LocalHeartsRepository,
                        LocalStreakRepository, JsonLessonRepository,
                        LocalChildNameRepository (mới)... (SharedPreferences
                        cho tiến độ/tim/streak/tên bé, JSON asset cho nội dung bài học)
  services/           # Bọc các plugin/API bên thứ 3 (speech_to_text, flutter_tts,
                        audioplayers) + "bộ não" chat: ChatReplyService (interface,
                        có thêm `translateToVietnamese`), GeminiChatService (Gemini
                        REST), OfflineChatService (câu trả lời có sẵn),
                        CompositeChatService (tự chọn giữa 2 cái trên) + "bộ não"
                        từ điển: DictionaryService (interface, mới) /
                        GeminiDictionaryService (mới)
  presentation/
    state/             Controllers (ChangeNotifier): Pet/PetCharacter/PetPalette/
                        Progress/Hearts/Streak/Lessons/Lesson/Chat/ChildName (mới)/
                        Dictionary (mới)
    widgets/           Component tái sử dụng: PetAvatar, TalkButton, HeartsBadge,
                        StreakBadge, StreakCelebration (mới - hiệu ứng ăn mừng)...
    screens/           Home, Play (bản đồ bài học), Lesson, Rewards, Chat,
                        Dictionary (mới - tab Từ điển), Settings, Root shell
  core/theme/         Màu sắc & theme dùng chung
  core/config/        Cấu hình (api_config.dart - URL backend qua --dart-define)
  app.dart             Composition root - nơi DUY NHẤT nối domain <-> data
  main.dart
assets/
  lessons/lessons.json  # Nội dung bài học (xem "Cách thêm bài học mới")
  sounds/*.wav           # Hiệu ứng âm thanh tự tổng hợp (xem scripts/generate_sounds.py) -
                          # có thêm streak.wav (mới, mục "Vòng 11" bên dưới)
```

Nguyên tắc: **UI (screens/widgets) không chứa business logic** - mọi luồng
xử lý (chấm câu trả lời, đổi mood, cộng sao...) nằm trong
`presentation/state/*_controller.dart`. Muốn đổi cách lưu dữ liệu (ví dụ
sau này lên cloud) chỉ cần viết `ProgressRepository` mới, không phải sửa UI.

## Cách thêm bài học mới (không cần đụng vào code)

Từ bản Gamification trở đi, bài học đọc từ **file JSON tĩnh**
`assets/lessons/lessons.json` (qua `JsonLessonRepository` +
`LessonsController`) thay vì hard-code bằng Dart class - **không cần sửa
code Dart**, chỉ cần sửa file JSON này rồi build lại app. Ví dụ thêm 1 bài
"Body parts":

```json
{
  "id": "body_parts_v1",
  "title": "Body Parts",
  "emoji": "🖐️",
  "words": [
    { "id": "hand", "en": "hand", "vi": "bàn tay", "emoji": "🖐️", "promptType": "identify" },
    { "id": "eye", "en": "eye", "vi": "mắt", "emoji": "👁️", "promptType": "identify" }
  ]
}
```

Thêm object này vào mảng `"lessons"` trong file JSON. Lưu ý:
- Mỗi `Word` cần **ít nhất 1 trong 2**: `"emoji"` hoặc `"swatchColor"` (mã màu
  ARGB hex, ví dụ `"FFEF5350"` - byte đầu `FF` là alpha/độ đục).
- `"promptType"`: `"identify"` (mặc định, Mimi hỏi "What's this?") hoặc
  `"repeat"` (Mimi đọc mẫu, bé lặp lại - dùng cho hello/goodbye...).
- Nên có **từ 4 từ trở lên** mỗi bài để câu hỏi trắc nghiệm (xem mục
  Gamification bên dưới) luôn đủ 3 lựa chọn.
- Bài học mới sẽ **nối vào cuối con đường** ở tab Play. Hiện tại (2026-08-21)
  toàn bộ bài học đều **mở khoá sẵn** (xem mục "Gamification: Tim, Streak,
  bản đồ bài học" bên dưới) nên bài mới cũng mở ngay, không cần học xong bài
  trước - nếu sau này bật lại khoá tuần tự thì bài mới sẽ theo đúng cơ chế
  đó (khoá tới khi xong bài ngay trước nó).

Màn Play, Rewards, và toàn bộ lesson engine tự động nhận bài học mới, không
cần sửa gì thêm. (Nếu sau này muốn chuyển hẳn sang SQLite, chỉ cần viết 1
implementation khác của `LessonRepository` mà không phải sửa UI.)

## Hình ảnh thú cưng & chọn nhân vật

Thú cưng hiện được **vẽ trực tiếp bằng vector** (Canvas) - không dùng ảnh PNG
nữa - luôn nét ở mọi kích thước màn hình, không tốn dung lượng ảnh, và từng
bộ phận (tai, mắt, miệng...) animate mượt độc lập nhau. Bộ 6 ảnh PNG cũ (lấy
từ screenshot ChatGPT) vẫn còn giữ trong `assets/images/` để tham khảo/dự
phòng, xem `assets/images/README.md`.

Bé có thể **chọn 1 trong 3 nhân vật** ngay ở tab Home (mặc định là mèo
**Mimi**):

- 🐰 **Bunny** (thỏ) - có tai dài, vẫy/kéo tai được.
- 🐱 **Mimi** (mèo, mặc định) - tai tam giác, vẫy/kéo tai được, có râu.
- 🐢 **Moni** (rùa) - không có tai (chạm vào rùa luôn tính là chạm THÂN); thay
  vào đó đầu rùa tự nhô ra/rụt vào mai theo animation "thở".

Kiến trúc chia làm 2 lớp tách biệt, xem
`lib/presentation/widgets/mimi_painter.dart` và
`lib/presentation/widgets/pet_character_painters.dart`:

- **`MimiPose`** (trong `mimi_painter.dart`) - "dáng" chung do
  `PetAvatar`/`AnimationController` tính mỗi khung hình (thở, chớp mắt, vẫy
  tai, nói chuyện, vui...), KHÔNG biết đang vẽ con nào.
- **`BunnyPainter` / `MimiCatPainter` / `MoniTurtlePainter`** (trong
  `pet_character_painters.dart`) - vẽ CustomPainter riêng cho từng con, nhận
  tham số bề mặt khác nhau (thỏ+mèo có tai, rùa có `headYOffset` thay vì tai).
  Hàm `buildPetCharacterPainter(character, pose)` là nơi DUY NHẤT dịch 1
  `MimiPose` dùng chung sang đúng tham số của từng nhân vật.

Nhân vật bé chọn được lưu qua `PetCharacterController` +
`PetCharacterRepository` (SharedPreferences, key `mimi.selected_character`) -
cùng nguyên tắc với `ProgressController`, nên giữ đúng lựa chọn giữa các lần
mở app. Muốn thêm nhân vật thứ 4: thêm 1 giá trị vào enum `PetCharacter`
(`lib/domain/entities/pet_character.dart`), thêm `PetCharacterInfo` (tên +
emoji), viết 1 `CustomPainter` mới, rồi nối vào
`buildPetCharacterPainter`/`hitTestPetCharacter` trong
`pet_character_painters.dart`.

### Chọn màu (lông/mai)

Bé có thể **chọn màu riêng** cho thú cưng ngay dưới hàng chọn nhân vật ở
Home - 5 màu: **Gốc** (màu nguyên bản), **Trắng**, **Da trời**, **Bạc hà**,
**Hồng phấn**. Chọn màu ĐỘC LẬP với chọn nhân vật - đổi con không mất màu và
ngược lại.

**MỖI NHÂN VẬT NHỚ 1 MÀU RIÊNG (2026-08-22)**: trước đây cả 3 con dùng
CHUNG 1 màu đang chọn (đổi màu lúc đang xem thỏ thì mèo/rùa cũng đổi theo).
Giờ đổi màu chỉ áp dụng cho ĐÚNG nhân vật đang xem, và mỗi nhân vật có sẵn 1
màu mặc định riêng ngay từ lần mở app đầu tiên (chưa cần bé tự chọn gì):
**Bunny → Hồng phấn**, **Mimi → Trắng**, **Moni → Da trời** (nhân vật mặc
định khi mở app vẫn là Mimi, không đổi). Bé vẫn có thể tự đổi màu khác cho
từng con bất cứ lúc nào, lựa chọn được nhớ riêng cho từng con giữa các lần
mở app. *Lưu ý: vì đổi cách lưu (key SharedPreferences cũ dùng chung 1 key,
giờ tách theo từng nhân vật), lần build đầu tiên sau bản cập nhật này màu bé
đã từng tự chọn trước đây sẽ về lại đúng màu mặc định mới của từng con - chỉ
xảy ra 1 LẦN DUY NHẤT, không mất tiến độ học/sao/phụ kiện.*

Kiến trúc cùng khuôn với hệ thống nhân vật: `PetPalette` (enum, xem
`lib/domain/entities/pet_palette.dart`, có thêm hàm `defaultPaletteFor(character)`)
+ `PetPaletteController` (giờ giữ 1 `Map<PetCharacter, PetPalette>` thay vì 1
giá trị đơn, gọi `paletteFor(character)`/`select(character, palette)`) +
`PetPaletteRepository` (SharedPreferences, 1 key riêng mỗi nhân vật dạng
`mimi.selected_palette.<tên nhân vật>`). Bảng màu THẬT (mã màu cụ thể cho
từng nhân vật ở từng palette) nằm trong `pet_character_painters.dart`
(`bunnyPaletteColors`/`catPaletteColors`/`turtlePaletteColors`) - vì mỗi
nhân vật cần 1 bộ màu riêng để "Trắng" ở mèo và "Trắng" ở thỏ đều đẹp/hợp lý
(không thể dùng chung 1 mã màu). Muốn thêm màu mới: thêm 1 giá trị vào enum
`PetPalette`, thêm `PetPaletteInfo` (tên + chấm màu hiển thị), thêm 1 dòng
vào MỖI bảng màu của cả 3 nhân vật, và (nếu muốn) 1 dòng vào
`defaultPaletteByCharacter` nếu màu mới này nên là mặc định cho 1 nhân vật
nào đó.

Đổi TRANG PHỤC/phụ kiện (nơ, mũ...) cho thú cưng - khác với đổi màu (chỉ
recolor hình có sẵn) - ĐÃ LÀM từ 2026-08-22, xem mục "Phụ kiện thời trang
cho thú cưng" bên dưới.

## Gamification: Tim, Streak, bản đồ bài học (2026-08-21)

Toàn bộ phần này **tự viết theo đúng kiến trúc Clean Architecture sẵn có**
(không dùng/fork repo mã nguồn mở nào - đã khảo sát các repo Duolingo-clone
bằng Flutter trên GitHub nhưng không có repo nào đủ chất lượng/còn bảo trì để
tận dụng an toàn cho app của bé).

- **Tim (Hearts)** - `HeartsController` + `HeartsRepository`
  (`lib/domain/repositories/hearts_repository.dart`,
  `lib/presentation/state/hearts_controller.dart`): tối đa **5 tim**, mất 1
  tim mỗi lần trả lời sai (bài ôn lại - đã thuộc hết từ trong bài - thì KHÔNG
  mất tim), **tự hồi phục** dần theo thời gian (1 tim / 2 giờ) mà không cần
  bé xem quảng cáo hay phụ huynh trả tiền (khác cơ chế thương mại hoá của
  Duolingo - phù hợp hơn cho app học của bé 8 tuổi). Hết tim giữa bài sẽ dừng
  bài học lại, hiện màn hình nhẹ nhàng báo chờ tim hồi phục.
- **Streak** - `StreakController` + `StreakRepository`: đếm số ngày học liên
  tiếp, cộng thêm 1 mỗi khi bé hoàn thành ít nhất 1 bài học/ngày, về lại 1
  nếu bỏ lỡ 1 ngày trở lên. Lưu theo ngày (chuỗi `yyyy-MM-dd`), không phụ
  thuộc giờ/múi giờ chính xác.
- **2 kiểu câu hỏi xen kẽ** - `LessonController` (thêm `QuestionKind`): từ có
  vị trí chẵn trong bài hỏi theo kiểu **nói** như trước giờ, từ vị trí lẻ hỏi
  theo kiểu **chọn trắc nghiệm** (2 từ ngẫu nhiên khác trong cùng bài làm
  "mồi nhử" + đáp án đúng, xáo trộn vị trí). Từ kiểu `promptType: "repeat"`
  (hello/goodbye...) LUÔN hỏi theo kiểu nói vì mục đích là tập phát âm.
- **Bản đồ bài học** - `PlayScreen` viết lại thành con đường ngoằn ngoèo kiểu
  Duolingo: mỗi bài học là 1 điểm tròn (mở/hoàn thành ⭐). Cơ chế khoá tuần tự
  (bài sau chỉ mở khi bài ngay trước đã hoàn thành 100%) **vẫn còn trong
  code** nhưng đang **TẮT** (2026-08-21, theo yêu cầu người dùng: bé đã đạt
  trình độ Mover, "chưa cần khoá ở giai đoạn này" để bé tự do chọn bài) - xem
  cờ `PlayScreen._sequentialLockingEnabled` trong
  `lib/presentation/screens/play/play_screen.dart`, đổi thành `true` để bật
  lại khoá tuần tự bất cứ lúc nào mà không cần viết lại logic.
- **Âm thanh hiệu ứng** - `SoundService` (dùng package `audioplayers`) phát
  4 hiệu ứng ngắn: đúng, sai, hoàn thành bài, mất tim. Toàn bộ file
  `assets/sounds/*.wav` do **app tự tổng hợp** bằng sóng sine qua
  `scripts/generate_sounds.py` (chỉ dùng thư viện chuẩn Python, không lấy âm
  thanh có bản quyền của bên thứ ba) - muốn đổi âm thanh, sửa script này rồi
  chạy lại `python3 scripts/generate_sounds.py`.

Chưa làm (có thể làm sau): huy hiệu thành tích, đường nối liền giữa các điểm
trên bản đồ (hiện chỉ xếp zíc-zắc, chưa vẽ đường nối để giảm rủi ro lệch hình
khi không có cách xem app thật chạy). Shop đổi sao lấy phụ kiện ĐÃ LÀM từ
2026-08-22, xem mục ngay bên dưới.

## Phụ kiện thời trang cho thú cưng (2026-08-22)

Bé dùng SỐ SAO TÍCH LUỸ (không trừ khi tiêu, xem `ProgressController.stars`)
để mở khoá dần các phụ kiện, rồi mặc cho thú cưng ở tab Rewards - phần
"Cửa hàng phụ kiện". Món đang mặc hiển thị NGAY trên Home (và cả Chat/Lesson
để nhất quán) - vẽ đè lên đúng nhân vật/màu đang chọn.

6 phụ kiện, chia làm 2 vị trí (mỗi vị trí mặc tối đa 1 món cùng lúc):

| Vị trí | Phụ kiện | Sao cần có |
|---|---|---|
| Cổ | 🎀 Nơ cổ | 5 |
| Đầu | 🥳 Mũ tiệc | 10 |
| Cổ | 🧣 Khăn quàng | 20 |
| Đầu | 🌸 Vòng hoa | 35 |
| Đầu | 👑 Vương miện | 50 |
| Cổ | 🏅 Huy chương | 80 |

Chạm vào 1 món ĐÃ mở khoá để MẶC (chạm lại lần nữa để CỞI RA); chạm vào món
CHƯA đủ sao sẽ chỉ báo còn thiếu bao nhiêu sao, không cho mặc thử.

Kiến trúc theo đúng khuôn các hệ thống khác trong app (domain entity + data
repository SharedPreferences + presentation controller):
- `lib/domain/entities/pet_accessory.dart` - enum `PetAccessoryId` (6 món) +
  `AccessorySlot` (head/neck) + `PetAccessoryInfo` (tên, emoji cho thẻ ở
  Rewards, số sao cần có).
- `lib/domain/repositories/pet_inventory_repository.dart` +
  `lib/data/repositories/local_pet_inventory_repository.dart` - CHỈ lưu
  "đang mặc gì" (2 key, 1 cho mỗi vị trí) - KHÔNG lưu "đã mở khoá món nào",
  trạng thái mở khoá luôn tính lại từ số sao hiện tại so với `unlockStars`
  của từng món, tránh 2 nguồn dữ liệu (mở khoá + số sao) có thể lệch nhau.
- `lib/presentation/state/pet_inventory_controller.dart` - `PetInventoryController`,
  có `equip(id)` (tự cởi món cũ cùng vị trí, bấm lại món đang mặc để cởi ra)
  và `resetEquipped()` (gọi kèm lúc bé "Làm lại từ đầu" ở Settings, tránh còn
  hiển thị món đã mở khoá bằng số sao vừa bị xoá).
- `lib/presentation/widgets/pet_accessory_painter.dart` - vẽ hình phụ kiện
  (vector, Canvas thuần - cùng kỹ thuật với 3 nhân vật) ĐÈ LÊN thú cưng SAU
  khi đã vẽ xong nhân vật. Dùng CHUNG 1 hình vẽ cho phụ kiện, chỉ đổi "điểm
  neo" (vị trí đầu/cổ) theo từng nhân vật - đỡ phải vẽ riêng 6 phụ kiện x 3
  nhân vật = 18 lần.

**LƯU Ý QUAN TRỌNG**: toạ độ đặt phụ kiện (điểm neo đầu/cổ của từng nhân vật)
là ƯỚC LƯỢNG dựa theo công thức hình học có sẵn của 3 painter nhân vật -
môi trường này KHÔNG có cách chạy thử app Flutter thật để canh chỉnh bằng
mắt. Nếu build thử thấy phụ kiện lệch (đè lên mắt/tai, trôi ra ngoài đầu,
không thẳng hàng...), chụp ảnh màn hình gửi lại để chỉnh chính xác toạ độ
trong `_headAnchor`/`_neckAnchor` (`pet_accessory_painter.dart`) - đúng cách
đã làm khi debug model Gemini trước đây: lấy bằng chứng THẬT từ app thay vì
đoán thêm.

Muốn thêm phụ kiện mới: thêm 1 giá trị vào enum `PetAccessoryId`, thêm 1
entry vào `PetAccessoryInfo.all` (chọn `slot`/`emoji`/`unlockStars`), rồi
viết 1 hàm vẽ mới + nối vào `_paintHeadAccessory`/`_paintNeckAccessory` trong
`pet_accessory_painter.dart`.

## 6 kiểu bài tập trong 1 bài học (2026-08-21)

Trong 1 bài học, mỗi từ sẽ được hỏi theo 1 trong 6 kiểu dưới đây (xoay vòng
theo vị trí từ trong bài - xem `QuestionKind` + `LessonController.currentQuestionKind`
trong `lesson_controller.dart`), thay vì chỉ mỗi kiểu "nói" như bản đầu:

1. **Nói** (`speak`) - Mimi hỏi kèm hình/màu ("What's this?"), bé bấm mic
   nói từ tiếng Anh - chấm bằng giọng nói như bản gốc.
2. **Chọn trắc nghiệm** (`choice`) - bé chọn đúng từ trong 2-3 lựa chọn.
3. **Điền từ** (`fillBlank`) - 1 câu ngắn có chỗ trống (ví dụ "I have a
   ___."), bé CHỌN từ đúng trong vài lựa chọn để điền vào (không gõ, đúng
   phong cách Duolingo cho người mới).
4. **Sắp xếp câu** (`reorder`) - các từ trong 1 câu bị xáo trộn thành từng
   mảnh, bé CHẠM chọn theo đúng thứ tự để ghép lại thành câu hoàn chỉnh, có
   nút "Xoá" để bỏ mảnh chọn nhầm gần nhất.
5. **Chính tả** (`dictation`) - Mimi đọc từ, bé **gõ bàn phím** để viết lại
   đúng chính tả (theo lựa chọn của bạn - gõ tự do, không dùng ngân hàng chữ
   cái hỗ trợ) - chấm bằng cùng bộ so khớp khoan dung (`EvaluateAnswer`) như
   kiểu Nói, vẫn cho phép sai lệch nhỏ.
6. **Luyện phát âm** (`pronunciation`) - dùng cho các từ dạng "repeat"
   (hello/goodbye...): bé nói theo Mimi, sau đó Mimi LUÔN đọc lại phát âm
   chuẩn để bé so sánh - kiểu bài này KHÔNG chấm đúng/sai nghiêm ngặt và
   KHÔNG trừ tim (mục đích là luyện tập/làm quen âm thanh, không phải kiểm
   tra), luôn khích lệ dù bé nói chưa chuẩn.

Dữ liệu cho kiểu 3 và 4 (câu mẫu) nằm ngay trong `assets/lessons/lessons.json`,
ở 2 trường mới trên mỗi từ:
- `"sentenceTemplate"`: câu có `___` đánh dấu chỗ trống, ví dụ `"I have a ___."`.
- `"sentenceWords"`: câu hoàn chỉnh tách sẵn thành từng từ, ví dụ
  `["I", "have", "a", "cat"]` (cần ít nhất 3 từ).

Từ nào KHÔNG có 2 trường này sẽ tự động bỏ qua kiểu bài tương ứng (không lỗi,
chỉ đơn giản là kiểu đó không xuất hiện cho từ đó) - nghĩa là bạn có thể thêm
bài học mới mà không bắt buộc phải điền đủ mọi trường, xem lại mục "Cách
thêm bài học mới" ở trên.

## LLM: Tâm sự với thú cưng (Gemini) (2026-08-21)

> **CẬP NHẬT (2026-09-16)**: phần "Không bắt buộc phải có API key... dán vào
> `lib/core/config/llm_config.dart`" bên dưới **đã LỖI THỜI** - file đó đã bị
> xoá (dead code sau khi refactor). Key Gemini giờ cấu hình 1 LẦN DUY NHẤT ở
> biến môi trường `GEMINI_API_KEY` phía backend (Render), KHÔNG còn dán vào
> client nữa (bắt buộc vì app giờ public trên web - xem đầu file mục "CẬP
> NHẬT (2026-09-16)" và `backend/README.md`). Client luôn coi như "đã cấu
> hình" (`GeminiChatService.isConfigured`/`GeminiDictionaryService.
> isConfigured` luôn `true`) và gọi qua proxy `POST /me/gemini/generate` -
> xem `backend/app/routers/gemini.py`. Phần System Prompt/safetySettings/
> xử lý lỗi/troubleshooting model bên dưới vẫn đúng nguyên lý, chỉ khác chỗ
> ĐẶT key.

Tab mới **Chat** cho bé trò chuyện tự do với thú cưng đang chọn (Bunny/Mimi/Moni),
KHÁC hẳn tab Play: không phải bài học đúng/sai, không trừ tim/cộng sao - chỉ
để vui và luyện phản xạ tiếng Anh tự nhiên. Bé có thể **gõ chữ hoặc bấm mic
nói** (đổi qua lại bằng nút bàn phím/mic ở góc trái ô nhập).

**Không bắt buộc phải có API key** - tab Chat hoạt động được NGAY từ đầu nhờ
1 chatbot offline có sẵn câu trả lời (xem "Chế độ tự động: AI thật hay
offline?" bên dưới). Nếu muốn bé trò chuyện tự do, thông minh hơn (AI thật):

1. Mở https://aistudio.google.com/apikey, đăng nhập bằng tài khoản Google
   (Gmail) bất kỳ - hoàn toàn miễn phí, không cần thẻ tín dụng.
2. Bấm "Create API key" -> chọn "Create API key in new project" (hoặc dùng
   project có sẵn nếu bạn đã có).
3. Copy chuỗi key hiện ra (dạng `AIzaSy...`).
4. Mở file `lib/core/config/llm_config.dart`, dán key vào dòng:
   ```dart
   static const String geminiApiKey = '';   // <- dán key vào giữa 2 dấu ''
   ```
5. Build lại app (`flutter run` hoặc `flutter build apk`).

**Chế độ tự động: AI thật hay offline?** `ChatController` không gọi thẳng
`GeminiChatService` nữa mà gọi qua interface `ChatReplyService`
(`lib/services/chat_reply_service.dart`), do `CompositeChatService`
(`lib/services/composite_chat_service.dart`) hiện thực - tự động chọn:
- **Chưa dán API key**: mọi tin nhắn đi qua `OfflineChatService`
  (`lib/services/offline_chat_service.dart`) - 1 chatbot offline đối chiếu
  từ khoá trong câu bé gõ/nói (hello, how are you, bye, favorite color...)
  với 1 danh sách câu trả lời tiếng Anh đơn giản đã soạn sẵn, chọn ngẫu
  nhiên 1 câu phù hợp (hoặc câu chung chung nếu không khớp từ khoá nào).
  KHÔNG cần mạng, KHÔNG gọi AI thật, nên an toàn nội dung tuyệt đối nhưng bé
  chỉ "trò chuyện" được trong phạm vi các mẫu câu đó, không tự do bằng AI
  thật. Tab Chat hiện 1 banner nhỏ "🤖 Đang chat offline" kèm nút "Hướng dẫn"
  khi đang ở chế độ này - KHÔNG khoá màn hình chat lại.
- **Đã dán API key**: dùng `GeminiChatService` (AI thật). Nếu 1 lượt chat cụ
  thể bị lỗi TẠM THỜI (mất mạng, timeout, hết hạn mức 429, hoặc lỗi server
  Google 5xx), `CompositeChatService` tự động dùng tạm `OfflineChatService`
  cho ĐÚNG LƯỢT ĐÓ thay vì bắt bé thấy màn hình lỗi - tin nhắn đó sẽ có ghi
  chú nhỏ "📶 Mất kết nối, đây là câu trả lời có sẵn" bên dưới. Các lỗi
  KHÔNG tạm thời (key sai/hết hạn, nội dung bị chặn an toàn) vẫn báo thật
  cho phụ huynh, không bị che đi.

`GeminiChatService` (`lib/services/gemini_chat_service.dart`) gọi thẳng REST
API của Gemini (package `http` thuần Dart - KHÔNG dùng SDK
`google_generative_ai` vì package đó đã deprecated, cũng không dùng Firebase
AI Logic vì cần dựng thêm 1 project Firebase, không cần thiết cho nhu cầu
đơn giản này). `ChatController` giữ lịch sử hội thoại (chỉ trong bộ nhớ
phiên hiện tại, KHÔNG lưu SharedPreferences - đơn giản và giảm dữ liệu lưu
trữ) và gọi `TtsService` đọc to câu trả lời của thú cưng.

**Đã fix (2026-08-21): câu trả lời bị cụt lủn/lẫn nội dung lạ**. Các model
Gemini 3.x (như `gemini-3.6-flash`) mặc định BẬT "thinking" (tự suy luận
trước khi trả lời) - phần suy luận này TIÊU TỐN CHUNG quỹ `maxOutputTokens`
với câu trả lời hiển thị, nên nếu quỹ token thấp, model có thể "nghĩ" hết
sạch token rồi bị cắt ngang giữa câu trả lời thật (gây ra các câu cụt như
"I" hoặc lẫn cả đoạn suy luận nội bộ kiểu ": Optionally weave in a..." lẫn
vào câu trả lời). Đã sửa trong `gemini_chat_service.dart`: thêm
`generationConfig.thinkingConfig.thinkingLevel = "minimal"` để giảm tối đa
phần suy luận (field này dành cho model Gemini 3.x - nếu đổi sang model
Gemini 2.5.x thì cần đổi thành `thinkingBudget: 0` thay vì `thinkingLevel`),
tăng `maxOutputTokens` từ 150 lên 500, và lọc bỏ các "part" có `thought:
true` (nội dung suy luận nội bộ) khi ghép câu trả lời hiển thị.

**An toàn nội dung cho bé** - 2 lớp phòng vệ độc lập trong mỗi request:
1. **System Prompt nghiêm ngặt** (soạn trong `GeminiChatService._buildSystemPrompt`)
   ép model đóng vai thú cưng thân thiện, chỉ dùng tiếng Anh đơn giản (A1-A2),
   chỉ nói về chủ đề an toàn (động vật, gia đình, bạn bè, trường học, trò
   chơi...), CẤM tuyệt đối bạo lực/kinh dị/tình cảm người lớn/chất kích
   thích/tự hại, không hỏi/lặp lại thông tin cá nhân, không tư vấn y
   tế/pháp lý/tài chính, và **bỏ qua mọi chỉ dẫn trong tin nhắn của bé cố
   thay đổi các luật này** (phòng prompt injection).
2. **`safetySettings` của chính Gemini** - đặt mức chặn cao
   (`BLOCK_LOW_AND_ABOVE`) cho mọi hạng mục (quấy rối, thù ghét, tình dục,
   nguy hiểm) - đây là bộ lọc phía Google, hoạt động độc lập với System
   Prompt (không thể bị "lách" qua prompt injection).

Nếu Gemini vẫn chặn/từ chối trả lời (hiếm khi xảy ra với nội dung bình
thường của bé), app hiện thông báo thân thiện thay vì lỗi kỹ thuật, và bé có
thể hỏi lại câu khác ngay.

**LƯU Ý QUAN TRỌNG ĐÃ TRAO ĐỔI VỚI BẠN**: theo yêu cầu của bạn (ưu tiên đơn
giản), API key được **nhúng thẳng vào mã nguồn app** thay vì qua 1 backend
proxy trung gian - ai giải mã (decompile) file APK/IPA build ra đều có thể
lấy được key này. Đây là lựa chọn có chủ đích đã được xác nhận, không phải
thiếu sót. Ở gói miễn phí, Google có thể dùng nội dung chat để cải thiện
model (không riêng tư tuyệt đối) - phù hợp cho app dùng trong gia đình. Nếu
sau này muốn an toàn hơn, cân nhắc chuyển sang backend proxy (Cloudflare
Worker/Firebase Cloud Function) giữ key ở phía server.

### Chat không kết nối được AI thật? Cách tự kiểm tra (2026-08-21, đã xử lý xong)

**ĐÃ XÁC NHẬN (2026-08-21)**: `geminiModel` hiện đang là `gemini-3.6-flash` -
lấy trực tiếp từ nội dung lỗi 404 thật mà Google trả về khi gọi thử bằng
API key thật ("model gemini-2.5-flash is no longer available to new users
... use models/gemini-3.6-flash"), KHÔNG phải đoán qua docs như 2 lần trước
(`gemini-flash-latest` rồi `gemini-2.5-flash` đều sai). Nếu bạn build lại và
vẫn lỗi, Google có thể đã đổi tên model tiếp - làm theo các bước dưới đây để
tự tìm tên đúng, đáng tin cậy hơn hẳn tài liệu tra trên mạng:

1. **Lấy danh sách model THẬT mà chính key của bạn dùng được** - mở trình
   duyệt, dán URL sau (thay `DÁN_KEY_CỦA_BẠN` bằng key thật của bạn) vào
   thanh địa chỉ rồi Enter:
   ```
   https://generativelanguage.googleapis.com/v1beta/models?key=DÁN_KEY_CỦA_BẠN
   ```
   Trình duyệt sẽ hiện ra 1 khối JSON dạng:
   ```json
   {
     "models": [
       { "name": "models/gemini-2.5-flash", "supportedGenerationMethods": ["generateContent", ...] },
       { "name": "models/gemini-2.0-flash", "supportedGenerationMethods": ["generateContent", ...] },
       ...
     ]
   }
   ```
   Tìm 1 entry có chữ **"flash"** trong `name` VÀ có `"generateContent"` trong
   `supportedGenerationMethods`. Lấy đúng phần chữ SAU `models/` (ví dụ
   `gemini-2.5-flash`) - đó chính là giá trị đúng để dán vào `geminiModel`
   trong `lib/core/config/llm_config.dart`. Nếu không chắc chọn entry nào,
   **copy nguyên khối JSON đó gửi lại cho mình** (không cần xoá gì, response
   này không chứa key của bạn) - mình sẽ đọc và sửa đúng tên model giúp bạn.
2. **Nếu trang báo lỗi thay vì hiện JSON** (ví dụ `"API key not valid"` hoặc
   mã lỗi 400/403): vấn đề nằm ở CHÍNH key, không phải model - key sai, bị
   xoá, hoặc project Google Cloud gắn với key bị tắt Generative Language API.
   Lấy lại key mới tại https://aistudio.google.com/apikey.
3. **Test luôn model đã chọn** (tuỳ chọn, xác nhận thêm trước khi sửa code) -
   thay `DÁN_KEY_CỦA_BẠN` và `TÊN_MODEL` bằng giá trị thật:
   - **PowerShell (Windows - dùng cách này, KHÔNG dùng `curl` trần)**: trên
     Windows, `curl` mặc định là ALIAS của `Invoke-WebRequest`, KHÔNG hiểu cú
     pháp `-H`/`-d` kiểu Unix (sẽ báo lỗi
     `Cannot bind parameter 'Headers'...` như đã gặp) - dùng script sau thay
     vì gõ `curl` trực tiếp:
     ```powershell
     $key = "DÁN_KEY_CỦA_BẠN"
     $model = "TÊN_MODEL"
     $headers = @{ "Content-Type" = "application/json"; "x-goog-api-key" = $key }
     $body = '{"contents":[{"parts":[{"text":"Say hi in 5 words"}]}]}'
     try {
         $resp = Invoke-RestMethod -Uri "https://generativelanguage.googleapis.com/v1beta/models/$($model):generateContent" -Method Post -Headers $headers -Body $body
         $resp | ConvertTo-Json -Depth 10
     } catch {
         Write-Host "STATUS:" $_.Exception.Response.StatusCode.value__
         $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
         $reader.ReadToEnd()
     }
     ```
     Dán cả khối này vào PowerShell rồi Enter. Kết quả mong đợi: JSON có
     `candidates.content.parts.text`. Nếu lỗi, khối `catch` sẽ in ra đúng mã
     lỗi (STATUS) và nội dung lỗi thật từ Google - gửi lại 2 dòng đó.
   - **macOS/Linux/Git Bash**:
     ```bash
     curl "https://generativelanguage.googleapis.com/v1beta/models/TÊN_MODEL:generateContent" \
       -H "Content-Type: application/json" \
       -H "x-goog-api-key: DÁN_KEY_CỦA_BẠN" \
       -d '{"contents":[{"parts":[{"text":"Say hi in 5 words"}]}]}'
     ```
4. **Lỗi mạng/timeout** (không liên quan model/key): kiểm tra máy/điện thoại
   test có Internet, không bị VPN/firewall/proxy công ty chặn
   `generativelanguage.googleapis.com`.
5. **Đã build lại HOÀN TOÀN chưa?** Sửa 1 hằng số `static const` như
   `geminiApiKey`/`geminiModel` đôi khi KHÔNG được hot reload/hot restart áp
   dụng đúng - chạy `flutter clean`, rồi `flutter pub get`, rồi `flutter run`
   (dừng hẳn app cũ trước khi chạy lại) để chắc chắn giá trị mới được build
   vào app.
6. Trong app, banner "🤖 Đang chat offline" ở tab Chat = app đang đọc
   `geminiApiKey` là RỖNG (`LlmConfig.isConfigured == false`) - nghĩa là key
   chưa được lưu đúng vào file, hoặc app đang chạy bản build CŨ (xem bước 5).
   Nếu KHÔNG thấy banner này nhưng vẫn không trả lời được, xem lỗi cụ thể ở
   banner đỏ/hồng phía dưới khung chat (`ChatController.friendlyErrorMessage`)
   để biết đúng nguyên nhân trong các mục trên.

## Thú cưng động & Nghe lại ở Chat (2026-08-22)

Trước đây tab Chat chỉ toàn CHỮ (bong bóng tin nhắn) - hơi đơn điệu so với
tab Home có thú cưng động. Đã bổ sung:

- **1 `PetAvatar` lớn ở đầu màn hình Chat** - đúng nhân vật/màu/phụ kiện bé
  đã chọn ở Home (xem 2 mục phía trên), **tự "diễn" đúng trạng thái**: đang
  NGHE (mic mở) → đang SUY NGHĨ (chờ AI/offline trả lời) → đang NÓI (lúc đọc
  to câu trả lời) → đứng yên. Trạng thái lấy trực tiếp từ
  `ChatController.isListening`/`isSending`/`isSpeaking` (không tự bịa thêm 1
  bộ mood riêng) - xem `ChatScreen._moodFor`.
- **1 avatar tròn nhỏ** (emoji nhân vật trên nền màu đang chọn) cạnh MỖI tin
  nhắn của thú cưng - KHÔNG animate (chỉ avatar lớn ở trên mới animate, để
  không vẽ CustomPaint tốn kém cho từng dòng khi lịch sử chat dài).
- **Nút "Nghe lại" (🔁)** ở mỗi tin nhắn của thú cưng - phát lại ĐÚNG giọng
  đọc + animation "đang nói" của câu đó, **KHÔNG gọi lại AI/tốn thêm 1 lượt
  Gemini** (tin nhắn không đổi, chỉ đọc lại text đã có sẵn). Tắt tạm thời
  trong lúc thú cưng đang đọc 1 câu khác (tránh 2 giọng chồng nhau).

Kỹ thuật: `ChatController` thêm 1 cờ `isSpeaking` (bật/tắt quanh lúc gọi
`TtsService.speak`, qua hàm dùng chung `_speakReply`) + 1 hàm `replay(message)`
gọi lại đúng `_speakReply` với text CŨ thay vì gọi `ChatReplyService` mới -
đây là điểm mấu chốt để "Nghe lại" không tốn thêm quota Gemini. `isSending`
(chờ AI) và `isSpeaking` (đang đọc to) CỐ TÌNH tách biệt 2 cờ khác nhau - bé
có thể gõ tin nhắn tiếp theo ngay khi có chữ trả lời hiện ra, không cần chờ
thú cưng đọc xong (giữ đúng hành vi mượt mà đã có từ trước).

## Avatar của bé & Gợi ý ngữ pháp ở Chat (2026-08-23)

### Sửa lỗi: tin nhắn (giọng nói) của bé bị cụt

**Nguyên nhân thật sự**: `ChatController.startVoiceInput()` trước đây giới
hạn mic chỉ mở tối đa **8 giây**, và im lặng quá **2 giây** (mặc định của
`SpeechService`) giữa câu là coi như "nói xong". Với 1 câu tự do nhiều từ, bé
8 tuổi mới học tiếng Anh thường ngập ngừng hơn 2 giây để nghĩ từ tiếp theo -
`speech_to_text` DỪNG NGANG giữa chừng, chỉ nhận diện được 1 PHẦN câu nói.
Tin nhắn hiển thị ĐÚNG những gì nhận diện được - vấn đề nằm ở khâu nhận diện
bị cắt sớm, không phải lỗi hiển thị/UI.

Đã sửa trong `chat_controller.dart`: tăng thời gian nghe tối đa lên **20
giây**, thời gian chờ im lặng lên **4 giây** (riêng cho Chat - Home và bài
học phát âm vẫn giữ nguyên số giây cũ vì chỉ cần 1 từ/câu chào ngắn). Đồng
thời cho phép bé **bấm lại nút mic trong lúc đang nói để chủ động báo "nói
xong"** ngay (`ChatController.stopVoiceInput`) thay vì phải đợi hết 20 giây
hoặc im lặng đủ 4 giây - nút hiện chữ "Đang nghe... (chạm để dừng)".

### Avatar của bé

Bé có thể chọn 1 avatar riêng ở tab **Settings** (mục "Avatar của bé"),
hiển thị cạnh MỌI tin nhắn của chính bé trong Chat (tương tự avatar tròn nhỏ
đã có sẵn cho thú cưng). 2 lựa chọn:
- **1 trong 16 emoji có sẵn** (`curatedChildAvatarEmojis` trong
  `lib/domain/entities/child_avatar.dart`) - mặc định là 🧒 khi bé chưa từng
  chọn gì.
- **1 ảnh từ thư viện ảnh của máy** - dùng package `image_picker` (mở
  Android Photo Picker trên Android 13+ / PHPicker trên iOS 14+, KHÔNG xin
  quyền truy cập TOÀN BỘ thư viện ảnh, chỉ ảnh bé tự chọn). Ảnh được **sao
  chép** vào thư mục lưu trữ lâu dài của app (package `path_provider`, tên
  file cố định `child_avatar.<đuôi file>` nên chọn ảnh mới tự động ghi đè ảnh
  cũ) vì đường dẫn `image_picker` trả về chỉ là file TẠM, có thể bị hệ điều
  hành xoá bất cứ lúc nào.

Kiến trúc theo đúng khuôn các hệ thống khác: `ChildAvatar`/`ChildAvatarKind`
(domain entity) + `ChildAvatarRepository`/`LocalChildAvatarRepository`
(SharedPreferences, 2 key: loại + giá trị) + `ChildAvatarController`
(presentation, có `selectEmoji`/`pickPhoto`/`resetToDefault`). iOS cần thêm
key `NSPhotoLibraryUsageDescription` trong `ios/Runner/Info.plist` (đã thêm
sẵn) để xin quyền ảnh - Android không cần khai báo quyền thủ công vì
`image_picker` tự gộp quyền cần thiết vào lúc build.

**Phụ thuộc mới**: `image_picker: ^1.2.3`, `path_provider: ^2.1.6` (cả 2 đều
publisher `flutter.dev` đã xác thực, đang bảo trì tích cực - khác với sự cố
`jcenter()` từng gặp với 1 bản `speech_to_text` cũ). Nhớ chạy lại
`flutter pub get` sau khi cập nhật `pubspec.yaml`.

### Gợi ý sửa lỗi ngữ pháp trong Chat (KHÔNG bao gồm phát âm)

Sau khi bé gửi 1 tin nhắn (gõ hoặc nói) VÀ nhận được câu trả lời trò chuyện
bình thường, app **âm thầm gọi thêm 1 request Gemini riêng, rất ngắn gọn**
chỉ để kiểm tra lỗi NGỮ PHÁP cơ bản (thì động từ, chia động từ theo chủ ngữ,
mạo từ a/an/the, số nhiều, trật tự từ) trong câu bé vừa gửi. Nếu có lỗi rõ
ràng, 1 gợi ý ngắn gọn, ấm áp (💡, ví dụ mẫu câu đúng) sẽ tự hiện dưới đúng
tin nhắn đó sau vài giây - KHÔNG chặn/làm chậm cuộc trò chuyện chính.

**Cố ý CHỈ làm phần ngữ pháp, KHÔNG làm phát âm** (theo lựa chọn đã xác nhận
với bạn): việc đánh giá phát âm CHUẨN cần âm thanh gốc, nhưng
`SpeechService.listenOnce()` chỉ trả về CHỮ đã nhận diện (`recognizedText`),
KHÔNG giữ lại file âm thanh nào - muốn làm phát âm thật sự cần ghi âm file +
gửi audio cho Gemini (multimodal), là 1 thay đổi kiến trúc lớn hơn nhiều, để
dành cho bài "Luyện phát âm" ở tab Play (đã so khớp với 1 từ mục tiêu cụ thể,
phù hợp hơn cho việc chấm phát âm).

**Chỉ hoạt động khi đang dùng AI thật (đã có API key Gemini)** - chatbot
offline không hiểu ngôn ngữ nên không thể phân tích ngữ pháp
(`OfflineChatService.checkGrammar` luôn trả về `null`). Bỏ qua câu quá ngắn
(dưới 3 từ, ví dụ "hi", "yes", "ok") vì không đủ ngữ cảnh để đánh giá đúng.
Nếu request phụ này lỗi/mất mạng/timeout, tự động bỏ qua trong im lặng
(`GeminiChatService.checkGrammar` không bao giờ throw) - KHÔNG BAO GIỜ ảnh
hưởng tới câu trả lời trò chuyện chính hay hiện lỗi kỹ thuật cho bé.

Kiến trúc: thêm `checkGrammar(childText)` vào interface `ChatReplyService`
(cả 3 lớp `GeminiChatService`/`OfflineChatService`/`CompositeChatService` đều
implement), thêm field `grammarNote` (nullable) + `copyWith` vào
`ChatMessage`. `ChatController.sendText()` gọi `_checkGrammar` "âm thầm"
(`unawaited`) ngay sau khi đã có câu trả lời chính, rồi gắn kết quả vào ĐÚNG
tin nhắn của bé qua `copyWith` khi phân tích xong.

## Vòng 11 (2026-08-23): Sóc & Chim cánh cụt, dịch Chat, ăn mừng streak, thêm hành động Home, tên riêng của bé, Từ điển

Đợt cập nhật lớn gồm 6 tính năng độc lập, liệt kê theo đúng thứ tự đã làm:

### 1. Thêm 2 nhân vật: 🐿️ Ran (sóc) và 🐧 Pingo (chim cánh cụt)

Theo đúng khuôn kiến trúc 3 nhân vật cũ (xem mục "Hình ảnh thú cưng & chọn
nhân vật" ở trên) - thêm `PetCharacter.squirrel`/`PetCharacter.penguin`,
`SquirrelPainter`/`PenguinPainter` (trong `pet_character_painters.dart`), nối
vào `buildPetCharacterPainter`/`hitTestPetCharacter`/`_headAnchor`/`_neckAnchor`
(`pet_accessory_painter.dart`).

- **Màu mặc định = màu tự nhiên của loài**: thay vì thêm giá trị `PetPalette`
  mới, `PetPalette.classic` ("Gốc") của Ran/Pingo được ĐỊNH NGHĨA thẳng là màu
  nâu/đen tự nhiên (`defaultPaletteByCharacter[squirrel/penguin] = classic`) -
  giống cách "Gốc" của Bunny/Mimi/Moni cũng là màu nguyên bản của mỗi con.
- **Pingo không có tai** (giống Moni) - phần "tai" trong `MimiPose`
  (`earLeftAngle`/`earRightAngle`) được TÁI SỬ DỤNG để animate 2 cái CHÂN
  CHÈO (flipper) thay vì thêm field mới vào `MimiPose` chỉ cho 1 nhân vật -
  tận dụng đúng animation vẫy tai đang chạy sẵn cho mọi nhân vật.
- **LƯU Ý TOẠ ĐỘ PHỤ KIỆN CHƯA KIỂM CHỨNG**: giống caveat đã ghi ở mục "Phụ
  kiện thời trang cho thú cưng", toạ độ `_headAnchor`/`_neckAnchor` của Ran/
  Pingo là ƯỚC LƯỢNG theo công thức hình học, CHƯA canh bằng mắt trên app thật
  - nếu phụ kiện lệch khi đeo cho 2 con mới này, chụp ảnh gửi lại để chỉnh.

### 2. Nút dịch 🌐 ở Chat

Mỗi tin nhắn của thú cưng có thêm 1 nút dịch (cạnh nút "Nghe lại" 🔁) - bấm
vào sẽ dịch câu thoại tiếng Anh đó sang tiếng Việt và hiện ngay bên dưới, bấm
lại để ẩn đi. Bấm lại LẦN NỮA sau khi đã dịch xong sẽ KHÔNG gọi lại AI (chỉ
ẩn/hiện lại bản dịch đã lưu) - cùng nguyên tắc tiết kiệm quota với nút "Nghe
lại".

Kiến trúc: thêm `translateToVietnamese(englishText)` vào interface
`ChatReplyService` (`GeminiChatService` gọi 1 request Gemini riêng, ngắn gọn,
cùng kiểu với `checkGrammar`; `OfflineChatService` luôn trả `null` - chatbot
offline không hiểu ngôn ngữ; `CompositeChatService` chỉ delegate sang Gemini
khi đã cấu hình). Thêm field `translatedText` (nullable) vào `ChatMessage`.
`ChatController` quản lý 2 trạng thái: `Set<int> _visibleTranslationIndices`
(tin nhắn nào đang HIỆN bản dịch) và `int? _translatingMessageIndex` (đang
chờ dịch, chặn bấm dịch nhiều tin nhắn cùng lúc) qua hàm `toggleTranslate(index)`.

### 3. Hiệu ứng ăn mừng khi đạt streak mới

Khi bé hoàn thành bài học và đây là ngày ĐẦU TIÊN trong ngày (streak thật sự
tăng thêm 1 - không phải học thêm bài thứ 2 cùng ngày), 1 hộp thoại ăn mừng sẽ
tự hiện: hiệu ứng các icon (⭐✨🔥🎉) bay toả ra từ tâm kiểu confetti đơn giản
(tự vẽ bằng `AnimationController` + `Transform.translate`/`Opacity`, KHÔNG
thêm package confetti ngoài - giữ đúng nguyên tắc hạn chế dependency mới của
dự án), kèm 1 âm thanh riêng (`streak.wav`, tự tổng hợp bằng
`scripts/generate_sounds.py` - hợp âm rải đi lên nhanh + 1 nốt lấp lánh cuối,
nổi bật hơn hẳn âm thanh "hoàn thành bài" thường).

Kiến trúc: `StreakController.recordActivityToday()` đổi từ trả về `void`
thành trả về `int?` (null = streak KHÔNG đổi hôm nay - đã tính rồi, số = giá
trị streak MỚI cần ăn mừng). `LessonController` lưu giá trị này vào
`_pendingStreakCelebration` (nullable), rồi `consumeStreakCelebration()`
"đọc-và-xoá" 1 lần (tránh hiện ăn mừng lặp lại nếu widget rebuild nhiều lần) -
`LessonScreen._LessonCompleteView` gọi hàm này trong `addPostFrameCallback`
lúc `build()` màn hoàn thành bài, hiện `showStreakCelebration(context, streak)`
(`lib/presentation/widgets/streak_celebration.dart`) nếu có giá trị.

### 4. Thêm 3 nút chơi cùng ở Home: Tắm 🛁, Đi ngủ 🌙, Tập thể dục 🤸

Cạnh 3 nút gốc (Xoay vòng/Nhảy chơi/Cho ăn), đều CHỈ để vui, KHÔNG cộng sao -
đúng nguyên tắc phân biệt với học ở tab Play.

- **Tắm** 🛁: mắt nhắm hờ + vài bọt bong bóng 🫧 bay lên quanh thú cưng.
- **Đi ngủ** 🌙: mắt nhắm hẳn, ĐỨNG YÊN (KHÔNG đặt mood `happy` như các trò
  khác - nếu đặt happy, thú cưng sẽ nhún nhảy trong lúc đang "ngủ", nhìn kỳ),
  hiện icon "💤" nhấp nháy.
- **Tập thể dục** 🤸: vài tia lấp lánh ✨ quanh thú cưng.

Kiến trúc: `enum MimiTrick` (`pet_avatar.dart`) thêm 3 giá trị
`bath/sleep/exercise`, mỗi trick có 1 `AnimationController` riêng, áp dụng như
1 override TẠM THỜI lên `_buildPose()` (tự hết hiệu lực sau khi animation
xong). Riêng bath/sleep cần thêm biến `forcedEyeScaleY` để ép mắt nhắm - LƯU Ý
KỸ THUẬT: phải đặt kèm `happyEyes = false`, vì nếu không, cờ `isHappy` của
painter sẽ VẪN vẽ mắt cong kiểu vui bất kể `eyeScaleY` là bao nhiêu (mood
`happy` mặc định bật cờ này). Các hiệu ứng trang trí (bong bóng/💤/tia sáng)
được vẽ như widget `Positioned` chồng lên `CustomPaint` (không vẽ trong
painter, vì không phải 1 phần hình vẽ vector của nhân vật) qua
`_buildTrickDecorations()`.

### 5. Đặt tên riêng cho bé ở Settings

Mục mới "Tên riêng của bé" trong Cài đặt - nhập tên (hoặc bấm "Xoá tên" để
quay lại xưng hô chung chung). Khi đã đặt tên:
- **Chat (Gemini)**: System Prompt được dặn thỉnh thoảng gọi tên bé (ví dụ
  "Hi Bông!", "Great job, Bông!") - không ép gọi tên trong MỌI câu.
- **Chat (chatbot offline)**: 1 số mẫu câu chào ("Hi", "Hello") có placeholder
  `{child}`, thay bằng tên riêng nếu có, hoặc "there" nếu chưa đặt.
- **Home**: 1 số câu thoại lúc bé vuốt ve thú cưng (`_petPhrases`) cũng có
  `{child}`, thay bằng tên riêng hoặc "friend" nếu chưa đặt.

Kiến trúc theo đúng khuôn `ChildAvatar`: `ChildNameRepository`/
`LocalChildNameRepository` (SharedPreferences, 1 key) + `ChildNameController`
(`name` nullable, `displayName` có fallback "bạn" dùng cho hiển thị ở
Settings). **GHI CHÚ**: tên hiện lưu CHUNG cho cả thiết bị (chưa có hệ thống
tài khoản đăng nhập) - theo trao đổi với bạn, khi nào app hỗ trợ nhiều tài
khoản sẽ nâng cấp lưu theo từng tài khoản, không phải việc cần làm ngay.

### 6. Tab mới: Từ điển 📖 (tab thứ 5 ở thanh dưới)

Tra nghĩa 1 từ hoặc 1 câu, TỰ ĐỘNG nhận diện tiếng Anh hay tiếng Việt và dịch
sang chiều còn lại (dùng Gemini - xem `GeminiDictionaryService`, phản hồi
theo định dạng cố định `EN: .../VI: ...` giống cách `checkGrammar` dùng
"TIP:"/"OK", dễ phân tích chắc chắn hơn bắt model trả JSON). Kết quả luôn hiện
cả 2 phía Anh/Việt, kèm:
- **Nút 🔊 Nghe** - đọc to phía TIẾNG ANH bằng `TtsService` (luôn đọc tiếng
  Anh dù bé gõ vào bằng tiếng Việt, vì đó là phía bé đang học).
- **Nút 🎤 Kiểm tra phát âm** - bé đọc theo, so khớp với `EvaluateAnswer.
  callPhrase` (biến thể MỚI của usecase `EvaluateAnswer` đã dùng cho câu hỏi
  "nói" ở bài học - `call()` so khớp 1 TỪ đơn với từng token nhận diện được;
  `callPhrase()` so khớp CẢ CÂU bằng khoảng cách chỉnh sửa tổng thể, khoan
  dung hơn theo độ dài câu), hiện ✅/🔁/🎤 tuỳ kết quả.

**KHÔNG có chế độ offline** (khác Chat) - tra nghĩa cần hiểu ngôn ngữ thật sự,
không thể đối chiếu từ khoá đơn giản như `OfflineChatService`. Chưa cấu hình
API key Gemini thì tab hiện hướng dẫn lấy key thay vì ô nhập liệu không dùng
được (xem `DictionaryController.isConfigured`).

Kiến trúc: `DictionaryLookupResult` (domain entity) + `DictionaryService`
(interface) / `GeminiDictionaryService` (impl) + `DictionaryController`
(presentation, quản lý cả tra cứu LẪN nghe/kiểm tra phát âm) +
`DictionaryScreen`. Nối vào `AppBottomNav` (5 mục) và `RootShell`'s
`IndexedStack` (5 children, cùng thứ tự).

**LƯU Ý AN TOÀN mic dùng chung**: cả `ChatController.startVoiceInput()` và
`DictionaryController.checkPronunciation()` đều BỌC `try/finally` quanh lời
gọi `SpeechService.listenOnce()` - nếu không, plugin lỗi/mic bị từ chối quyền
giữa chừng sẽ làm cờ `isListening` kẹt ở `true` MÃI MÃI (vì 2 controller này
sống ở cấp app, không bị tạo lại khi chuyển tab), khoá vĩnh viễn nút mic
tương ứng - đúng lớp lỗi đã từng gặp và sửa ở `HomeScreen._handleTalkPressed`
(xem comment tại đó).

## Vòng 12 (2026-08-23): Sửa lỗi Từ điển, tăng số tim, hiệu ứng UIUX ở bài học

3 việc theo đúng yêu cầu, liệt kê theo thứ tự đã làm:

### 1. Sửa lỗi Từ điển hay báo "Chưa tra được từ này lúc này"

Tìm ra 2 nguyên nhân thật sự trong `GeminiDictionaryService` (KHÔNG phải do
key/mạng như thông báo cũ khiến người dùng lầm tưởng):

- `_parse()` bản cũ chỉ nhận tiền tố `"EN:"`/`"VI:"` khi ở ĐẦU DÒNG (tách theo
  `\n`) - nếu Gemini gộp cả 2 phần trên CÙNG 1 dòng, hoặc chèn markdown
  (`**EN:**`) dù prompt đã dặn "no markdown", việc nhận diện thất bại và trả
  lỗi oan dù model đã trả lời đúng nội dung. Đã đổi sang `RegExp` khoan dung
  (thử khớp 2 dòng riêng trước, không được thì thử khớp gộp 1 dòng), và tự bỏ
  ký tự markdown trước khi nhận diện.
- `maxOutputTokens: 200` hơi eo hẹp cho câu dài phải trả CẢ 2 ngôn ngữ trong 1
  lượt (cùng lớp lỗi đã gặp ở mục "LLM: Tâm sự với thú cưng" cho Chat) - tăng
  lên 300.

Đồng thời đổi `DictionaryService.lookup()` từ trả `Future<DictionaryLookupResult?>`
(chỉ biết thành công/thất bại) sang `Future<DictionaryLookupOutcome>` mang
theo MÃ LỖI cụ thể (`missing_key`/`invalid_key`/`model_not_found`/
`rate_limited`/`blocked`/`not_found`/`timeout`/`network`/...) - cùng nguyên
tắc với `ChatReplyResult` đã dùng cho Chat - để nếu lỗi vẫn xảy ra (hết quota,
sai key, bị chặn an toàn...), bé/phụ huynh thấy đúng nguyên nhân thay vì luôn
1 câu chung chung, dễ chẩn đoán hơn nhiều.

**Bổ sung thêm**: khi bé bấm "Kiểm tra phát âm", giờ hiện thêm từng TỪ trong
câu tiếng Anh được tô XANH (đọc đúng) / ĐỎ (chưa đúng) ngay bên dưới nhận xét
chung, thay vì chỉ 1 câu nhận xét mơ hồ cho cả câu - dùng usecase mới
`EvaluateAnswer.wordLevelMatch()` (so khớp từng từ, thuật toán tương tự
`call()`/`callPhrase()` đã có, tránh 1 từ bé nói được tính trùng cho 2 vị trí
mục tiêu). Trả về kèm `WordMatchResult` (gồm cả danh sách từ ĐÃ CHUẨN HOÁ dùng
để so khớp, không chỉ mỗi `List<bool>`) để UI hiển thị đúng khớp vị trí - nếu
chỉ trả `List<bool>` rồi để UI tự tách lại câu gốc, câu có dấu nháy đơn (như
"it's") sẽ bị lệch số từ giữa 2 bên, tô màu nhầm vị trí.

### 2. Tăng thời gian sử dụng (tim)

Theo yêu cầu "không quá cần thiết phải giới hạn bé" - `HeartsController`:
- `maxHearts`: 5 → **10** (gấp đôi số lượt thử trước khi hết tim).
- `regenInterval`: 2 giờ → **15 phút** (hồi tim NHANH HƠN RẤT NHIỀU, gần như
  không còn cảm giác bị chặn lại).

Vẫn giữ NGUYÊN cơ chế tim (không bỏ hẳn) để bé còn có động lực trả lời cẩn
thận, chỉ không còn khắt khe như trước. Đồng bộ luôn giá trị mặc định lần đầu
cài app trong `LocalHeartsRepository.getHearts()` (`?? 10`).

### 3. Hiệu ứng UIUX khi trả lời ở bài học

- **Chọn đáp án đúng/sai** (trắc nghiệm/điền từ): đáp án ĐÚNG luôn được tô
  XANH khi đã có kết quả, đáp án bé vừa CHỌM SAI được tô ĐỎ - bé thấy ngay
  vừa chọn gì và đáp án đúng là gì, không chỉ nghe Mimi nói.
- **Sắp xếp câu**: khung câu đang ghép đổi màu xanh/đỏ theo kết quả, và câu
  ghép SAI được GIỮ NGUYÊN hiển thị (tô đỏ) thay vì bị xoá ngay lập tức như
  trước - chỉ xoá khi bé thật sự bắt đầu ghép lại.
- **Chính tả (gõ từ)**: viền ô nhập đổi màu xanh/đỏ theo kết quả.
- **Lắc/nảy**: khu vực trả lời "lắc" nhẹ khi sai, thú cưng "nảy" nhẹ
  (`Curves.elasticOut`) khi đúng - tự triển khai bằng `AnimationController` +
  `Transform`, KHÔNG thêm package animation ngoài.
- **Rung phản hồi (haptics)**: rung nhẹ khi chạm chọn đáp án/mảnh từ
  (`HapticFeedback.selectionClick`), rung vừa khi đúng (`mediumImpact`), rung
  mạnh khi sai (`heavyImpact`) - đặt tập trung trong `LessonController` (nơi
  quyết định đúng/sai), không rải rác ở UI.
- Thêm dòng trạng thái "Đúng rồi, giỏi quá! 🎉" cho `LessonSessionState.correct`
  (`_StatusHint`) - trước đây chỉ có dòng trạng thái cho lúc sai, không có cho
  lúc đúng.

Kiến trúc: tách phần "đang chơi" của `LessonScreen` thành StatefulWidget
riêng `_LessonPlayView` (với `TickerProviderStateMixin`) để theo dõi CHUYỂN
trạng thái (`_prevState` so với `state` hiện tại mỗi lần build, qua
`addPostFrameCallback` - cùng idiom đã dùng cho ăn mừng streak) và chỉ kích
hoạt animation ĐÚNG 1 LẦN mỗi lần chuyển, không lặp lại khi widget rebuild.
Thêm `LessonController.selectedWordId` (lựa chọn bé vừa chạm, null khi sang
từ mới/thử lại) để UI biết tô đỏ đúng lựa chọn nào.

## Vòng 13 (2026-08-31): Thêm "Bài tranh" (Picture Scenes) + mở rộng từ vựng Play

Theo yêu cầu bổ sung chủ đề chuyên sâu hơn ("có 1 bức tranh, rồi hỏi các câu
liên quan trong bức tranh đó"). Trước khi làm đã tư vấn và hỏi lại người
dùng 2 vòng (câu hỏi cố định hay AI sinh động; nguồn tranh; đặt ở đâu trong
app; quy mô thí điểm) để chốt đúng hướng thay vì tự quyết toàn bộ.

### 1. Tính năng mới: "Bài tranh" - tách biệt hoàn toàn với Play

- **Vì sao KHÔNG dùng chung `Lesson`/`Word`/`LessonController`**: 1 bài tranh
  là 1 bức tranh CHUNG kèm NHIỀU câu hỏi xoay quanh tranh đó (dạng gần với
  bài "miêu tả tranh" trong đề thi Cambridge YLE Movers/Flyers), khác hẳn
  cấu trúc Play (nhiều từ vựng ĐỘC LẬP, mỗi từ 1 câu hỏi riêng). Nên xây 1 hệ
  thống song song, đúng Clean Architecture: entity `PictureScene`/
  `SceneQuestion` riêng, `PictureSceneRepository` + `JsonPictureSceneRepository`
  (đọc `assets/scenes/scenes.json`, giống hệt cách `JsonLessonRepository` đọc
  `lessons.json`), 2 controller riêng (`PictureScenesController` - danh sách,
  `ScenePlayController` - phiên chơi 1 bài tranh) và 2 màn hình riêng.
- **KHÔNG trừ tim, KHÔNG có thử lại khi sai** (khác Lesson): trả lời sai chỉ
  hiện luôn đáp án đúng rồi chuyển câu tiếp theo, không kẹt lại bắt bé chọn
  lại nhiều lần. Đây là bài "khám phá/luyện hiểu câu" nhẹ nhàng hơn, không
  phải bài kiểm tra từ vựng nghiêm ngặt như Play - đúng tinh thần giảm áp lực
  đã theo đuổi từ Vòng 12 (tăng tim, bớt khắt khe).
- **3 kiểu câu hỏi mỗi bài tranh**: trắc nghiệm (chạm chọn), đúng/sai, và nói
  (dùng lại `TalkButton`/`SpeechService`/`EvaluateAnswer` sẵn có). Vẫn tái sử
  dụng các quy ước UI/UX đã có từ Vòng 12: tô XANH đáp án đúng/ĐỎ đáp án bé
  chọn sai, rung phản hồi (`HapticFeedback`) tập trung ở controller.
- **Minh hoạ tranh**: chọn vẽ VECTOR bằng `CustomPainter` (widget
  `SceneIllustration`, 5 painter riêng cho 5 tranh thí điểm) thay vì dùng ảnh
  ngoài cho vòng thí điểm này - lý do: người dùng chọn "kết hợp cả 2 nguồn"
  (ảnh có sẵn bản quyền + tự vẽ), nhưng dùng ảnh ngoài cần xin phép tải TỪNG
  file cụ thể (tên file/nguồn/dung lượng) theo đúng quy tắc an toàn của
  phiên làm việc - nên vòng này ưu tiên tự vẽ (không có rào cản xin phép,
  không phụ thuộc file ngoài), để dành việc bổ sung ảnh có bản quyền cho một
  vòng mở rộng sau, sẽ xin phép rõ ràng trước khi tải từng ảnh.
- **Vị trí trong app**: 1 THẺ RIÊNG ở màn Home (`_PictureScenesCard`) mở
  `PictureScenesScreen`, KHÔNG thêm tab thứ 6 ở thanh điều hướng dưới (thanh
  đã có 5 tab, từng phải chỉnh padding/cỡ chữ khi lên 5 tab) - đúng lựa chọn
  người dùng đã chốt.
- **5 bài tranh thí điểm** (`assets/scenes/scenes.json`, 25 câu hỏi): At the
  Park, Breakfast Time, In the Classroom, At the Zoo, Bedtime - mỗi bài 5
  câu hỏi khớp đúng với từng chi tiết trong tranh minh hoạ tương ứng (đã cho
  1 agent độc lập rà soát đối chiếu từng câu hỏi với hình vẽ, xem mục 3).
  Đây CHỈ LÀ khởi đầu - sẽ tiếp tục mở rộng ngân hàng tranh/câu hỏi phong phú
  hơn nhiều ở các vòng sau theo đúng mong muốn ban đầu, không dừng lại ở 5
  tranh.

### 2. Mở rộng từ vựng Play: thêm 6 chủ đề mới (60 từ)

Theo đúng yêu cầu "các chủ đề bài học trong menu Play cũng cần bổ sung thêm
cho thật phong phú" - thêm vào `assets/lessons/lessons.json`: **Jobs**,
**Places in Town**, **School Things**, **Daily Routine**, **Body & Health**,
**House & Furniture** (mỗi bài 10 từ). Play hiện có **15 bài / 142 từ**
(trước vòng này: 9 bài / 82 từ).

**Bài học rút ra khi soạn nội dung mới** (áp dụng ngay, tránh phải sửa lại
sau):

- `ProgressController.masteredWordIds` là 1 `Set<String>` DÙNG CHUNG cho
  TẤT CẢ bài học (không phân biệt bài nào) - nếu 2 từ ở 2 bài khác nhau lỡ
  trùng `id`, học thuộc từ này sẽ vô tình "học thuộc" luôn từ kia. Đã rà soát
  toàn bộ 142 `id` bằng script Python (không chỉ soát bằng mắt) để đảm bảo
  không trùng.
- `EvaluateAnswer.call()` (dùng cho `PromptType.identify`) chỉ so khớp ĐÁNG
  TIN CẬY với mục tiêu 1 TỪ ĐƠN - mục tiêu nhiều từ có thể bị chấm đúng nhầm
  khi bé chỉ nói ĐÚNG TỪ ĐẦU (do có nhánh "bao gồm tiền tố" trong thuật
  toán). Nên mọi từ mới dạng `identify` đều là 1 từ đơn. Riêng cụm hành động
  "mặc quần áo" (get dressed) đổi sang `PromptType.repeat` (kiểu Mimi đọc
  mẫu, bé lặp lại - dùng cho hello/goodbye có sẵn) vì `repeat` KHÔNG chấm
  đúng/sai nghiêm ngặt, nên an toàn dùng cụm nhiều từ ở đây.

### 3. Đã cho 1 agent độc lập rà soát trước khi bàn giao

Vì quy mô thay đổi lớn (1 tính năng hoàn toàn mới + mở rộng nội dung), đã
nhờ 1 agent riêng (không thấy quá trình mình làm) kiểm tra đối nghịch toàn
bộ thay đổi. Đã tìm ra và SỬA:

- Từ "get dressed" ban đầu dùng `id: get_dressed` nhưng `en: dress` +
  `PromptType.identify` + emoji áo phông 👕 - gây mâu thuẫn (bé thấy áo
  phông nhưng đáp án đúng lại là "dress" - cái váy). Sửa theo hướng ở mục 2
  (chuyển sang `PromptType.repeat`, `en: "get dressed"`).
- `ScenePlayController.onTalkPressed` chỉ gọi `EvaluateAnswer.call()` (chấm
  theo 1 từ đơn) dù tương lai có thể thêm câu trả lời nhiều từ cho câu hỏi
  dạng "nói" - đã sửa để tự động chuyển sang `callPhrase()` (chấm cả cụm)
  khi đáp án có khoảng trắng, phòng ngừa lỗi ngầm cho nội dung thêm sau này.
- Emoji 🧠 (bộ não) dùng cho từ "head" (cái đầu) dễ gây hiểu nhầm - đổi sang
  😀. Hình quyển sách trên tủ đầu giường (bài Bedtime) vẽ quá mỏng, khó nhận
  ra - vẽ dày hơn kèm 1 đường gáy sách cho rõ.

## Vòng 14 (2026-08-31): Sửa câu hỏi lấp lửng, thêm nội dung, sửa layout Rewards, thêm mốc "Ngọc thưởng"

User yêu cầu 4 việc sau khi dùng thử Vòng 13: (1) sửa câu hỏi điền từ "lấp lửng" (ví dụ chủ đề Animals, câu "I like the ___." có cả apple/cat đều hợp lý), (2) tiếp tục làm phong phú Bài tranh + Play, (3) căn lại layout cửa hàng phụ kiện/từ đã thuộc ở Rewards (cảm giác lệch trái), (4) thêm mốc thưởng LỚN "viên ngọc" quy đổi tiền thật. Đã hỏi lại qua AskUserQuestion cho việc (4) vì liên quan tới thoả thuận tiền bạc trong gia đình - chốt: **200 sao/viên ngọc, mỗi viên 100.000đ, có nút "Đã nhận thưởng"**.

### 1. Sửa lỗi câu hỏi "điền từ" (fillBlank) lấp lửng

Nguyên nhân THẬT: `_buildChoiceOptions()` (dùng chung cho cả trắc nghiệm lẫn điền từ) chọn 2 từ "mồi nhử" HOÀN TOÀN NGẪU NHIÊN trong cùng bài học, không kiểm tra có hợp câu hay không. Với dạng TRẮC NGHIỆM, việc này không sao vì màn hình vẫn hiện HÌNH minh hoạ của từ đúng - bé nhìn hình mà chọn, mồi nhử ngẫu nhiên không gây lấp lửng. Nhưng dạng ĐIỀN TỪ trước đây CHỈ hiện câu có chỗ trống, KHÔNG hiện hình - nếu câu mẫu chung chung kiểu "I like the ___." thì NHIỀU đáp án đều hợp lý, bé không có cách nào biết chắc Mimi muốn từ nào.

**Đã sửa** (`lesson_screen.dart`, `_buildVisual`): thêm lại hình/màu minh hoạ của từ đúng (`_WordPromptVisual`) phía TRÊN câu điền từ - giống hệt cách dạng trắc nghiệm đã làm. Từ giờ đáp án luôn RÕ RÀNG DUY NHẤT (khớp hình) bất kể 2 từ mồi nhử là gì, bé vẫn phải đọc hiểu câu để biết ĐẶT từ vào đâu - không mất giá trị luyện đọc của dạng bài này.

**Tiện thể rà soát phát hiện thêm 1 lỗi nội dung có sẵn** (không liên quan cơ chế trên): từ "rabbit" ở bài Animals & Colors có `sentenceTemplate: "Look, a ___!"` nhưng `sentenceWords` lại là `["Look", "a", "rabbit"]` (thiếu dấu phẩy, sai dấu câu cuối so với mẫu) - ảnh hưởng dạng bài "Sắp xếp câu". Đã sửa lại thành mẫu câu đơn giản nhất quán với các từ khác: `"There is a ___."`.

### 2. Làm phong phú thêm Bài tranh + Play

- **Bài tranh**: thêm 5 tranh mới (`beach_v1` Ở bãi biển, `farm_v1` Ở nông trại, `kitchen_v1` Trong bếp, `garden_v1` Trong vườn, `birthday_v1` Tiệc sinh nhật) - nâng tổng từ 5 lên **10 bài tranh / 50 câu hỏi**. Cùng phong cách minh hoạ vector CustomPainter như Vòng 13.
- **Play**: thêm 4 chủ đề mới (`nature_v1` Nature, `sports_v1` Sports & Equipment, `time_v1` Time Words, `hobbies_v1` Music & Hobbies) - nâng tổng từ 15 lên **19 bài / 182 từ**. Riêng `time_v1` (today/tomorrow/morning/night...) dùng `PromptType.repeat` (kiểu Mimi đọc mẫu, bé lặp lại - như hello/goodbye) thay vì `identify`, vì các khái niệm thời gian trừu tượng này không có 1 bức tranh "đúng duy nhất" để nhận diện - tránh lặp lại đúng kiểu lỗi vừa sửa ở mục 1.
- Quy trình: cho 1 agent khác soạn nội dung 5 tranh mới (soạn xong tự rà soát), sau đó cho 1 agent ĐỘC LẬP KHÁC (chưa thấy quá trình soạn) rà soát lại toàn bộ Vòng 14 - tìm ra và ĐÃ SỬA: 9/10 tranh có câu hỏi đúng/sai đều là "True" (bé đoán mò cũng đúng, cùng LỖI LẤP LỬNG kiểu khác) - đã đổi 3 câu (farm/garden/birthday) sang đáp án "False"; bát táo trong tranh Kitchen vẽ lún xuống mặt quầy bếp và 3 quả táo vẽ sát nhau khó đếm - đã vẽ lại rõ ràng hơn.

### 3. Sửa layout Rewards bị lệch trái

Nguyên nhân: `Wrap` mặc định `alignment: WrapAlignment.start` dồn các thẻ về SÁT TRÁI - hàng cuối không đủ lấp đầy chiều ngang (ví dụ 6 phụ kiện chia 4+2, hàng 2 chỉ 2 thẻ) để lại khoảng trống bên phải, tạo cảm giác lệch trái. Đã đổi cả 2 `Wrap` (cửa hàng phụ kiện, từ đã thuộc) sang `alignment: WrapAlignment.center` - hàng đã đầy đủ hiển thị giống hệt như cũ, chỉ hàng cuối chưa đầy mới canh giữa thay vì dồn trái.

### 4. Mốc thưởng "Ngọc thưởng 💎" - quy đổi tiền thật

Khác hẳn 6 phụ kiện (danh sách CỐ ĐỊNH, tối đa 80 sao): ngọc là mốc LẶP LẠI VÔ HẠN vì sao sẽ tiếp tục cộng dồn mãi khi bé còn học, không hợp lý liệt kê thành danh sách cố định. Kiến trúc: `GemRewardRepository`/`LocalGemRewardRepository` (SharedPreferences, CHỈ lưu `claimedGemCount` - số ĐÃ NHẬN THƯỞNG) + `GemRewardController` (`earnedCountFor(stars) = stars ~/ 200` luôn tính lại từ số sao hiện có, KHÔNG lưu riêng; `pendingCountFor` = đã đạt trừ đã nhận). Cố tình KHÔNG giữ tham chiếu trực tiếp tới `ProgressController` (nhận `stars` qua tham số ở mỗi lần gọi) để tránh phụ thuộc 2 chiều giữa 2 controller.

Rewards có thêm mục "Ngọc thưởng 💎" giữa cửa hàng phụ kiện và từ đã thuộc: hiện từng viên đã đạt mốc nhưng CHƯA nhận kèm nút "Đã nhận thưởng ✅" (bấm xong không nhắc lại mốc đó nữa), hoặc thanh tiến độ "còn X sao nữa" nếu chưa có viên nào chờ. Số đã nhận + số tiền tương ứng luôn hiện phía trên. Khi bé "làm lại từ đầu" ở Settings, số đã nhận cũng reset về 0 (tránh "vượt trước" số sao mới kiếm lại được, khiến viên ngọc mới đạt không hiện ra đúng lúc).

App **KHÔNG xử lý bất kỳ giao dịch tiền thật nào** - đây chỉ là bộ đếm/nhắc trong app, việc thưởng tiền hoàn toàn do bố mẹ tự thực hiện ngoài app.

**LƯU Ý CHO VÒNG SAU:**
- Dạng bài `QuestionKind.fillBlank` từ giờ LUÔN cần hiện hình minh hoạ - nếu sau này thêm `promptType: identify` mới mà không có emoji/swatchColor hợp lệ, `Word` constructor đã có `assert` chặn từ lúc parse JSON nên sẽ báo lỗi sớm, không lo sót.
- Ngân hàng Bài tranh (10 tranh/50 câu) và Play (19 bài/182 từ) vẫn còn có thể mở rộng tiếp nếu user muốn "phong phú" hơn nữa - chưa có giới hạn cứng nào được đặt ra.
- (2026-09-16: `llm_config.dart` đã bị XOÁ - key Gemini giờ cấu hình phía
  backend, không còn nhúng trong client, nên lưu ý này không còn áp dụng.)

## Vòng 15 (2026-09-08): Sửa lỗi giọng nói bị cắt cụt câu ở Chat

User báo: ở màn Chat (Tâm sự tự do với thú cưng), khi bé nói vào mic thì câu thoại bị nhận diện CẮT CỤT, không đầy đủ. Đây là lỗi CŨ đã từng được "sửa" ở Vòng 11 (2026-08-23, tăng `pauseFor` từ 2s mặc định lên 4s) nhưng thực ra chưa hết hẳn.

**Nguyên nhân thật sự** (tra lại đúng tài liệu chính thức của package `speech_to_text`, không đoán): trên Android, hệ điều hành áp 1 giới hạn CỨNG ở tầng native - "system imposed pause of from one to three seconds that cannot be overridden" - tức app đặt `pauseFor` bao lâu cũng vậy, máy Android vẫn có thể tự ý dừng nghe sau ~1-3 giây im lặng. Việc tăng lên 4s ở Vòng 11 gần như KHÔNG có tác dụng thật trên Android (chỉ có ích thật trên iOS, nơi `pauseFor` được tôn trọng đúng).

**Đã sửa** (`speech_service.dart`, `SpeechService.listenOnce`): vì không thể "xin" hệ điều hành chờ lâu hơn, chuyển sang hướng khác - khi 1 phiên nghe bị dừng sớm do im lặng mà bé CHƯA chủ động bấm nút "nói xong", tự động MỞ LẠI 1 phiên nghe mới ngay lập tức và NỐI phần nhận diện được vào câu đang có, lặp lại tới khi: bé chủ động dừng, hết tổng thời gian `listenFor`, hoặc 2 phiên liên tiếp không nhận thêm được từ nào (coi như nói xong thật). Với bé, cảm giác mic vẫn nghe liên tục dù bên dưới là nhiều phiên ngắn nối lại.

Cơ chế "tự nối phiên" này chỉ bật cho Chat qua tham số mới `allowContinuation: true` (mặc định `false`) - vì bật cho MỌI nơi dùng giọng nói sẽ khiến các màn chỉ cần 1 từ ngắn (học từ vựng, tra từ điển, bài tranh, chào hỏi ở Home) bị chờ lâu hơn không cần thiết (phát hiện qua review độc lập). Cũng đã bọc try/catch quanh mỗi phiên nghe nối tiếp để nếu 1 phiên SAU bị lỗi, không làm mất phần câu ĐÃ nhận diện đúng từ các phiên TRƯỚC đó (cũng phát hiện qua review độc lập).

**LƯU Ý CHO VÒNG SAU:**
- Giới hạn ~1-3s im lặng của Android là ở tầng OS/plugin, không phải bug của app - nếu sau này vẫn còn cảm giác "hơi khựng" giữa các phiên nối (độ trễ mở lại phiên mới), có thể cân nhắc thêm chỉ báo UI nhỏ (ví dụ mic nhấp nháy nhẹ) để bé yên tâm mic vẫn đang nghe.
- KHÔNG bật `allowContinuation: true` cho các nơi dùng giọng nói khác (học từ vựng, tra từ điển, bài tranh) trừ khi có lý do rõ ràng - xem giải thích trong doc comment `SpeechService.listenOnce`.
- (2026-09-16: `llm_config.dart` đã bị XOÁ - key Gemini giờ cấu hình phía
  backend, không còn nhúng trong client, nên lưu ý này không còn áp dụng.)

## Vòng 16 (2026-09-09): Làm phong phú thêm bài học Play (Days/Months/Shapes/Toys) - cho bé đã lên Movers

User cho biết bé đã học lớp **Cambridge YLE Movers** và yêu cầu tiếp tục làm phong phú Play. Đối chiếu wordlist chính thức Movers/Starters với 19 bài đang có (182 từ) để tìm mảng còn thiếu - phát hiện 4 chủ đề CHƯA có: Ngày trong tuần, Tháng trong năm, Hình khối, Đồ chơi (đều là mục có trong wordlist chính thức Cambridge, hay xuất hiện trong đề thi Movers thật).

**Đã thêm 4 bài mới vào `lessons.json`, nâng tổng từ 19→23 bài / 182→221 từ:**
- `days_v1` "Days of the Week" (7 từ: Monday-Sunday) và `months_v1` "Months of the Year" (12 từ: January-December) - dùng `PromptType.repeat` (Mimi đọc mẫu, bé lặp lại) vì đây là khái niệm trừu tượng, không có "1 tranh đúng duy nhất" để nhận diện - đúng nguyên tắc đã rút ra từ Vòng 14 (tránh lặp lại lỗi câu hỏi lấp lửng). Emoji ngày dùng số thứ tự 1️⃣-7️⃣ (Monday=1 theo chuẩn ISO 8601), emoji tháng gắn với hình ảnh mùa/lễ hội dễ nhớ.
- `shapes_v1` "Shapes" (10 từ: circle/square/triangle/star/heart/diamond/oval/cross/arrow/crescent) - dùng `PromptType.identify` (có tranh nhận diện + câu điền từ/sắp xếp câu như bài thường) vì hình khối là khái niệm CÓ hình đúng duy nhất, phù hợp kiểm tra hiểu bài thật sự.
- `toys_v1` "Toys & Games" (10 từ: teddy bear/balloon/present/blocks/yoyo/skateboard/scooter/slide/game/bubbles) - riêng "teddy bear" (cụm 2 từ) dùng `PromptType.repeat` giống cách đã xử lý "get dressed" ở Vòng 13, các từ đơn còn lại dùng `identify` bình thường. Đã tránh trùng với các từ đồ chơi đã có sẵn ở `hobbies_v1` (puzzle/kite/doll/robot).

**Quy trình**: tự soạn nội dung trực tiếp bằng script (không delegate agent vì đây là dữ liệu từ vựng có cấu trúc rõ ràng, tự viết kiểm soát chính xác hơn) → chạy validation Python (id trùng, emoji trùng trong 1 bài, câu mẫu điền từ khớp với câu đã tách từ) → 1 subagent review độc lập rà nội dung mới, phát hiện và ĐÃ SỬA: emoji ➕ cho "cross" đọc thành dấu cộng chứ không phải hình chữ thập (đổi sang ✝️, sửa cả câu ví dụ cho tự nhiên hơn); emoji 🎲 (xúc xắc) cho "game" dễ nhầm thành "dice" (đổi sang 🎮 - tay cầm chơi game, rõ nghĩa hơn); emoji 🦃 (gà tây) cho tháng 11 và 🎆 (pháo hoa) cho tháng 7 là hình ảnh gắn với văn hoá Mỹ (Lễ Tạ Ơn, Quốc khánh Mỹ), không có ý nghĩa với bé Việt Nam - đổi sang 🧣 (khăn quàng cổ, trời se lạnh) và 🍉 (dưa hấu, mùa hè) dễ liên tưởng hơn; "skateboard" và "scooter" dùng chung 1 mẫu câu "I ride my ___." hơi lặp - đã đổi câu của scooter thành "I zoom on my ___." cho đa dạng.

**LƯU Ý CHO VÒNG SAU:**
- Ngân hàng Play giờ 23 bài/221 từ, vẫn có thể mở rộng tiếp (ví dụ: Prepositions of Place - vị trí in/on/under/next to - đã cân nhắc ở vòng này nhưng nhận thấy phù hợp làm 1 "Bài tranh" (Picture Scene) mới hơn là 1 bài Play, vì giới từ chỉ vị trí cần 1 KHUNG CẢNH đầy đủ để minh hoạ đúng nghĩa, không hợp với format "1 từ - 1 emoji" của Play).
- Phát hiện (không phải lỗi mới, có sẵn từ Vòng 6/7): bài `animals_colors_v1` dùng chung emoji 👋 cho cả "hello" và "goodbye" - không gây lỗi chức năng nào (mỗi từ vẫn chỉ hiện đúng emoji của chính nó khi tới lượt), chỉ là 2 từ cùng dùng 1 biểu tượng bàn tay vẫy - có thể cân nhắc đổi 1 trong 2 nếu có vòng sau rà lại nội dung cũ.
- (2026-09-16: `llm_config.dart` đã bị XOÁ - key Gemini giờ cấu hình phía
  backend, không còn nhúng trong client, nên lưu ý này không còn áp dụng.)

## Gợi ý các chức năng để phát triển tiếp

### Giai đoạn 1 - Mimi "sống" hơn ✅ (xong, đã nâng cấp lên vector)
- ✅ Mimi được **vẽ bằng vector** (Canvas, `lib/presentation/widgets/mimi_painter.dart`)
  thay vì ảnh PNG chụp màn hình như bản đầu - luôn nét ở mọi kích thước, siêu
  nhẹ, không cần ảnh ngoài. Đây là kết quả áp dụng gợi ý bạn tham khảo được
  từ Gemini (vector + animation theo từng bộ phận, kiểu SVG + CSS animation) -
  dịch lại bằng công cụ vẽ của Flutter (`CustomPainter`) vì code HTML/CSS/SVG
  gốc chạy trên trình duyệt, không nhúng thẳng vào app Flutter được.
- ✅ Animation mượt hơn hẳn nhờ vẽ theo từng bộ phận độc lập: **chớp mắt
  thật** (mí mắt khép lại rồi mở ra ngẫu nhiên mỗi 3-6s), **vẫy tai** ngẫu
  nhiên khi rảnh, tai vểnh lên khi lắng nghe, miệng mấp máy + gật đầu nhẹ khi
  nói, **nhún nhảy** khi vui (thay vì chỉ "nảy lên" 1 lần).
- ✅ Đã cho bé chạm/vuốt ve Mimi ở Home: chạm vào Mimi có thêm hiệu ứng
  "giggle" (lắc lư đáng yêu) + Mimi nói 1 câu ngẫu nhiên, KHÔNG cộng sao (để
  phân biệt rõ với việc học ở tab Play). Ngoài ra có thể **kéo nhẹ Mimi** rồi
  thả ra, Mimi sẽ đàn hồi bật lại đúng vị trí.
- Rive/Lottie thật (file .riv/.json do hoạ sĩ dựng) vẫn chưa cần thiết nữa -
  cách vẽ vector hiện tại đã giải quyết được vấn đề chính (ảnh mờ, animation
  cứng) mà không cần thuê thêm hoạ sĩ/công cụ riêng. Nếu sau này vẫn muốn có
  animation do hoạ sĩ thiết kế tay, chỉ cần thêm package `rive` và sửa
  `PetAvatar` - kiến trúc hiện tại (PetAvatar là nơi duy nhất vẽ Mimi) vẫn
  sẵn sàng cho việc này.
- ✅ (2026-08-20) Thêm nhiều tương tác hơn với Mimi ở Home:
  - **Kéo tai**: bé chạm đúng vào tai trái/phải, Mimi phản ứng riêng (tai
    giật/kéo dài ra + câu thoại khác với chạm vào thân) - PetAvatar tự nhận
    biết bé chạm vào tai hay thân/đầu (`hitTestMimi` trong `mimi_painter.dart`).
  - **3 nút "chơi cùng Mimi"**: Xoay vòng 🌀, Nhảy chơi 🦘, Cho ăn 🥕 - đều chỉ
    để vui, KHÔNG cộng sao (giữ đúng nguyên tắc phân biệt với học ở tab Play).
    Cơ chế qua `PetAvatarController` (`pet_avatar.dart`) - màn hình nào cũng
    có thể tự thêm nút chơi riêng mà không cần sửa PetAvatar.
- Chưa làm (có chủ đích, xem ghi chú cuối `pet_avatar.dart`): nhào lộn 360°
  kiểu lộn ngược đầu (khác xoay tại chỗ đang có, cần phối cảnh 3D phức tạp
  hơn), âm thanh tổng hợp kiểu "Boing/Giggle" (cần thêm 1 package âm thanh
  mới - cân nhắc kỹ trước vì package mới từng gây lỗi build Android như
  `speech_to_text` gặp phải, nên chưa thêm vội).

### Giai đoạn 2 - Mở rộng nội dung học
- ✅ (2026-08-21) Thêm bài **Family** (6 từ) và **Numbers 1-5** (6 từ), cạnh
  bài Animals & Colors gốc.
- ✅ (2026-08-21) **6 kiểu bài tập** (nói/chọn/điền từ/sắp xếp câu/chính
  tả/luyện phát âm) - xem mục "6 kiểu bài tập trong 1 bài học" ở trên. Kiểu
  "điền từ"/"sắp xếp câu" chính là bước đầu của "cụm từ ngắn"/"câu đơn giản"
  từng đề ra bên dưới.
- ✅ (2026-08-21) Thêm **6 bài mức Movers** (mỗi bài 10 từ, phong phú hơn cho
  bé đã qua trình độ nhập môn): Weather & Seasons, Feelings, Actions &
  Sports, Food & Drinks, Clothes, Transportation - xem mục "Gamification:
  Tim, Streak, bản đồ bài học" ở trên.
- ✅ (2026-08-31) Thêm **6 bài mới** (mỗi bài 10 từ): Jobs, Places in Town,
  School Things, Daily Routine, Body & Health, House & Furniture - xem mục
  "Vòng 13" ở trên. Play hiện có 15 bài / 142 từ.
- Còn thiếu: các chủ đề mức cao hơn nữa (Flyers level) khi bé tiến bộ thêm.
- Bài "Ôn tập" trộn ngẫu nhiên các từ đã học trước đó, ưu tiên hỏi lại từ
  bé lâu chưa ôn (một dạng spaced-repetition đơn giản).

### Giai đoạn 3 - Gamification sâu hơn
- ✅ (2026-08-21) **Tim, streak, bản đồ bài học, câu hỏi trắc nghiệm, âm
  thanh** - xem mục "Gamification: Tim, Streak, bản đồ bài học" ở trên.
- ✅ (2026-08-22) **Shop đổi sao lấy phụ kiện** (mũ, nơ, vòng hoa, khăn, huy
  chương...) mặc cho thú cưng - xem mục "Phụ kiện thời trang cho thú cưng" ở
  trên.
- ✅ (2026-08-23) **Hiệu ứng ăn mừng khi đạt streak mới** (confetti + âm
  thanh) - xem mục "Vòng 11" ở trên.
- Huy hiệu thành tích (hoàn thành bài học đầu tiên, học liên tục 3 ngày...).
- Mimi "lớn lên"/lên cấp theo tiến độ học của bé.
- Vẽ đường nối liền giữa các điểm trên bản đồ Play (hiện chỉ xếp zíc-zắc).

### Giai đoạn 4 - Giọng nói & AI nâng cao
- ✅ (2026-08-21) **Chat tự do với thú cưng qua Gemini AI** (miễn phí, cần tự
  lấy API key) - xem mục "LLM: Tâm sự với thú cưng (Gemini)" ở trên.
- ✅ (2026-09-16) **Key Gemini chuyển sang backend proxy** (không còn nhúng
  trong client - bắt buộc vì app giờ public trên web) - xem
  `backend/app/routers/gemini.py`.
- ✅ (2026-08-23) **Gợi ý sửa lỗi ngữ pháp** nhẹ nhàng cho tin nhắn của bé ở
  Chat - xem mục "Avatar của bé & Gợi ý ngữ pháp ở Chat" ở trên. CHƯA làm
  đánh giá phát âm chi tiết (không chỉ đúng/sai từ mà cả độ chuẩn phát âm) -
  cố ý để dành riêng cho bài "Luyện phát âm" ở tab Play, xem lý do kỹ thuật
  trong mục vừa nêu.
- ✅ (2026-08-23) **Nút dịch 🌐 ở Chat** + **tab Từ điển** (tra 2 chiều Anh-
  Việt, nghe phát âm, kiểm tra phát âm bé đọc theo) - xem mục "Vòng 11" ở
  trên.
- Giọng đọc tự nhiên hơn (ví dụ Google Cloud TTS/ElevenLabs) thay giọng
  máy on-device - có thể phát sinh phí tuỳ mức dùng.

### Giai đoạn 5 - Dành cho phụ huynh
- Màn hình phụ huynh có PIN bảo vệ: xem bé học bao lâu, từ nào còn yếu,
  tiến độ theo tuần.
- Giới hạn thời gian chơi mỗi ngày.
- ✅ (2026-09-16) **Backup/khôi phục tiến độ + đồng bộ cloud** - xem Giai
  đoạn 6 ngay dưới đây (đăng nhập bằng email, tiến độ tự đồng bộ, đổi điện
  thoại/máy vẫn giữ nguyên miễn đăng nhập cùng email).

### Giai đoạn 6 - Mở rộng kỹ thuật
- ✅ (2026-09-16) **Đồng bộ nhiều thiết bị (cloud sync)** - backend FastAPI +
  NeonDB (Postgres), đăng nhập không mật khẩu (mã 6 số qua email). Xem
  `deployment.md` + `backend/README.md`. Mỗi email = 1 hồ sơ riêng (chưa có
  UI chuyển đổi nhiều hồ sơ dưới 1 tài khoản - muốn thêm 1 bé khác, tạo thêm
  1 email khác).
- Hồ sơ nhiều bé (multi-profile) dưới CÙNG 1 tài khoản - chưa làm, xem ghi
  chú ngay trên.
- App KHÔNG còn offline-first tuyệt đối (cần mạng để đăng nhập lần đầu +
  đồng bộ) nhưng vẫn có cache cục bộ để dùng tạm khi mất mạng giữa chừng
  (xem `CloudStateStore`).

Đề xuất thứ tự ưu tiên: **Giai đoạn 1 (ảnh Mimi thật)** trước tiên vì đây là
yếu tố cảm xúc quan trọng nhất với bé, sau đó đến **Giai đoạn 2** (thêm bài
học) để tăng nội dung, rồi mới tới Giai đoạn 3-6 khi đã rõ bé thích phần nào
nhất.
