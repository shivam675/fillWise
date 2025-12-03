"""Application configuration and settings."""
from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings
from pydantic import AnyHttpUrl

BASE_DIR = Path(__file__).resolve().parent.parent


class Settings(BaseSettings):
    """Central application settings loaded from environment variables."""

    app_name: str = "AI Template Agent Backend"
    api_prefix: str = "/api"
    database_url: str = f"sqlite:///{BASE_DIR.parent / 'template_agent.db'}"
    allowed_origins: list[AnyHttpUrl | str] = ["http://localhost", "http://localhost:3000", "http://localhost:8080", "http://127.0.0.1"]
    cors_allow_credentials: bool = True
    cors_allow_methods: list[str] = ["*"]
    cors_allow_headers: list[str] = ["*"]
    default_page_size: int = 20
    max_page_size: int = 100
    environment: str = "development"
    secret_key: str = "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 30

    class Config:
        env_file = BASE_DIR.parent / ".env"
        env_file_encoding = "utf-8"


@lru_cache
def get_settings() -> Settings:
    """Return cached Settings instance."""

    return Settings()
