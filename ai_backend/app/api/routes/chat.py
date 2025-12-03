"""Chat interface endpoints."""
from __future__ import annotations

from fastapi import APIRouter, status
from uuid import uuid4

from ...schemas import ChatMessage, ChatResponse
from ...services.chat_service import chat_service

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.post("/message", response_model=ChatResponse, status_code=status.HTTP_200_OK)
def send_message(payload: ChatMessage) -> ChatResponse:
    # Use provided session_id or generate one
    session_id = payload.session_id or str(uuid4())
    
    # Process message through the chat service
    result = chat_service.process_message(
        session_id=session_id,
        message=payload.message,
        template_id=payload.template_id,
    )
    
    return ChatResponse(
        reply=result.reply,
        template_id=result.template_id,
        variables=payload.variables,
        state=result.state,
        pending_fields=result.pending_fields,
        collected_values=result.collected_values,
        generated_document=result.generated_document,
        document_title=result.document_title,
    )
