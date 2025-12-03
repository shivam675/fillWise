"""SQLAlchemy models for user management."""
from datetime import datetime
from uuid import uuid4

from sqlalchemy import Boolean, DateTime, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from ..database import Base


class User(Base):
    """User account definition."""

    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid4()))
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    hashed_password: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    is_superuser: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Settings can be a JSON column or a separate table. For simplicity, let's keep it simple for now.
    # Or we can add a separate Settings model.
    openai_api_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    anthropic_api_key: Mapped[str | None] = mapped_column(String(255), nullable=True)
    selected_model: Mapped[str | None] = mapped_column(String(50), default="gpt-4o")
