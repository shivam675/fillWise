"""FastAPI application entry-point."""
from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .api import api_router
from .core.config import get_settings
from .core.logging import configure_logging
from .database import Base, engine, SessionLocal
from .crud import user as crud_user
from .schemas.user import UserCreate


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging()

    app = FastAPI(title=settings.app_name)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_credentials=settings.cors_allow_credentials,
        allow_methods=settings.cors_allow_methods,
        allow_headers=settings.cors_allow_headers,
    )

    @app.on_event("startup")
    def _create_tables() -> None:
        Base.metadata.create_all(bind=engine)
        
        # Create default superuser
        db = SessionLocal()
        try:
            user = crud_user.get_by_email(db, email="admin")
            if not user:
                user_in = UserCreate(
                    email="admin",
                    password="admin1",
                    is_superuser=True,
                    full_name="Super Admin"
                )
                crud_user.create(db, obj_in=user_in)
        finally:
            db.close()

    @app.exception_handler(RequestValidationError)
    async def validation_exception_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=422,
            content={"error": "Validation failed", "details": exc.errors(), "path": request.url.path},
        )

    app.include_router(api_router, prefix=settings.api_prefix)

    return app


app = create_app()
