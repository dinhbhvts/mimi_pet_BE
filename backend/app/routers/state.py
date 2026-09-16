from datetime import datetime, timezone

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..auth import get_current_user
from ..db import get_db
from ..models import ProfileState, User
from ..schemas import StateIn, StateOut

router = APIRouter(prefix="/me", tags=["state"])


def _to_out(row: ProfileState) -> StateOut:
    return StateOut(
        state=row.state or {},
        updatedAt=row.updated_at.isoformat() if row.updated_at else None,
    )


@router.get("/state", response_model=StateOut)
def get_state(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    row = db.get(ProfileState, user.id)
    if row is None:
        row = ProfileState(user_id=user.id, state={})
        db.add(row)
        db.commit()
        db.refresh(row)
    return _to_out(row)


@router.put("/state", response_model=StateOut)
def put_state(
    payload: StateIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    row = db.get(ProfileState, user.id)
    now = datetime.now(timezone.utc)
    if row is None:
        row = ProfileState(user_id=user.id, state=payload.state, updated_at=now)
        db.add(row)
    else:
        row.state = payload.state
        row.updated_at = now
    db.commit()
    db.refresh(row)
    return _to_out(row)
