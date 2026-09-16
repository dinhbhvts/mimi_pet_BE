# Mimi Pet API (backend)

Backend FastAPI cho app Mimi English Pet - xử lý đăng nhập (username + mật
khẩu, 10 tài khoản `mimi01`..`mimi10` tự tạo sẵn lúc khởi động, xem
`app/seed.py`), đồng bộ tiến độ của bé giữa các thiết bị (web + Android), và
proxy gọi Gemini API (giữ API key ở server, không lộ ra app public trên
web).

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
mục này) - không cần NeonDB thật để test. Ngay khi khởi động, 10 tài khoản
`mimi01`..`mimi10` (mật khẩu mặc định `Bong@1808`) được tự động tạo sẵn -
đăng nhập thử ngay được, không cần thao tác gì thêm.

Copy `.env.example` thành `.env` để tuỳ chỉnh biến môi trường lúc chạy cục
bộ (file `.env` đã có sẵn trong `.gitignore` - không commit lên GitHub).

## Cấu trúc

```
backend/
├── requirements.txt
├── .env.example
└── app/
    ├── main.py           - khởi tạo FastAPI, CORS, đăng ký router, chạy seed
    ├── db.py             - kết nối SQLAlchemy (SQLite dev / Postgres prod)
    ├── models.py         - 2 bảng: users, profile_states
    ├── schemas.py        - Pydantic request/response cho auth + state
    ├── auth.py           - băm/so khớp mật khẩu (PBKDF2), tạo/xác thực JWT
    ├── seed.py           - tự tạo 10 tài khoản mimi01..mimi10 lúc khởi động
    └── routers/
        ├── auth.py       - POST /auth/login
        ├── account.py    - POST /me/change-password
        ├── state.py      - GET/PUT /me/state (đồng bộ tiến độ)
        └── gemini.py     - POST /me/gemini/generate (proxy Gemini)
```

## Kiểm tra nhanh bằng curl

```bash
# 1. Đăng nhập (dùng luôn 1 trong 10 tài khoản có sẵn)
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" -d '{"username":"mimi01","password":"Bong@1808"}'

# 2. Đọc/ghi state (thay <token> bằng giá trị "token" ở bước 1)
curl http://localhost:8000/me/state -H "Authorization: Bearer <token>"
curl -X PUT http://localhost:8000/me/state -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" -d '{"state":{"stars":10}}'

# 3. Đổi mật khẩu
curl -X POST http://localhost:8000/me/change-password -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"old_password":"Bong@1808","new_password":"MatKhauMoi123"}'
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
