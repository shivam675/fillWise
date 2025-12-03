"""Custom exception classes and helpers."""
from fastapi import HTTPException, status


class TemplateNotFoundError(HTTPException):
    """Raised when a template cannot be found."""

    def __init__(self, template_id: str) -> None:
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Template with id '{template_id}' was not found.",
        )


class TemplateConflictError(HTTPException):
    """Raised when template constraints are violated."""

    def __init__(self, message: str) -> None:
        super().__init__(status_code=status.HTTP_409_CONFLICT, detail=message)
