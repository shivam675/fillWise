from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime
import uuid

class TemplateBase(BaseModel):
    name: str
    description: Optional[str] = None
    content: str  # This will store the rich text (HTML or JSON string)
    category: str = "custom"
    is_active: bool = True

class TemplateCreate(TemplateBase):
    pass

class TemplateUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    content: Optional[str] = None
    category: Optional[str] = None
    is_active: Optional[bool] = None

class Template(TemplateBase):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    created_at: datetime = Field(default_factory=datetime.utcnow)
    updated_at: datetime = Field(default_factory=datetime.utcnow)

class TemplateList(BaseModel):
    items: List[Template]
    total: int
