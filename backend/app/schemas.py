"""Pydantic request/response models cho các route auth + state.

Route /me/gemini/generate KHÔNG có schema riêng ở đây - nhận/trả JSON tự do
(xem `routers/gemini.py`), vì đây là proxy TRONG SUỐT sang Gemini API (body
gửi lên/về giữ nguyên đúng định dạng phía Flutter đã xây dựng sẵn, backend
không cần hiểu cấu trúc bên trong).
"""
from typing import Any, Dict, Optional

from pydantic import BaseModel


class LoginIn(BaseModel):
    username: str
    password: str


class ChangePasswordIn(BaseModel):
    old_password: str
    new_password: str


class TokenOut(BaseModel):
    token: str
    username: str


class StateIn(BaseModel):
    state: Dict[str, Any]


class StateOut(BaseModel):
    state: Dict[str, Any]
    updatedAt: Optional[str] = None
