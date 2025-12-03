# AI Template Agent

Production-ready reference architecture that pairs a FastAPI backend with a Flutter desktop client to deliver AI-assisted business document generation.

## Repository Layout

- `ai_backend/` – FastAPI + SQLAlchemy service exposing template CRUD, chat endpoint, health checks, and SQLite persistence.
- `flutter_client/` – Flutter desktop UI implementing Provider-based state management, WeMod-inspired theme, chat interface, and template management screens.

## Quick Start

### Backend
```bash
cd ai_backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

### Frontend
```bash
cd flutter_client
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000
```

## Development Workflow
1. Start FastAPI backend (`uvicorn app.main:app --reload`).
2. Launch Flutter app with hot-reload (`flutter run -d chrome`).
3. Use `flutter packages pub run build_runner build --delete-conflicting-outputs` for generated code when adding serializers.

## Testing
- Backend: `cd ai_backend && pytest`
- Frontend: `cd flutter_client && flutter test`

## Architecture Highlights
- Fully typed SQLAlchemy models (`Template`, `TemplateVariable`).
- Provider pattern for reactive Flutter UI (`TemplateProvider`, `ChatProvider`).
- Repaint boundary isolation for heavy widgets (`TemplateCard`).
- Toast notifications and API service abstractions for consistent UX.
