"""CRUD helpers for Template resources."""
from __future__ import annotations

from collections.abc import Sequence

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from ..models.template import Template, TemplateType, TemplateVariable
from ..schemas import TemplateCreate, TemplateUpdate


def list_templates(
    db: Session,
    *,
    search: str | None = None,
    type_filter: TemplateType | None = None,
    is_active: bool | None = None,
    skip: int = 0,
    limit: int = 20,
) -> tuple[int, Sequence[Template]]:
    filters = []

    if search:
        like_pattern = f"%{search.lower()}%"
        filters.append(Template.name.ilike(like_pattern) | Template.description.ilike(like_pattern))

    if type_filter:
        filters.append(Template.type == type_filter)

    if is_active is not None:
        filters.append(Template.is_active == is_active)

    base_query = select(Template)
    if filters:
        base_query = base_query.where(*filters)

    count_query = select(func.count()).select_from(Template)
    if filters:
        count_query = count_query.where(*filters)

    total = db.execute(count_query).scalar_one()
    items = db.execute(base_query.offset(skip).limit(limit)).scalars().unique().all()
    return total, items


def get_template(db: Session, template_id: str) -> Template | None:
    return db.get(Template, template_id)


def create_template(db: Session, payload: TemplateCreate) -> Template:
    template = Template(**payload.model_dump(exclude={"template_variables"}))

    for variable in payload.template_variables or []:
        template.template_variables.append(TemplateVariable(**variable.model_dump()))

    db.add(template)
    db.flush()
    return template


def update_template(db: Session, template: Template, payload: TemplateUpdate) -> Template:
    for key, value in payload.model_dump(exclude_unset=True, exclude={"template_variables"}).items():
        setattr(template, key, value)

    if payload.template_variables is not None:
        template.template_variables.clear()
        for variable in payload.template_variables:
            template.template_variables.append(
                TemplateVariable(**variable.model_dump(exclude_unset=True))
            )

    db.add(template)
    db.flush()
    return template


def delete_template(db: Session, template: Template) -> None:
    db.delete(template)
    db.flush()
