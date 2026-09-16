"""Đăng nhập bằng username + mật khẩu + JWT.

Không dùng thư viện đăng nhập nặng (OAuth server...) vì chỉ phục vụ 1 gia
đình - JWT tự ký (HS256) là đủ, đơn giản, dễ tự đọc/sửa sau này.

LỊCH SỬ (2026-09-16): bản đầu dùng đăng nhập KHÔNG mật khẩu (mã 6 số gửi qua
email, xem `email_sender.py` đã xoá) - nhưng gói Free của Render chặn hẳn
traffic ra ngoài ở cổng SMTP nên không gửi được email, và đổi sang gọi API
email bên thứ 3 (Brevo) bị người dùng đánh giá là quá phức tạp cho 1 app gia
đình. Quay lại cơ chế username/mật khẩu truyền thống, đơn giản hơn, không
phụ thuộc dịch vụ email nào - phù hợp hơn với vài tài khoản cố định
(`mimi01`..`mimi10`, xem `seed.py`) dùng trong gia đình.

Mật khẩu băm bằng PBKDF2-HMAC-SHA256 (thư viện chuẩn `hashlib`, không cần
cài thêm `bcrypt`/`passlib` - tránh phụ thuộc thêm gói cần biên dịch native
trên Render) kèm salt ngẫu nhiên riêng cho mỗi user, 260.000 vòng lặp (cùng
mức khuyến nghị OWASP 2023 cho PBKDF2-SHA256).
"""
import hashlib
import hmac
import os
from datetime import datetime, timedelta, timezone

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from .db import get_db
from .models import User

JWT_SECRET = os.environ.get("JWT_SECRET", "dev-secret-change-me-in-production")
JWT_ALGORITHM = "HS256"
# App cho bé dùng lâu dài trên thiết bị gia đình - hạn token dài để không bắt
# đăng nhập lại thường xuyên (khác 1 app ngân hàng/thương mại cần hạn ngắn).
JWT_EXPIRE_DAYS = 180

_PBKDF2_ITERATIONS = 260_000

_bearer = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    """Trả về chuỗi `<salt_hex>$<hash_hex>` để lưu thẳng vào cột
    `password_hash` - tự chứa salt nên không cần cột riêng."""
    salt = os.urandom(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, _PBKDF2_ITERATIONS)
    return f"{salt.hex()}${digest.hex()}"


def verify_password(password: str, stored_hash: str) -> bool:
    """So khớp mật khẩu - dùng `hmac.compare_digest` (so sánh thời gian không
    đổi) để tránh lộ thông tin qua timing attack, dù rủi ro không cao với quy
    mô app này."""
    try:
        salt_hex, digest_hex = stored_hash.split("$", 1)
    except ValueError:
        return False
    salt = bytes.fromhex(salt_hex)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, _PBKDF2_ITERATIONS)
    return hmac.compare_digest(digest.hex(), digest_hex)


def create_access_token(user_id: str, username: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "username": username,
        "iat": now,
        "exp": now + timedelta(days=JWT_EXPIRE_DAYS),
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing token")
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.PyJWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid or expired token")
    user = db.get(User, payload.get("sub"))
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")
    return user
