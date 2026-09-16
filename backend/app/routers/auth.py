from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import create_access_token, generate_code, hash_code
from ..db import get_db
from ..email_sender import send_login_code
from ..models import LoginCode, ProfileState, User
from ..schemas import RequestCodeIn, TokenOut, VerifyCodeIn

router = APIRouter(prefix="/auth", tags=["auth"])

CODE_TTL_MINUTES = 10
RESEND_COOLDOWN_SECONDS = 60


def _aware(dt: datetime) -> datetime:
    """SQLite trả datetime "naive" (mất tzinfo) dù ta luôn lưu giờ UTC - gắn
    lại tzinfo=UTC để so sánh được với `datetime.now(timezone.utc)`. Với
    Postgres (production), datetime trả về đã có tzinfo nên dòng này an
    toàn/không đổi gì (replace cùng 1 giá trị UTC)."""
    return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)


@router.post("/request-code")
def request_code(payload: RequestCodeIn, db: Session = Depends(get_db)):
    email = payload.email.lower().strip()
    now = datetime.now(timezone.utc)

    recent = (
        db.query(LoginCode)
        .filter(LoginCode.email == email)
        .order_by(LoginCode.created_at.desc())
        .first()
    )
    if recent and (now - _aware(recent.created_at)) < timedelta(seconds=RESEND_COOLDOWN_SECONDS):
        raise HTTPException(status_code=429, detail="Vui lòng đợi một chút trước khi gửi lại mã.")

    code = generate_code()
    db.add(
        LoginCode(
            email=email,
            code_hash=hash_code(code),
            expires_at=now + timedelta(minutes=CODE_TTL_MINUTES),
        )
    )
    db.commit()

    send_login_code(email, code)
    return {"sent": True}


@router.post("/verify-code", response_model=TokenOut)
def verify_code(payload: VerifyCodeIn, db: Session = Depends(get_db)):
    email = payload.email.lower().strip()
    now = datetime.now(timezone.utc)

    entry = (
        db.query(LoginCode)
        .filter(LoginCode.email == email, LoginCode.consumed_at.is_(None))
        .order_by(LoginCode.created_at.desc())
        .first()
    )
    if entry is None or _aware(entry.expires_at) < now or entry.code_hash != hash_code(payload.code.strip()):
        raise HTTPException(status_code=400, detail="Mã không đúng hoặc đã hết hạn.")

    entry.consumed_at = now
    db.commit()

    user = db.query(User).filter(User.email == email).first()
    if user is None:
        user = User(email=email)
        db.add(user)
        db.commit()
        db.refresh(user)
        db.add(ProfileState(user_id=user.id, state={}))
        db.commit()

    token = create_access_token(user.id, user.email)
    return TokenOut(token=token, email=user.email)
