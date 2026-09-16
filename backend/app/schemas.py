"""Pydantic request/response models cho các route auth + state.

Route /me/gemini/generate KHÔNG có schema riêng ở đây - nhận/trả JSON tự do
(xem `routers/gemini.py`), vì đây là proxy TRONG SUỐT sang Gemini API (body
gửi lên/về giữ nguyên đúng định dạng phía Flutter đã xây dựng sẵn, backend
không cần hiểu cấu trúc bên trong).
"""
from typing import Any, Dict, Optional

from pydantic import BaseModel, EmailStr


class RequestCodeIn(BaseModel):
    email: EmailStr


class VerifyCodeIn(BaseModel):
    email: EmailStr
    code: str


class TokenOut(BaseModel):
    token: str
    email: str


class StateIn(BaseModel):
    state: Dict[str, Any]


class StateOut(BaseModel):
    state: Dict[str, Any]
    updatedAt: Optional[str] = None
