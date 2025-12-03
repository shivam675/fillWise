"""Document API endpoints."""
from __future__ import annotations

from typing import Any, Optional
from fastapi import APIRouter, HTTPException, status
from pydantic import BaseModel, Field

from ...core.document_manager import document_manager, Document

router = APIRouter(prefix="/documents", tags=["Documents"])


class DocumentCreate(BaseModel):
    title: str
    content: str
    template_id: Optional[str] = None
    template_name: Optional[str] = None
    filled_values: dict[str, Any] = Field(default_factory=dict)


class DocumentUpdate(BaseModel):
    title: Optional[str] = None
    content: Optional[str] = None
    filled_values: Optional[dict[str, Any]] = None


class DocumentResponse(BaseModel):
    id: str
    title: str
    content: str
    template_id: Optional[str] = None
    template_name: Optional[str] = None
    filled_values: dict[str, Any] = Field(default_factory=dict)
    created_at: str
    updated_at: str


class DocumentListResponse(BaseModel):
    total: int
    items: list[DocumentResponse]


@router.get("", response_model=DocumentListResponse)
def list_documents():
    """Get all saved documents."""
    docs = document_manager.list_documents()
    return DocumentListResponse(
        total=len(docs),
        items=[DocumentResponse(
            id=d.id,
            title=d.title,
            content=d.content,
            template_id=d.template_id,
            template_name=d.template_name,
            filled_values=d.filled_values,
            created_at=d.created_at,
            updated_at=d.updated_at
        ) for d in docs]
    )


@router.get("/{doc_id}", response_model=DocumentResponse)
def get_document(doc_id: str):
    """Get a document by ID."""
    doc = document_manager.get_document(doc_id)
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    
    return DocumentResponse(
        id=doc.id,
        title=doc.title,
        content=doc.content,
        template_id=doc.template_id,
        template_name=doc.template_name,
        filled_values=doc.filled_values,
        created_at=doc.created_at,
        updated_at=doc.updated_at
    )


@router.post("", response_model=DocumentResponse, status_code=status.HTTP_201_CREATED)
def create_document(payload: DocumentCreate):
    """Save a new document."""
    doc = document_manager.create_document(
        title=payload.title,
        content=payload.content,
        template_id=payload.template_id,
        template_name=payload.template_name,
        filled_values=payload.filled_values
    )
    
    return DocumentResponse(
        id=doc.id,
        title=doc.title,
        content=doc.content,
        template_id=doc.template_id,
        template_name=doc.template_name,
        filled_values=doc.filled_values,
        created_at=doc.created_at,
        updated_at=doc.updated_at
    )


@router.put("/{doc_id}", response_model=DocumentResponse)
def update_document(doc_id: str, payload: DocumentUpdate):
    """Update an existing document."""
    doc = document_manager.update_document(
        doc_id=doc_id,
        title=payload.title,
        content=payload.content,
        filled_values=payload.filled_values
    )
    
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    
    return DocumentResponse(
        id=doc.id,
        title=doc.title,
        content=doc.content,
        template_id=doc.template_id,
        template_name=doc.template_name,
        filled_values=doc.filled_values,
        created_at=doc.created_at,
        updated_at=doc.updated_at
    )


@router.delete("/{doc_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(doc_id: str):
    """Delete a document."""
    if not document_manager.delete_document(doc_id):
        raise HTTPException(status_code=404, detail="Document not found")
