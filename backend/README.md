# Mimi Pet API (backend)

Backend FastAPI cho app Mimi English Pet - xử lý đăng nhập (mã 6 số gửi qua
email, không cần mật khẩu), đồng bộ tiến độ của bé giữa các thiết bị
(web + Android), và proxy gọi Gemini API (giữ API key ở server, không lộ ra
app public trên web).

Xem `../deployment.md` (thư mục gốc project Flutter) để biết hướng dẫn
deploy đầy đủ lên Render + NeonDB. File này chỉ hướng dẫn chạy THỬ cục bộ.

## Chạy thử cục bộ

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows
# source .venv/bin/activate     # macOS/Linux
pip install -r requirements.txt

uvicorn app.main:app --reload --port 8000
```

Mặc định (chưa khai `DATABASE_URL`) dùng SQLite (`dev.db` tự tạo trong thư
mục này) - không cần NeonDB thật để test. Mã đăng nhập sẽ IN RA CONSOLE
(chưa khai `SMTP_*`) thay vì gửi email thật.

Copy `.env.example` thành `.env` để tuỳ chỉnh biến môi trường lúc chạy cục
bộ (file `.env` đã có sẵn trong `.gitignore` - không commit lên GitHub).

## Cấu trúc

```
backend/
├── requirements.txt
├── .env.example
└── app/
    ├── main.py           - khởi tạo FastAPI, CORS, đăng ký router
    ├── db.py             - kết nối SQLAlchemy (SQLite dev / Postgres prod)
    ├── models.py         - 3 bảng: users, login_codes, profile_states
    ├── schemas.py        - Pydantic request/response cho auth + state
    ├── auth.py           - sinh/băm mã đăng nhập, tạo/xác thực JWT
    ├── email_sender.py   - gửi mã đăng nhập qua SMTP
    └── routers/
        ├── auth.py       - POST /auth/request-code, /auth/verify-code
        ├── state.py      - GET/PUT /me/state (đồng bộ tiến độ)
        └── gemini.py     - POST /me/gemini/generate (proxy Gemini)
```

## Kiểm tra nhanh bằng curl

```bash
# 1. Xin mã đăng nhập (mã sẽ hiện trong log console/terminal đang chạy uvicorn)
curl -X POST http://localhost:8000/auth/request-code \
  -H "Content-Type: application/json" -d '{"email":"test@example.com"}'

# 2. Xác nhận mã, lấy token
curl -X POST http://localhost:8000/auth/verify-code \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","code":"<mã 6 số>"}'

# 3. Đọc/ghi state (thay <token> bằng giá trị "token" ở bước 2)
curl http://localhost:8000/me/state -H "Authorization: Bearer <token>"
curl -X PUT http://localhost:8000/me/state -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" -d '{"state":{"stars":10}}'
```

## Thiết kế "1 blob JSON" thay vì nhiều bảng

`profile_states.state` gộp CHUNG toàn bộ tiến độ của bé (sao, tim, streak,
thú cưng đã tuỳ chỉnh, avatar, điểm thi thử...) vào 1 cột JSON duy nhất,
thay vì 1 bảng riêng cho mỗi loại dữ liệu - khớp với cách app Flutter vốn đã
lưu key-value đơn giản qua `SharedPreferences` (xem
`lib/services/cloud_state_store.dart` phía Flutter). Đánh đổi: không hỗ trợ
xử lý xung đột khi 2 thiết bị sửa CÙNG LÚC (ghi đè toàn bộ, "ai ghi sau
thắng") - chấp nhận được vì app chỉ phục vụ quy mô 1 gia đình, hiếm khi có 2
thiết bị cùng sửa đúng 1 thời điểm.
