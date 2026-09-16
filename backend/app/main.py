import os
import sys

# Console Windows mặc định dùng cp1252, không encode được tiếng Việt có dấu -
# ép UTF-8 cho stdout/stderr (an toàn/không đổi gì trên Linux - nơi backend
# thực sự chạy khi deploy lên Render - vì ở đó locale đã là UTF-8 sẵn) để
# các câu print() tiếng Việt (vd `email_sender.py` lúc chưa cấu hình SMTP)
# không làm sập server khi chạy thử trên Windows.
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

from dotenv import load_dotenv

load_dotenv()

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .db import Base, engine
from .routers import auth, gemini, state

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Mimi Pet API")

_origins_raw = os.environ.get("ALLOWED_ORIGINS", "*")
_origins = [o.strip() for o in _origins_raw.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=_origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(state.router)
app.include_router(gemini.router)


@app.get("/health")
def health():
    return {"status": "ok"}
