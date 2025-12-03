"""Conversation state manager for document creation workflows."""
from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional
from datetime import datetime
from uuid import uuid4

from .template_manager import template_manager
from ..schemas.template_config import Template


class ConversationState(str, Enum):
    """States of a document creation conversation."""
    IDLE = "idle"                           # No active document workflow
    TEMPLATE_DETECTED = "template_detected" # Template identified, extracting fields
    COLLECTING_INFO = "collecting_info"     # Asking user for missing field values
    READY_TO_GENERATE = "ready_to_generate" # All info collected, ready to create doc
    DOCUMENT_GENERATED = "document_generated" # Document created, can be edited/saved


@dataclass
class ConversationSession:
    """Tracks state of a single conversation."""
    id: str
    state: ConversationState = ConversationState.IDLE
    detected_template: Optional[Template] = None
    extracted_fields: dict[str, str] = field(default_factory=dict)  # field_name -> description
    collected_values: dict[str, Any] = field(default_factory=dict)  # field_name -> user value
    pending_fields: list[str] = field(default_factory=list)  # fields still needed
    current_asking_field: Optional[str] = None
    message_history: list[dict] = field(default_factory=list)  # conversation context
    generated_document: Optional[str] = None  # final document content
    document_title: Optional[str] = None


class ConversationManager:
    """Manages conversation sessions for document creation."""
    
    _sessions: dict[str, ConversationSession] = {}
    
    def get_or_create_session(self, session_id: str) -> ConversationSession:
        """Get existing session or create new one."""
        if session_id not in self._sessions:
            self._sessions[session_id] = ConversationSession(id=session_id)
        return self._sessions[session_id]
    
    def reset_session(self, session_id: str) -> ConversationSession:
        """Reset a session to idle state."""
        self._sessions[session_id] = ConversationSession(id=session_id)
        return self._sessions[session_id]
    
    def detect_template(self, prompt: str) -> Optional[Template]:
        """
        Detect if the user's message indicates they want to create a document.
        Returns the best matching template or None.
        """
        prompt_lower = prompt.lower()
        templates = template_manager.list_templates()
        
        best_match: Optional[Template] = None
        best_score = 0
        
        # Keywords that indicate document creation intent
        creation_keywords = ['create', 'make', 'generate', 'draft', 'write', 'prepare', 
                          'need', 'want', 'help me with', 'can you', "let's", 'lets']
        has_creation_intent = any(kw in prompt_lower for kw in creation_keywords)
        
        for template in templates:
            if not template.is_active:
                continue
                
            score = 0
            template_name_lower = template.name.lower()
            template_desc_lower = (template.description or '').lower()
            
            # Direct name match (highest priority)
            if template_name_lower in prompt_lower:
                score += 100
            
            # Check individual words from template name
            name_words = template_name_lower.split()
            for word in name_words:
                if len(word) > 2 and word in prompt_lower:
                    score += 30
            
            # Check description keywords
            if template_desc_lower:
                desc_words = template_desc_lower.split()
                for word in desc_words:
                    if len(word) > 3 and word in prompt_lower:
                        score += 10
            
            # Common document type aliases
            aliases = {
                'nda': ['non-disclosure', 'non disclosure', 'confidentiality', 
                       'confidential agreement', 'secrecy agreement'],
                'contract': ['agreement', 'deal', 'terms'],
                'invoice': ['bill', 'billing', 'payment'],
                'letter': ['correspondence', 'mail'],
                'proposal': ['offer', 'pitch', 'quotation'],
                'resume': ['cv', 'curriculum vitae'],
                'employment': ['job', 'hiring', 'work'],
            }
            
            for key, alias_list in aliases.items():
                if key in template_name_lower:
                    for alias in alias_list:
                        if alias in prompt_lower:
                            score += 50
            
            # Boost score if there's creation intent
            if has_creation_intent and score > 0:
                score = int(score * 1.5)
            
            if score > best_score:
                best_score = score
                best_match = template
        
        # Only return a match if confidence is high enough
        if best_score >= 30:
            return best_match
        return None
    
    def extract_template_text(self, content: str) -> str:
        """Extract plain text from template content (which may be Quill JSON)."""
        try:
            delta = json.loads(content)
            if isinstance(delta, list):
                text_parts = []
                for op in delta:
                    if isinstance(op, dict) and 'insert' in op:
                        insert = op['insert']
                        if isinstance(insert, str):
                            text_parts.append(insert)
                return ''.join(text_parts)
        except (json.JSONDecodeError, TypeError):
            pass
        return content
    
    def extract_placeholders(self, template_text: str) -> dict[str, str]:
        """
        Extract placeholders/fields from template text.
        Looks for patterns like:
        - {field_name}
        - [FIELD_NAME]
        - <field_name>
        - {{field_name}}
        - [Your Name], [Company Name], etc.
        - _______ (blank lines to fill)
        """
        placeholders = {}
        
        # Pattern: {field_name} or {{field_name}}
        curly_matches = re.findall(r'\{+([a-zA-Z_][a-zA-Z0-9_ ]*)\}+', template_text)
        for match in curly_matches:
            field_name = match.strip().replace(' ', '_').lower()
            placeholders[field_name] = f"Value for {match}"
        
        # Pattern: [FIELD NAME] or [Your Name]
        bracket_matches = re.findall(r'\[([A-Za-z][A-Za-z0-9 _]+)\]', template_text)
        for match in bracket_matches:
            field_name = match.strip().replace(' ', '_').lower()
            placeholders[field_name] = f"Value for {match}"
        
        # Pattern: <field_name>
        angle_matches = re.findall(r'<([a-zA-Z_][a-zA-Z0-9_]*)>', template_text)
        for match in angle_matches:
            field_name = match.strip().lower()
            placeholders[field_name] = f"Value for {match}"
        
        # Common fields that might be in legal documents
        common_fields = [
            ('party_a', r'party\s*a|first\s*party|disclosing\s*party'),
            ('party_b', r'party\s*b|second\s*party|receiving\s*party'),
            ('effective_date', r'effective\s*date|date\s*of\s*agreement'),
            ('company_name', r'company\s*name'),
            ('your_name', r'your\s*name|client\s*name'),
            ('address', r'address'),
            ('amount', r'amount|sum|payment'),
        ]
        
        text_lower = template_text.lower()
        for field_name, pattern in common_fields:
            if re.search(pattern, text_lower) and field_name not in placeholders:
                # Check if there's a blank or placeholder near it
                if re.search(f'{pattern}[:\s]*[_\\[{{<]', text_lower):
                    placeholders[field_name] = f"Please provide the {field_name.replace('_', ' ')}"
        
        return placeholders
    
    def extract_info_from_message(self, message: str, pending_fields: list[str], 
                                   current_field: Optional[str]) -> dict[str, str]:
        """
        Try to extract field values from user's message.
        Uses simple heuristics and patterns.
        """
        extracted = {}
        message_lower = message.lower()
        
        # If we're asking for a specific field, the whole message is likely the answer
        if current_field and len(pending_fields) == 1:
            extracted[current_field] = message.strip()
            return extracted
        
        # Try to parse structured responses like "Name: John, Company: Acme"
        # Pattern: field_name: value or field_name = value
        pairs = re.findall(r'([a-zA-Z_]+)\s*[:=]\s*([^,\n]+)', message)
        for key, value in pairs:
            key_lower = key.lower().replace(' ', '_')
            for field in pending_fields:
                if key_lower in field or field in key_lower:
                    extracted[field] = value.strip()
        
        # If current field is set and we didn't extract anything, use the message
        if current_field and current_field not in extracted:
            extracted[current_field] = message.strip()
        
        return extracted
    
    def format_field_question(self, field_name: str, remaining_count: int) -> str:
        """Generate a friendly question for a field."""
        friendly_name = field_name.replace('_', ' ').title()
        
        if remaining_count > 1:
            return f"What is the **{friendly_name}**? ({remaining_count} fields remaining)"
        else:
            return f"What is the **{friendly_name}**? (last field!)"
    
    def fill_template(self, template_text: str, values: dict[str, Any]) -> str:
        """Fill in template placeholders with collected values."""
        result = template_text
        
        for field_name, value in values.items():
            # Try various placeholder formats
            patterns = [
                f'{{{field_name}}}',
                f'{{{field_name.replace("_", " ")}}}',
                f'{{{field_name.upper()}}}',
                f'[{field_name}]',
                f'[{field_name.replace("_", " ").title()}]',
                f'[{field_name.upper()}]',
                f'<{field_name}>',
            ]
            for pattern in patterns:
                result = result.replace(pattern, str(value))
        
        return result


# Singleton instance
conversation_manager = ConversationManager()
