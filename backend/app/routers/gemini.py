"""Proxy TRONG SUỐT sang Gemini API - giữ API key ở server (biến môi trường
GEMINI_API_KEY), không lộ ra client public (web/APK).

Nhận nguyên body JSON app đã xây dựng sẵn (systemInstruction/contents/
generationConfig/safetySettings - xem `gemini_chat_service.dart`/
`gemini_dictionary_service.dart` phía Flutter) và forward y nguyên sang
Google, trả JSON kết quả về y nguyên - backend KHÔNG cần hiểu cấu trúc bên
trong, nên không phải sửa lại nếu sau này đổi prompt/generationConfig phía
Flutter.
"""
import os
from typing import Any, Dict

import httpx
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse

from ..auth import get_current_user
from ..models import User

router = APIRouter(prefix="/me/gemini", tags=["gemini"])

GEMINI_BASE_URL = "https://generativelanguage.googleapis.com/v1beta/models"


@router.post("/generate")
async def generate(payload: Dict[str, Any], user: User = Depends(get_current_user)):
    api_key = os.environ.get("GEMINI_API_KEY", "")
    if not api_key:
        raise HTTPException(
            status_code=503,
            detail="Gemini chưa được cấu hình trên server (thiếu biến môi trường GEMINI_API_KEY).",
        )
    # "gemini-2.5-flash" ĐÃ BỊ GOOGLE KHAI TỬ (xác nhận qua lỗi 404 thật lúc
    # test: "model gemini-2.5-flash is no longer available to new users...
    # use models/gemini-3.6-flash") - dùng "gemini-3.6-flash" làm mặc định.
    # Nếu Google tiếp tục đổi tên model, xem `deployment.md` mục "Chat không
    # kết nối được AI thật?" để tự tra tên model mới đúng cho key của bạn.
    model = os.environ.get("GEMINI_MODEL", "gemini-3.6-flash")

    async with httpx.AsyncClient(timeout=25) as client:
        try:
            resp = await client.post(
                f"{GEMINI_BASE_URL}/{model}:generateContent",
                headers={"Content-Type": "application/json", "x-goog-api-key": api_key},
                json=payload,
            )
        except httpx.RequestError as exc:
            raise HTTPException(status_code=502, detail=f"Không gọi được Gemini: {exc}")

    try:
        body = resp.json()
    except ValueError:
        body = {"raw": resp.text}
    return JSONResponse(status_code=resp.status_code, content=body)
