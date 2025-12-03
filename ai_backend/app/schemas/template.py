"""Pydantic schemas for template operations."""
from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, Field

from ..models.template import TemplateType


class TemplateVariableBase(BaseModel):
    name: str
    description: str | None = None
    data_type: str = Field(default="string", description="Expected data type e.g. string, number")
    required: bool = True
    default_value: str | None = None


class TemplateVariableCreate(TemplateVariableBase):
    pass


class TemplateVariableUpdate(TemplateVariableBase):
    required: bool | None = None


class TemplateVariable(TemplateVariableBase):
    id: str

    class Config:
        from_attributes = True


class TemplateBase(BaseModel):
    name: str
    description: str
    type: TemplateType = TemplateType.business
    prompt_template: str
    variables: list[dict[str, Any]] | None = Field(default_factory=list)
    tags: list[str] | None = Field(default_factory=list)
    category: str | None = None
    created_by: str | None = None
    version: str | None = None
    is_active: bool = True


class TemplateCreate(TemplateBase):
    template_variables: list[TemplateVariableCreate] | None = Field(default_factory=list)


class TemplateUpdate(BaseModel):
    name: str | None = None
    description: str | None = None
    type: TemplateType | None = None
    prompt_template: str | None = None
    variables: list[dict[str, Any]] | None = None
    tags: list[str] | None = None
    category: str | None = None
    created_by: str | None = None
    version: str | None = None
    is_active: bool | None = None
    template_variables: list[TemplateVariableUpdate] | None = None


class Template(TemplateBase):
    id: str
    created_at: datetime
    updated_at: datetime
    template_variables: list[TemplateVariable] | None = None

    class Config:
        from_attributes = True


class TemplateSearchResponse(BaseModel):
    total: int
    items: list[Template]


class ChatMessage(BaseModel):
    message: str
    session_id: str | None = None  # For conversation tracking
    template_id: str | None = None
    variables: dict[str, Any] | None = None


class ChatResponse(BaseModel):
    reply: str
    template_id: str | None = None
    variables: dict[str, Any] | None = None
    state: str = "idle"  # Conversation state
    pending_fields: list[str] = Field(default_factory=list)
    collected_values: dict[str, Any] = Field(default_factory=dict)
    generated_document: str | None = None
    document_title: str | None = None
