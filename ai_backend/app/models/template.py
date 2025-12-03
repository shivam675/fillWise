"""SQLAlchemy models for template management."""
from __future__ import annotations

from datetime import datetime
from enum import Enum
from uuid import uuid4

from sqlalchemy import Boolean, Column, DateTime, Enum as SQLEnum, ForeignKey, JSON, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from ..database import Base


class TemplateType(str, Enum):
    """Allowed categories for templates."""

    business = "business"
    legal = "legal"
    marketing = "marketing"
    technical = "technical"
    financial = "financial"
    hr = "hr"
    custom = "custom"


class Template(Base):
    """Business document template definition."""

    __tablename__ = "templates"

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid4()))
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    type: Mapped[TemplateType] = mapped_column(SQLEnum(TemplateType), nullable=False, default=TemplateType.business)
    prompt_template: Mapped[str] = mapped_column(Text, nullable=False)
    variables: Mapped[list[dict] | None] = mapped_column(JSON, default=list)
    tags: Mapped[list[str] | None] = mapped_column(JSON, default=list)
    category: Mapped[str | None] = mapped_column(String(120))
    created_by: Mapped[str | None] = mapped_column(String(120), default="system")
    version: Mapped[str | None] = mapped_column(String(50), default="1.0.0")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    template_variables: Mapped[list[TemplateVariable]] = relationship(
        "TemplateVariable",
        back_populates="template",
        cascade="all, delete-orphan",
        lazy="joined",
    )


class TemplateVariable(Base):
    """Represents structured variables required by a template."""

    __tablename__ = "template_variables"
    __table_args__ = (UniqueConstraint("template_id", "name", name="uq_template_variable_name"),)

    id: Mapped[str] = mapped_column(String, primary_key=True, default=lambda: str(uuid4()))
    template_id: Mapped[str] = mapped_column(String, ForeignKey("templates.id", ondelete="CASCADE"), nullable=False)
    name: Mapped[str] = mapped_column(String(120), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    data_type: Mapped[str] = mapped_column(String(50), default="string")
    required: Mapped[bool] = mapped_column(Boolean, default=True)
    default_value: Mapped[str | None] = mapped_column(String(255))

    template: Mapped[Template] = relationship("Template", back_populates="template_variables")
