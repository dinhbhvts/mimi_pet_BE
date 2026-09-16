from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ..auth import get_current_user, hash_password, verify_password
from ..db import get_db
from ..models import User
from ..schemas import ChangePasswordIn

router = APIRouter(prefix="/me", tags=["account"])

MIN_PASSWORD_LENGTH = 6


@router.post("/change-password")
def change_password(
    payload: ChangePasswordIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if not verify_password(payload.old_password, user.password_hash):
        raise HTTPException(status_code=400, detail="Mật khẩu hiện tại không đúng.")
    if len(payload.new_password) < MIN_PASSWORD_LENGTH:
        raise HTTPException(status_code=400, detail=f"Mật khẩu mới cần ít nhất {MIN_PASSWORD_LENGTH} ký tự.")

    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"changed": True}
