"""Schema DB - CHỈ 3 bảng, đủ cho quy mô 1 gia đình:
- users: 1 dòng / email đăng nhập.
- login_codes: mã 6 số dùng 1 lần để đăng nhập (không lưu mật khẩu).
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
    email = Column(String, unique=True, nullable=False, index=True)
    created_at = Column(DateTime(timezone=True), default=_now)


class LoginCode(Base):
    __tablename__ = "login_codes"

    id = Column(String, primary_key=True, default=_uuid)
    email = Column(String, nullable=False, index=True)
    code_hash = Column(String, nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    consumed_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=_now)


class ProfileState(Base):
    __tablename__ = "profile_states"

    user_id = Column(String, ForeignKey("users.id"), primary_key=True)
    # sqlalchemy.JSON (không phải JSONB riêng của Postgres) để chạy được trên
    # cả SQLite (dev cục bộ) lẫn Postgres/NeonDB (production).
    state = Column(JSON, nullable=False, default=dict)
    updated_at = Column(DateTime(timezone=True), default=_now, onupdate=_now)
