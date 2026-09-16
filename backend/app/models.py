"""Schema DB - CHỈ 2 bảng, đủ cho quy mô 1 gia đình:
- users: 1 dòng / tài khoản (đăng nhập bằng username + mật khẩu, xem
  `auth.py`).
- profile_states: TOÀN BỘ tiến độ của bé gộp chung 1 cột JSON (thay vì 1
  bảng riêng cho mỗi loại dữ liệu như sao/tim/streak/thú cưng...) - khớp với
  cách app hiện lưu key-value đơn giản qua SharedPreferences, xem
  `lib/services/cloud_state_store.dart` phía Flutter.
"""
import uuid
from datetime import datetime, timezone

from sqlalchemy import JSON, Column, DateTime, ForeignKey, String

from .db import Base


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=_uuid)
    username = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=_now)


class ProfileState(Base):
    __tablename__ = "profile_states"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    # sqlalchemy.JSON (không phải JSONB riêng của Postgres) để chạy được trên
    # cả SQLite (dev cục bộ) lẫn Postgres/NeonDB (production).
    state = Column(JSON, nullable=False, default=dict)
    updated_at = Column(DateTime(timezone=True), default=_now, onupdate=_now)
