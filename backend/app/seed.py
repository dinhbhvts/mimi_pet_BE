"""Tự động tạo sẵn 10 tài khoản mimi01..mimi10 (mật khẩu mặc định
"Bong@1808") mỗi khi server khởi động - IDEMPOTENT (chỉ tạo tài khoản nào
CHƯA có, không đụng tới tài khoản đã tồn tại/đã đổi mật khẩu), nên an toàn
để gọi lại ở MỌI lần khởi động, kể cả sau khi user đã tự đổi mật khẩu qua
`/me/change-password` - seed sẽ không ghi đè lại mật khẩu đã đổi.
"""
from .auth import hash_password
from .db import SessionLocal
from .models import ProfileState, User

DEFAULT_PASSWORD = "Bong@1808"
DEFAULT_ACCOUNT_COUNT = 10


def seed_default_accounts() -> None:
    db = SessionLocal()
    try:
        for i in range(1, DEFAULT_ACCOUNT_COUNT + 1):
            username = f"mimi{i:02d}"
            exists = db.query(User).filter(User.username == username).first()
            if exists is not None:
                continue
            user = User(username=username, password_hash=hash_password(DEFAULT_PASSWORD))
            db.add(user)
            db.commit()
            db.refresh(user)
            db.add(ProfileState(user_id=user.id, state={}))
            db.commit()
    finally:
        db.close()
