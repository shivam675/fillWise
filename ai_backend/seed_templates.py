"""Seed default templates from bundled JSON."""
from __future__ import annotations

import json
from pathlib import Path

from app import crud
from app.database import Base, SessionLocal, engine
from app.schemas import TemplateCreate

DATA_PATH = Path(__file__).parent / "app" / "data" / "default_templates.json"


def seed() -> None:
    Base.metadata.create_all(bind=engine)
    session = SessionLocal()
    try:
        with DATA_PATH.open("r", encoding="utf-8") as handle:
            templates = json.load(handle)

        for entry in templates:
            payload = TemplateCreate(**entry)
            crud.create_template(session, payload)

        session.commit()
        print(f"Seeded {len(templates)} templates")
    finally:
        session.close()


if __name__ == "__main__":
    seed()
