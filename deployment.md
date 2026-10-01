# Hướng dẫn triển khai Mimi Pet (web public + backend + database)

Tài liệu này hướng dẫn đưa Mimi Pet lên mạng thật - bản web (mở bằng link
trên bất kỳ trình duyệt nào, kể cả Safari trên iPhone/iPad) + backend đồng
bộ dữ liệu (NeonDB + Render) - dùng hoàn toàn dịch vụ MIỄN PHÍ.

**Cập nhật (2026-09-16)**: app giờ CÓ backend + database thật (trước đây
không có, xem lịch sử bên dưới mục "Vì sao giờ cần Render + NeonDB") - lý do:
gia đình dùng iOS không cài được app iOS miễn phí (Apple bắt buộc tài khoản
dev trả phí để cài lên máy thật quá 7 ngày), nên cần bản web dùng thay, và
vì có nhiều thiết bị (web + Android) cùng dùng, tiến độ của bé cần đồng bộ
qua lại thay vì mỗi máy 1 bản riêng.

## Điều quan trọng cần biết trước khi deploy

### Dùng trên iPhone/iPad (Safari) - cập nhật 2026-10-01

Mọi trình duyệt trên iPhone/iPad (kể cả Chrome cho iOS) đều chạy engine
WebKit của Apple, nên giới hạn dưới đây áp dụng cho tất cả.

**Đính chính:** bản ghi chú trước (2026-09-16) nói Safari "hầu như không hỗ
trợ" nghe giọng nói - chưa chính xác. Từ iOS 14.5, Safari CÓ bộ nhận dạng
giọng nói (`webkitSpeechRecognition`) và `speech_to_text` bản web dùng đúng
bộ này. Điều kiện: bật **Đọc chính tả** (Cài đặt → Cài đặt chung → Bàn phím
→ Đọc chính tả), cho phép micro, và trang phải chạy HTTPS (GitHub
Pages/Render tự có). Chất lượng vẫn kém ổn định hơn Chrome/Android.

Đã xử lý riêng cho iOS trong app:

- **Mic (`lib/services/speech_service.dart`, `SpeechService.planFor`)**: trên
  iOS web luôn nghe 1 phiên, KHÔNG bật chế độ nghe liên tục và KHÔNG tự mở
  lại phiên nghe (2 cơ chế này viết để vá giới hạn của Android, nhưng trên
  Safari làm lặp chữ hoặc bị chặn vì phiên mới không xuất phát từ 1 lần
  chạm). Safari tự dừng khi bé nói xong câu.
- **Giọng đọc/âm thanh (`web/index.html`)**: Safari chỉ cho phát tiếng sau
  khi người dùng đã chạm vào trang, và lần phát đầu phải nằm ngay trong lúc
  chạm. Câu trả lời ở Chat về sau khi chờ mạng nên trước đây có thể bị im.
  Giờ trang tự "mở khoá" giọng đọc + âm thanh ở lần chạm đầu tiên bất kỳ.
- **Lịch sử Chat**: Safari hay tự đóng tab chạy nền làm mất cuộc trò chuyện.
  Giờ 40 tin gần nhất được lưu trong state đồng bộ (`chatHistory`), mở lại
  (kể cả trên máy khác) vẫn còn; có nút 🗑 xoá cuộc trò chuyện.
- **Thêm vào Màn hình chính**: icon chú thỏ, tên "Mimi Pet", mở toàn màn
  hình như app (`web/manifest.json`, thẻ `apple-*` trong `web/index.html`).
- **Hướng dẫn trong app** (`lib/presentation/widgets/ios_web_tips.dart`):
  thẻ nhắc ở Home (chỉ hiện trên iPhone/iPad, ẩn được) và mục "Dùng trên
  iPhone/iPad" trong Cài đặt - thêm vào Màn hình chính, cho phép micro vĩnh
  viễn, bật Đọc chính tả, xử lý khi không nghe thấy tiếng.
- **Dự phòng khi mic vẫn không nghe**: ô "Gõ thay vào đây" (Home, bài học)
  và chế độ gõ chữ ở Chat - bé bấm biểu tượng micro TRÊN BÀN PHÍM iPhone để
  đọc, chữ tự điền vào ô (đi đường Đọc chính tả của bàn phím, khác với
  `webkitSpeechRecognition`). Xem `lib/presentation/widgets/type_instead_of_talk.dart`.

Còn hạn chế (cần thử trên máy thật):

- Chưa kiểm chứng trên iPhone thật (chỉ test được trên Chrome). Đặc biệt
  cần thử mic khi mở từ icon ở Màn hình chính - một số bản iOS hạn chế nhận
  dạng giọng nói ở chế độ này; nếu không nghe được, mở bằng Safari thường.
- "Kiểm tra phát âm" trong Từ điển vẫn phụ thuộc mic của trình duyệt.
  Hướng khắc phục triệt để (dự kiến): ghi âm rồi gửi qua backend cho Gemini
  nhận dạng - chạy giống nhau trên mọi máy, không phụ thuộc Safari.

Bản Android (`flutter build apk`) vẫn là trải nghiệm mic mượt nhất.

## Kiến trúc tổng quan

```
Flutter app (web + Android, CÙNG 1 mã nguồn)
   │  HTTP + đăng nhập JWT
   ▼
Backend FastAPI (thư mục backend/, deploy trên Render)
   │  SQLAlchemy
   ▼
NeonDB (Postgres) - lưu tài khoản + tiến độ của bé
```

Mỗi bé/phụ huynh đăng nhập bằng **username + mật khẩu** (10 tài khoản
`mimi01`..`mimi10` được TỰ ĐỘNG tạo sẵn mỗi khi backend khởi động, mật khẩu
mặc định `Bong@1808`, xem `backend/app/seed.py`) - tiến độ (sao, tim,
streak, thú cưng đã tuỳ chỉnh, avatar, điểm thi thử...) đồng bộ tự động giữa
mọi thiết bị đăng nhập cùng 1 tài khoản. Đổi mật khẩu ngay trong app (Cài
đặt → Đổi mật khẩu) sau khi đăng nhập lần đầu.

**Lịch sử**: bản đầu dùng đăng nhập không mật khẩu (mã 6 số gửi qua email),
sau đổi sang gọi API email bên thứ 3 (Brevo) vì Render chặn cổng SMTP - cả 2
cách đều bị đánh giá phức tạp không cần thiết cho 1 app dùng trong gia đình,
nên quay lại username/mật khẩu truyền thống với vài tài khoản cố định.

## Phần 1: Deploy backend lên Render + NeonDB

### Bước 1.1: Tạo database trên NeonDB

1. Vào https://neon.tech , đăng ký tài khoản miễn phí (đăng nhập bằng
   GitHub cho nhanh).
2. Tạo 1 project mới (ví dụ đặt tên "mimi-pet").
3. Vào tab **Connection Details**, copy chuỗi kết nối dạng
   `postgresql://<user>:<password>@<host>/<dbname>?sslmode=require` - đây
   chính là giá trị sẽ dán vào biến môi trường `DATABASE_URL` ở bước 1.3.

### Bước 1.2: Đưa code backend lên GitHub

Nếu project chưa có git/GitHub (xem thêm ở Phần 2, Bước 2.2 - chỉ cần làm 1
lần cho cả backend lẫn web):

```bash
cd D:\DinhBH\MimiProjects\mimi_pet
git init
git add .
git commit -m "Mimi Pet MVP"
git remote add origin https://github.com/<ten-user-github>/mimi_pet.git
git branch -M main
git push -u origin main
```

### Bước 1.3: Tạo Web Service trên Render

1. Vào https://render.com , đăng ký miễn phí bằng tài khoản GitHub.
2. Bấm **New → Web Service**, chọn repo `mimi_pet` vừa đẩy lên.
3. Điền cấu hình:
   - **Root Directory**: `backend`
   - **Runtime**: Python 3
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`
   - **Instance Type**: Free
4. Ở phần **Environment Variables**, thêm từng biến (xem giải thích chi
   tiết trong `backend/.env.example`):
   | Biến | Giá trị |
   |---|---|
   | `DATABASE_URL` | Chuỗi kết nối NeonDB đã copy ở Bước 1.1 |
   | `JWT_SECRET` | 1 chuỗi ngẫu nhiên dài (chạy `python -c "import secrets; print(secrets.token_hex(32))"` để tạo) |
   | `GEMINI_API_KEY` | API key Gemini (lấy tại https://aistudio.google.com/apikey) - để trống nếu chưa dùng tính năng Chat/Từ điển |
   | `GEMINI_MODEL` | `gemini-3.6-flash` (model đang dùng được tại thời điểm viết tài liệu này - Google hay đổi tên model, xem mục "Chat không kết nối được AI thật?" bên dưới nếu gặp lỗi "Tên model Gemini không đúng") |
   | `ALLOWED_ORIGINS` | Domain web sẽ deploy ở Phần 2, ví dụ `https://<ten-user>.github.io` (nhiều domain cách nhau dấu phẩy) |
5. Bấm **Create Web Service**. Lần đầu build mất vài phút, xong sẽ có URL
   dạng `https://mimi-pet-be.onrender.com` - **ghi lại URL này**, cần dùng
   ở Phần 2 (biến `API_BASE_URL`).
6. Mở `https://<url-render-cua-ban>/health` trên trình duyệt - thấy
   `{"status":"ok"}` là backend đã chạy. Ngay từ lần khởi động ĐẦU TIÊN này,
   backend đã tự tạo sẵn 10 tài khoản `mimi01`..`mimi10` (mật khẩu mặc định
   `Bong@1808`) - không cần thao tác gì thêm, đăng nhập thử ngay được.

**Lưu ý gói Free của Render**: server tự "ngủ" sau ~15 phút không có ai gọi,
lần gọi đầu tiên sau khi ngủ sẽ mất thêm 30-60 giây để "thức dậy" (bé/phụ
huynh sẽ thấy màn đăng nhập load hơi lâu ở lần dùng đầu ngày) - đây là giới
hạn của gói miễn phí, không phải lỗi.

## Phần 2: Deploy bản web lên GitHub Pages

### Bước 2.1: Build thử cục bộ (tuỳ chọn, để kiểm tra trước khi deploy)

```bash
cd D:\DinhBH\MimiProjects\mimi_pet
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=https://<url-render-cua-ban>
```

`--dart-define=API_BASE_URL=...` **BẮT BUỘC** phải trỏ đúng URL backend
Render ở Phần 1 - thiếu tham số này, app sẽ cố gọi `localhost:8000` (không
tồn tại trên máy người dùng khác) và không đăng nhập được.

### Bước 2.2: Đưa code lên GitHub (nếu chưa làm ở Phần 1)

Xem Bước 1.2 ở trên.

### Bước 2.3: Kích hoạt workflow tự động build + deploy

File `.github/workflows/deploy.yml` đã có sẵn trong project, tự động build
và deploy lên GitHub Pages mỗi khi push lên nhánh `main`. Chỉ cần khai báo 1
**repository variable** (KHÔNG phải secret, vì URL Render không phải thông
tin bí mật) cho đúng URL backend của bạn:

1. Vào repo trên GitHub → **Settings → Secrets and variables → Actions** →
   tab **Variables** → **New repository variable**.
2. Đặt tên `API_BASE_URL`, giá trị là URL Render ở Phần 1 (ví dụ
   `https://mimi-pet-be.onrender.com` - KHÔNG có dấu `/` ở cuối).
3. Vào **Settings → Pages**, chọn **Source: Deploy from a branch**, chọn
   nhánh `gh-pages` (workflow tự tạo nhánh này sau lần chạy đầu, quay lại
   đây chọn SAU KHI đã push và workflow chạy xong lần đầu).

Push code (nếu vừa sửa gì) để kích hoạt workflow:

```bash
git add .
git commit -m "Deploy web + backend"
git push
```

Vào tab **Actions** trên GitHub xem tiến trình build. Xong, trang chạy tại
`https://<ten-user-github>.github.io/mimi_pet/`.

### Lựa chọn khác (tham khảo, không bắt buộc)

- **Vercel**: đơn giản hơn GitHub Pages ở bước cấu hình, tự build mỗi lần
  push, nhưng cần thêm 1 tài khoản thứ 3. Build Command:
  ```bash
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter && _flutter/bin/flutter build web --release --dart-define=API_BASE_URL=https://<url-render-cua-ban>
  ```
  Output Directory: `build/web`. Khai `API_BASE_URL` trong phần
  Environment Variables của Vercel nếu muốn tách khỏi build command.
- **Netlify/Cloudflare Pages**: tương tự Vercel.

## Vì sao giờ cần Render + NeonDB (trước đây thì không)

Bản MVP ban đầu của Mimi Pet **không cần backend**: mọi logic chạy trên máy
bé, tiến độ lưu bằng `shared_preferences` ngay trên thiết bị, API key Gemini
nhúng thẳng trong app (chấp nhận được vì app riêng tư, chỉ cài thủ công cho
1 bé, không phát tán công khai).

2 điều đã thay đổi khiến bắt buộc phải có backend:

1. **Đăng nhập + đồng bộ nhiều thiết bị**: bé giờ dùng cả web (iPad/Safari)
   lẫn app Android - cần 1 nơi TẬP TRUNG lưu tiến độ để cả 2 thiết bị thấy
   cùng 1 dữ liệu, đó là việc của Render (chạy backend) + NeonDB (lưu dữ
   liệu).
2. **API key Gemini không còn được nhúng trong app**: app giờ CÔNG KHAI
   trên web (ai có link cũng mở được), nếu vẫn nhúng key thẳng trong code,
   bất kỳ ai cũng xem được key qua Network tab của trình duyệt và dùng ké
   hết quota miễn phí của bạn. Backend giữ key hộ, app chỉ gọi qua backend
   (xem `backend/app/routers/gemini.py`).

## Tóm tắt các việc cần làm (theo đúng thứ tự)

1. Tạo project NeonDB, copy connection string (Bước 1.1).
2. Đẩy code lên GitHub nếu chưa có (Bước 1.2/2.2).
3. Tạo Web Service trên Render, khai đủ biến môi trường, lấy URL (Bước 1.3) -
   backend tự tạo sẵn 10 tài khoản `mimi01`..`mimi10` (mật khẩu mặc định
   `Bong@1808`) ngay lần khởi động đầu tiên, không cần thao tác gì thêm.
4. Khai biến `API_BASE_URL` trên GitHub Actions, bật GitHub Pages, push code
   (Bước 2.3).
5. Mở link GitHub Pages trên iPhone/iPad, đăng nhập bằng 1 trong 10 tài
   khoản trên, đổi mật khẩu ngay trong Cài đặt.
