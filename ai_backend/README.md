# AI Template Agent Backend

FastAPI application exposing template CRUD APIs, chat endpoint, and health probe.

## Setup
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Key Endpoints
- `GET /api/health` – Service health probe
- `GET /api/templates` – Paginated template catalog with filters
- `POST /api/templates` – Create new template
- `POST /api/chat/message` – Send chat prompt with optional template context

## Testing
```bash
pytest
```

## Seeding Data
```bash
python seed_templates.py
```
