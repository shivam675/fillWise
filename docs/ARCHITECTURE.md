# System Architecture Guide

## Overview
- **Backend**: FastAPI + SQLAlchemy service inside `ai_backend`.
- **Frontend**: Flutter desktop app inside `flutter_client` using Provider pattern and Dio API service.

## Backend Modules
- `app/main.py` – Application factory, CORS, global exception handling.
- `app/api/routes` – REST endpoints for templates, chat, and health probes.
- `app/models` – ORM models with enums and relationships.
- `app/schemas` – Pydantic validation schemas.
- `app/services` – Chat orchestration placeholder (swap for LLM provider).
- `tests/` – Pytest health probe coverage.

## Frontend Modules
- `lib/app.dart` – Provider registrations and MaterialApp configuration.
- `lib/theme/` – WeMod-inspired color palette and ThemeData.
- `lib/providers/` – Template, chat, navigation, and document state.
- `lib/services/` – ApiService (Dio) and ToastService overlay.
- `lib/screens/` – Feature-based screens (Chat, Templates, Documents, Settings).
- `lib/widgets/` – Template cards and shared UI primitives.

## Data Flow
1. `TemplateProvider.refresh()` triggers `ApiService.fetchTemplates()`
2. FastAPI `/api/templates` queries SQLite via SQLAlchemy.
3. JSON response hydrated into `TemplateModel` on Flutter side.
4. Providers notify listening screens; `Consumer` widgets rebuild sections only.

## Chat Flow
1. User submits input on `ChatScreen`.
2. `ChatProvider.sendMessage()` optimistically appends user message and calls `ApiService.sendMessage()`.
3. Backend `/api/chat/message` optionally loads template context and returns AI draft.
4. Provider stores response, UI scrolls to most recent message, and toast notifications highlight success/failure.

## UI / UX
- WeMod-inspired palette defined in `lib/theme/colors.dart` and consumed via `AppTheme.darkTheme`.
- Sidebar navigation (Chat, Templates, Documents, Settings) implemented inside `HomeScreen` with `NavigationRail`.
- Toast notifications via `ToastService` overlay for non-blocking alerts.
- Template grid uses cards with chips, live search, and debounced updates for snappy UX.

## Performance Notes
- Flutter uses `RepaintBoundary` around cards/toasts to isolate expensive rebuilds.
- Debounced search input prevents redundant network calls.
- SQLAlchemy session dependency commits/rollbacks automatically for reliability.
- Pagination controls and query limits avoid unbounded result sets.

## Testing Strategy
- Backend: Pytest health checks and future CRUD coverage.
- Frontend: `flutter test` placeholder to bootstrap widget testing; extend with provider and integration suites.
