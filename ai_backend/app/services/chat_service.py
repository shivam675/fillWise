"""AI chat service with tool calling and LLM-driven document workflow."""
from __future__ import annotations

import json
import re
import urllib.request
from dataclasses import dataclass, field
from typing import Any, Optional, List, Dict

from ..core.settings_manager import settings_manager
from ..core.template_manager import template_manager
from ..core.document_manager import document_manager


@dataclass
class ChatResponse:
    """Response from chat service."""
    reply: str
    template_id: Optional[str] = None
    state: str = "idle"
    pending_fields: List[str] = field(default_factory=list)
    collected_values: Dict[str, Any] = field(default_factory=dict)
    generated_document: Optional[str] = None
    document_title: Optional[str] = None
    document_saved: bool = False
    saved_document_id: Optional[str] = None


# Tool definitions for Ollama tool calling
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "list_templates",
            "description": "List all available document templates. Call this to see what templates are available before selecting one.",
            "parameters": {
                "type": "object",
                "properties": {},
                "required": []
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "select_template",
            "description": "Select a template to use for document creation. Call this when you've identified which template the user needs.",
            "parameters": {
                "type": "object",
                "properties": {
                    "template_id": {
                        "type": "string",
                        "description": "The ID of the template to use"
                    },
                    "reason": {
                        "type": "string",
                        "description": "Brief explanation of why this template was selected"
                    }
                },
                "required": ["template_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_template_fields",
            "description": "Get the required fields/placeholders for a specific template. Call this after selecting a template to know what information to collect.",
            "parameters": {
                "type": "object",
                "properties": {
                    "template_id": {
                        "type": "string",
                        "description": "The ID of the template"
                    }
                },
                "required": ["template_id"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "generate_document",
            "description": "Generate and save the final document with all collected values. Call this ONLY when you have ALL required information from the user.",
            "parameters": {
                "type": "object",
                "properties": {
                    "template_id": {
                        "type": "string",
                        "description": "The ID of the template to use"
                    },
                    "title": {
                        "type": "string",
                        "description": "Title for the generated document"
                    },
                    "values": {
                        "type": "object",
                        "description": "Key-value pairs of field names and their values collected from the user"
                    }
                },
                "required": ["template_id", "title", "values"]
            }
        }
    }
]


class ConversationSession:
    """Tracks conversation state."""
    def __init__(self, session_id: str):
        self.id = session_id
        self.messages: List[Dict[str, Any]] = []
        self.selected_template_id: Optional[str] = None
        self.collected_values: Dict[str, Any] = {}
        self.generated_document: Optional[str] = None
        self.document_title: Optional[str] = None


class ChatService:
    """Generates AI responses using Ollama with tool calling support."""
    
    _sessions: Dict[str, ConversationSession] = {}
    
    def get_or_create_session(self, session_id: str) -> ConversationSession:
        if session_id not in self._sessions:
            self._sessions[session_id] = ConversationSession(session_id)
        return self._sessions[session_id]
    
    def reset_session(self, session_id: str) -> ConversationSession:
        self._sessions[session_id] = ConversationSession(session_id)
        return self._sessions[session_id]

    def process_message(self, *, session_id: str, message: str, 
                        template_id: Optional[str] = None) -> ChatResponse:
        """Process a user message - routes to tool calling or LLM mode based on settings."""
        settings = settings_manager.load_settings()
        
        # Check for reset commands
        if message.lower().strip() in ['reset', 'start over', 'cancel', 'new', 'clear']:
            self.reset_session(session_id)
            return ChatResponse(
                reply="🔄 Conversation reset. How can I help you create a document today?",
                state="idle"
            )
        
        if settings.use_tool_calling:
            return self._process_with_tools(session_id, message, settings)
        else:
            return self._process_with_llm(session_id, message, settings)

    def _process_with_tools(self, session_id: str, message: str, settings) -> ChatResponse:
        """Process message using Ollama's native tool calling."""
        session = self.get_or_create_session(session_id)
        
        # Add user message to history
        session.messages.append({"role": "user", "content": message})
        
        # Build system message with context
        templates = template_manager.list_templates()
        template_info = "\n".join([
            f"- {t.name} (ID: {t.id}): {t.description or 'No description'}" 
            for t in templates if t.is_active
        ])
        
        system_message = f"""{settings.system_prompt}

AVAILABLE TEMPLATES:
{template_info}

INSTRUCTIONS:
1. When user wants to create a document, first call list_templates or directly select_template if you know which one fits
2. After selecting, call get_template_fields to see what information is needed
3. Ask the user for ALL required information through conversation
4. Only call generate_document when you have collected ALL required values from the user
5. Be conversational and helpful - confirm information and ask clarifying questions

IMPORTANT: Do not make up information. Always ask the user for required values."""

        # Prepare messages for Ollama
        ollama_messages = [{"role": "system", "content": system_message}]
        ollama_messages.extend(session.messages)
        
        # Call Ollama with tools
        response = self._call_ollama_chat(ollama_messages, settings, tools=TOOLS)
        
        if "error" in response:
            return ChatResponse(reply=f"Error: {response['error']}", state="error")
        
        assistant_message = response.get("message", {})
        reply_content = assistant_message.get("content", "")
        tool_calls = assistant_message.get("tool_calls", [])
        
        # Process tool calls if any
        if tool_calls:
            tool_results = []
            final_response = None
            
            for tool_call in tool_calls:
                func_name = tool_call.get("function", {}).get("name", "")
                func_args = tool_call.get("function", {}).get("arguments", {})
                
                # Handle arguments that might be a string
                if isinstance(func_args, str):
                    try:
                        func_args = json.loads(func_args)
                    except json.JSONDecodeError:
                        func_args = {}
                
                result = self._execute_tool(func_name, func_args, session)
                tool_results.append({"tool": func_name, "result": result})
                
                # Check if document was generated
                if func_name == "generate_document" and result.get("success"):
                    final_response = ChatResponse(
                        reply=f"✅ **Document Created!**\n\n{result.get('message', '')}\n\nYour document has been saved to the Documents section.",
                        template_id=func_args.get("template_id"),
                        state="document_saved",
                        collected_values=func_args.get("values", {}),
                        generated_document=result.get("content"),
                        document_title=func_args.get("title"),
                        document_saved=True,
                        saved_document_id=result.get("document_id")
                    )
            
            if final_response:
                session.messages.append({"role": "assistant", "content": final_response.reply})
                return final_response
            
            # Add tool results to context and get follow-up response
            tool_result_text = "\n".join([
                f"Tool '{r['tool']}' returned: {json.dumps(r['result'])}" 
                for r in tool_results
            ])
            
            session.messages.append({
                "role": "assistant", 
                "content": reply_content,
                "tool_calls": tool_calls
            })
            session.messages.append({
                "role": "tool",
                "content": tool_result_text
            })
            
            # Get follow-up response after tool execution
            follow_up = self._call_ollama_chat(
                [{"role": "system", "content": system_message}] + session.messages,
                settings,
                tools=TOOLS
            )
            
            if "error" not in follow_up:
                follow_up_content = follow_up.get("message", {}).get("content", "")
                if follow_up_content:
                    reply_content = follow_up_content
                    session.messages.append({"role": "assistant", "content": reply_content})
        else:
            # No tool calls - just a regular response
            session.messages.append({"role": "assistant", "content": reply_content})
        
        return ChatResponse(
            reply=reply_content or "I'm here to help you create documents. What would you like to create?",
            template_id=session.selected_template_id,
            state="conversing",
            collected_values=session.collected_values
        )

    def _process_with_llm(self, session_id: str, message: str, settings) -> ChatResponse:
        """Process message using structured LLM prompts (no native tool calling)."""
        session = self.get_or_create_session(session_id)
        
        # Add user message to history
        session.messages.append({"role": "user", "content": message})
        
        # Build context
        templates = template_manager.list_templates()
        template_info = "\n".join([
            f"- {t.name} (ID: {t.id}): {t.description or 'No description'}" 
            for t in templates if t.is_active
        ])
        
        # Build conversation history
        history = "\n".join([
            f"{'User' if m['role'] == 'user' else 'Assistant'}: {m['content']}" 
            for m in session.messages[-10:]
        ])
        
        prompt = f"""{settings.system_prompt}

AVAILABLE TEMPLATES:
{template_info}

CONVERSATION HISTORY:
{history}

INSTRUCTIONS:
You are helping the user create a document. Based on the conversation:
1. If user wants to create a document, identify the best matching template
2. Ask for required information conversationally
3. When you have ALL required information, output a JSON block to generate the document

To generate a document, include this JSON block in your response:
```json
{{"action": "generate_document", "template_id": "...", "title": "...", "values": {{"field1": "value1", ...}}}}
```

Current user message: {message}

Respond naturally. If you need more information, ask for it. Only include the JSON block when you have everything needed."""

        response = self._call_ollama_generate(prompt, settings)
        
        if response.startswith("Error"):
            return ChatResponse(reply=response, state="error")
        
        # Check if response contains a generate action
        if '```json' in response and '"action": "generate_document"' in response:
            try:
                # Extract JSON block
                json_start = response.find('```json') + 7
                json_end = response.find('```', json_start)
                json_str = response[json_start:json_end].strip()
                action_data = json.loads(json_str)
                
                if action_data.get("action") == "generate_document":
                    result = self._execute_tool(
                        "generate_document",
                        {
                            "template_id": action_data.get("template_id"),
                            "title": action_data.get("title"),
                            "values": action_data.get("values", {})
                        },
                        session
                    )
                    
                    if result.get("success"):
                        # Remove JSON block from reply and add success message
                        clean_reply = response[:response.find('```json')].strip()
                        final_reply = f"{clean_reply}\n\n✅ **Document Created!**\n\n{result.get('message', '')}\n\nYour document has been saved to the Documents section."
                        
                        session.messages.append({"role": "assistant", "content": final_reply})
                        
                        return ChatResponse(
                            reply=final_reply,
                            template_id=action_data.get("template_id"),
                            state="document_saved",
                            collected_values=action_data.get("values", {}),
                            generated_document=result.get("content"),
                            document_title=action_data.get("title"),
                            document_saved=True,
                            saved_document_id=result.get("document_id")
                        )
            except (json.JSONDecodeError, KeyError, ValueError):
                pass  # If JSON parsing fails, return the response as-is
        
        session.messages.append({"role": "assistant", "content": response})
        
        return ChatResponse(
            reply=response,
            template_id=session.selected_template_id,
            state="conversing",
            collected_values=session.collected_values
        )

    def _execute_tool(self, tool_name: str, args: Dict[str, Any], 
                      session: ConversationSession) -> Dict[str, Any]:
        """Execute a tool and return results."""
        
        if tool_name == "list_templates":
            templates = template_manager.list_templates()
            return {
                "templates": [
                    {"id": t.id, "name": t.name, "description": t.description}
                    for t in templates if t.is_active
                ]
            }
        
        elif tool_name == "select_template":
            template_id = args.get("template_id")
            template = template_manager.get_template(template_id)
            if template:
                session.selected_template_id = template_id
                return {
                    "success": True,
                    "template": {
                        "id": template.id,
                        "name": template.name,
                        "description": template.description
                    }
                }
            return {"success": False, "error": "Template not found"}
        
        elif tool_name == "get_template_fields":
            template_id = args.get("template_id")
            template = template_manager.get_template(template_id)
            if template:
                # Extract template content and find fields
                content = self._extract_template_text(template.content)
                fields = self._extract_placeholders(content)
                return {
                    "template_id": template_id,
                    "template_name": template.name,
                    "fields": list(fields.keys()),
                    "field_descriptions": fields,
                    "template_preview": content[:500] + "..." if len(content) > 500 else content
                }
            return {"error": "Template not found"}
        
        elif tool_name == "generate_document":
            template_id = args.get("template_id")
            title = args.get("title", "Untitled Document")
            values = args.get("values", {})
            
            template = template_manager.get_template(template_id)
            if not template:
                return {"success": False, "error": "Template not found"}
            
            # Get template content and fill it
            content = self._extract_template_text(template.content)
            filled_content = self._fill_template(content, values)
            
            # Save to documents
            doc = document_manager.create_document(
                title=title,
                content=filled_content,
                template_id=template_id,
                template_name=template.name,
                filled_values=values
            )
            
            session.generated_document = filled_content
            session.document_title = title
            session.collected_values = values
            
            return {
                "success": True,
                "document_id": doc.id,
                "title": title,
                "content": filled_content,
                "message": f"Document '{title}' has been created using the '{template.name}' template."
            }
        
        return {"error": f"Unknown tool: {tool_name}"}

    def _call_ollama_chat(self, messages: List[Dict], settings, 
                          tools: Optional[List] = None) -> Dict[str, Any]:
        """Call Ollama chat API with optional tools."""
        payload = {
            "model": settings.model_name,
            "messages": messages,
            "stream": False,
            "options": {
                "temperature": settings.temperature,
                "top_p": settings.top_p,
                "top_k": settings.top_k,
                "num_ctx": settings.num_ctx,
                "repeat_penalty": settings.repeat_penalty,
            }
        }
        
        if tools:
            payload["tools"] = tools
        
        try:
            url = f"{settings.base_url.rstrip('/')}/api/chat"
            data = json.dumps(payload).encode('utf-8')
            req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
            
            with urllib.request.urlopen(req, timeout=180) as response:
                if response.status == 200:
                    return json.loads(response.read().decode())
                else:
                    return {"error": f"Ollama returned status {response.status}"}
        except Exception as e:
            return {"error": f"Connection error: {str(e)}"}

    def _call_ollama_generate(self, prompt: str, settings) -> str:
        """Call Ollama generate API."""
        payload = {
            "model": settings.model_name,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": settings.temperature,
                "top_p": settings.top_p,
                "top_k": settings.top_k,
                "num_ctx": settings.num_ctx,
                "repeat_penalty": settings.repeat_penalty,
            }
        }
        
        try:
            url = f"{settings.base_url.rstrip('/')}/api/generate"
            data = json.dumps(payload).encode('utf-8')
            req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})
            
            with urllib.request.urlopen(req, timeout=180) as response:
                if response.status == 200:
                    res_data = json.loads(response.read().decode())
                    return res_data.get("response", "")
                else:
                    return f"Error: Ollama returned status {response.status}"
        except Exception as e:
            return f"Error connecting to Ollama: {str(e)}"

    def _extract_template_text(self, content: str) -> str:
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

    def _extract_placeholders(self, template_text: str) -> Dict[str, str]:
        """Extract placeholders from template text."""
        placeholders = {}
        
        # Pattern: {field_name} or {{field_name}}
        curly_matches = re.findall(r'\{+([a-zA-Z_][a-zA-Z0-9_ ]*)\}+', template_text)
        for match in curly_matches:
            field_name = match.strip().replace(' ', '_').lower()
            placeholders[field_name] = f"Value for {match}"
        
        # Pattern: [FIELD NAME]
        bracket_matches = re.findall(r'\[([A-Za-z][A-Za-z0-9 _]+)\]', template_text)
        for match in bracket_matches:
            field_name = match.strip().replace(' ', '_').lower()
            placeholders[field_name] = f"Value for {match}"
        
        # Pattern: <field_name>
        angle_matches = re.findall(r'<([a-zA-Z_][a-zA-Z0-9_]*)>', template_text)
        for match in angle_matches:
            field_name = match.strip().lower()
            placeholders[field_name] = f"Value for {match}"
        
        return placeholders

    def _fill_template(self, template_text: str, values: Dict[str, Any]) -> str:
        """Fill template placeholders with values."""
        result = template_text
        
        for field_name, value in values.items():
            patterns = [
                f'{{{field_name}}}',
                f'{{{field_name.replace("_", " ")}}}',
                f'{{{field_name.upper()}}}',
                f'{{{field_name.title()}}}',
                f'[{field_name}]',
                f'[{field_name.replace("_", " ").title()}]',
                f'[{field_name.upper()}]',
                f'<{field_name}>',
            ]
            for pattern in patterns:
                result = result.replace(pattern, str(value))
        
        return result


# Singleton instance
chat_service = ChatService()

