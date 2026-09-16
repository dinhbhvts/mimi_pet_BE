"""Đăng nhập không mật khẩu (mã 6 số gửi qua email) + JWT.

Không dùng thư viện đăng nhập nặng (OAuth server...) vì chỉ phục vụ 1 gia
đình - JWT tự ký (HS256) là đủ, đơn giản, dễ tự đọc/sửa sau này.
"""
import hashlib
import os
import random
import string
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

_bearer = HTTPBearer(auto_error=False)


def generate_code() -> str:
    return "".join(random.choices(string.digits, k=6))


def hash_code(code: str) -> str:
    """Băm mã đăng nhập trước khi lưu DB - không lưu mã gốc, giống nguyên tắc
    lưu mật khẩu, dù mã chỉ dùng 1 lần và hết hạn sau 10 phút."""
    return hashlib.sha256(code.encode("utf-8")).hexdigest()


def create_access_token(user_id: str, email: str) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": user_id,
        "email": email,
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
