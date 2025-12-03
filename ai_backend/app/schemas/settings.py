from pydantic import BaseModel
from typing import Optional

# Models that support native tool/function calling in Ollama
TOOL_CAPABLE_MODELS = [
    "llama3.1:8b",
    "llama3.1:70b", 
    "llama3.2:1b",
    "llama3.2:3b",
    "llama3.3:70b",
    "qwen2.5:7b",
    "qwen2.5:14b",
    "qwen2.5:32b",
    "qwen2.5:72b",
    "qwen2.5-coder:7b",
    "mistral:7b",
    "mistral-nemo:12b",
    "mixtral:8x7b",
    "mixtral:8x22b",
    "command-r:35b",
    "command-r-plus:104b",
    "hermes3:8b",
    "hermes3:70b",
    "athene-v2:72b",
    "nemotron:70b",
    "granite3-dense:8b",
]

# Default model that supports tool calling (8B as requested)
DEFAULT_TOOL_MODEL = "llama3.1:8b"

class OllamaSettings(BaseModel):
    base_url: str = "http://localhost:11434"
    model_name: str = DEFAULT_TOOL_MODEL
    use_tool_calling: bool = True  # Toggle between tool calling and LLM mode
    system_prompt: str = """You are an intelligent document assistant. Your primary task is to help users create documents based on templates.

When a user asks to create a document (like NDA, contract, letter, etc.):
1. First, identify which template best matches their request
2. Ask for any required information to fill the template
3. Once you have all needed information, generate the document

Always be helpful, professional, and accurate in your responses."""
    temperature: float = 0.7
    top_p: float = 0.9
    top_k: int = 40
    num_ctx: int = 4096
    repeat_penalty: float = 1.1

class SettingsUpdate(BaseModel):
    base_url: Optional[str] = None
    model_name: Optional[str] = None
    use_tool_calling: Optional[bool] = None
    system_prompt: Optional[str] = None
    temperature: Optional[float] = None
    top_p: Optional[float] = None
    top_k: Optional[int] = None
    num_ctx: Optional[int] = None
    repeat_penalty: Optional[float] = None
