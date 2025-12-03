"""Template management API routes."""
from __future__ import annotations

from fastapi import APIRouter, HTTPException, Query, status

from ...core.template_manager import template_manager
from ...schemas.template_config import Template, TemplateCreate, TemplateList, TemplateUpdate

router = APIRouter(prefix="/templates", tags=["Templates"])


@router.get("/", response_model=TemplateList)
def list_templates(
    search: str | None = Query(default=None, description="Search by name or description"),
) -> TemplateList:
    items = template_manager.list_templates(search=search)
    return TemplateList(items=items, total=len(items))


@router.get("/{template_id}", response_model=Template)
def get_template(template_id: str) -> Template:
    template = template_manager.get_template(template_id)
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return template


@router.post("/", response_model=Template, status_code=status.HTTP_201_CREATED)
def create_template(payload: TemplateCreate) -> Template:
    return template_manager.create_template(payload)


@router.put("/{template_id}", response_model=Template)
def update_template(template_id: str, payload: TemplateUpdate) -> Template:
    template = template_manager.update_template(template_id, payload)
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    return template


@router.delete("/{template_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_template(template_id: str):
    success = template_manager.delete_template(template_id)
    if not success:
        raise HTTPException(status_code=404, detail="Template not found")
