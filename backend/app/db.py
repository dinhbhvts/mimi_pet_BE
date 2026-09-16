"""Kết nối database - mặc định SQLite cục bộ (test không cần NeonDB thật),
production trỏ DATABASE_URL sang Postgres (NeonDB) qua biến môi trường.
"""
import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker

_raw_url = os.environ.get("DATABASE_URL", "sqlite:///./dev.db")

# NeonDB (và hầu hết hướng dẫn Postgres) đưa connection string dạng
# "postgres://..." hoặc "postgresql://..." - tự thêm driver "+psycopg" (psycopg3,
# có sẵn nhiều wheel hơn psycopg2 cho các bản Python mới) để khỏi phải sửa tay
# chuỗi kết nối copy từ NeonDB dán thẳng vào biến môi trường.
if _raw_url.startswith("postgres://"):
    DATABASE_URL = _raw_url.replace("postgres://", "postgresql+psycopg://", 1)
elif _raw_url.startswith("postgresql://"):
    DATABASE_URL = _raw_url.replace("postgresql://", "postgresql+psycopg://", 1)
else:
    DATABASE_URL = _raw_url

connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}
engine = create_engine(DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
