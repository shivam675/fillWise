"""Document management - stores generated documents."""
from __future__ import annotations

import json
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Optional
from uuid import uuid4


@dataclass
class Document:
    """A generated document."""
    id: str
    title: str
    content: str
    template_id: Optional[str] = None
    template_name: Optional[str] = None
    filled_values: dict = field(default_factory=dict)
    created_at: str = ""
    updated_at: str = ""
    
    def __post_init__(self):
        if not self.created_at:
            self.created_at = datetime.utcnow().isoformat()
        if not self.updated_at:
            self.updated_at = self.created_at


class DocumentManager:
    """Manages saved documents using a JSON file."""
    
    def __init__(self, storage_path: Optional[Path] = None):
        if storage_path is None:
            storage_path = Path(__file__).parent.parent / "data" / "documents.json"
        self._storage_path = storage_path
        self._storage_path.parent.mkdir(parents=True, exist_ok=True)
    
    def _load_documents(self) -> list[Document]:
        """Load documents from JSON file."""
        if not self._storage_path.exists():
            return []
        
        try:
            with open(self._storage_path, 'r') as f:
                data = json.load(f)
                return [Document(**doc) for doc in data]
        except (json.JSONDecodeError, TypeError):
            return []
    
    def _save_documents(self, documents: list[Document]) -> None:
        """Save documents to JSON file."""
        with open(self._storage_path, 'w') as f:
            json.dump([asdict(doc) for doc in documents], f, indent=2)
    
    def list_documents(self) -> list[Document]:
        """Get all documents, newest first."""
        docs = self._load_documents()
        return sorted(docs, key=lambda d: d.created_at, reverse=True)
    
    def get_document(self, doc_id: str) -> Optional[Document]:
        """Get a document by ID."""
        docs = self._load_documents()
        for doc in docs:
            if doc.id == doc_id:
                return doc
        return None
    
    def create_document(self, title: str, content: str, 
                       template_id: Optional[str] = None,
                       template_name: Optional[str] = None,
                       filled_values: Optional[dict] = None) -> Document:
        """Create a new document."""
        doc = Document(
            id=str(uuid4()),
            title=title,
            content=content,
            template_id=template_id,
            template_name=template_name,
            filled_values=filled_values or {}
        )
        
        docs = self._load_documents()
        docs.append(doc)
        self._save_documents(docs)
        
        return doc
    
    def update_document(self, doc_id: str, title: Optional[str] = None,
                       content: Optional[str] = None,
                       filled_values: Optional[dict] = None) -> Optional[Document]:
        """Update an existing document."""
        docs = self._load_documents()
        
        for doc in docs:
            if doc.id == doc_id:
                if title is not None:
                    doc.title = title
                if content is not None:
                    doc.content = content
                if filled_values is not None:
                    doc.filled_values = filled_values
                doc.updated_at = datetime.utcnow().isoformat()
                
                self._save_documents(docs)
                return doc
        
        return None
    
    def delete_document(self, doc_id: str) -> bool:
        """Delete a document."""
        docs = self._load_documents()
        original_count = len(docs)
        docs = [d for d in docs if d.id != doc_id]
        
        if len(docs) < original_count:
            self._save_documents(docs)
            return True
        return False


# Singleton instance
document_manager = DocumentManager()
