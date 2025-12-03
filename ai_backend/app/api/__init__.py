"""API router composition."""
from fastapi import APIRouter

from .routes import auth, chat, documents, health, templates, users, settings

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(templates.router)
api_router.include_router(chat.router)
api_router.include_router(documents.router)
api_router.include_router(settings.router, prefix="/settings", tags=["settings"])
