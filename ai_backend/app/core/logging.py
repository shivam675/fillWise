"""Logging utilities for the backend."""
import logging
from logging.config import dictConfig


LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "default": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
        }
    },
    "handlers": {
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "default",
        }
    },
    "root": {
        "handlers": ["console"],
        "level": "INFO",
    },
}


def configure_logging() -> None:
    """Apply project-wide logging configuration."""

    dictConfig(LOGGING_CONFIG)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)
