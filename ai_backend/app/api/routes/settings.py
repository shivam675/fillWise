from fastapi import APIRouter, HTTPException
from ...schemas.settings import OllamaSettings, SettingsUpdate, TOOL_CAPABLE_MODELS
from ...core.settings_manager import settings_manager
import urllib.request
import json

router = APIRouter()

@router.get("/", response_model=OllamaSettings)
def get_settings():
    return settings_manager.load_settings()

@router.post("/", response_model=OllamaSettings)
def update_settings(update: SettingsUpdate):
    current = settings_manager.load_settings()
    update_data = update.model_dump(exclude_unset=True)
    updated = current.model_copy(update=update_data)
    settings_manager.save_settings(updated)
    return updated

@router.get("/tool-capable-models")
def get_tool_capable_models():
    """Return list of models known to support native tool calling."""
    return {"models": TOOL_CAPABLE_MODELS}

@router.post("/test-connection")
def test_connection(settings: OllamaSettings):
    try:
        # First check if Ollama is reachable by fetching tags
        url = f"{settings.base_url.rstrip('/')}/api/tags"
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=5) as response:
            if response.status == 200:
                data = json.loads(response.read().decode())
                models = data.get("models", [])
                model_names = [m.get("name", "") for m in models]
                
                # Check if the specified model exists
                model_found = any(settings.model_name in name for name in model_names)
                
                # Check if model supports tool calling
                supports_tools = any(
                    tc_model in settings.model_name or settings.model_name in tc_model
                    for tc_model in TOOL_CAPABLE_MODELS
                )
                
                # Also try to generate a simple test response with the model
                test_result = None
                if model_found:
                    try:
                        gen_url = f"{settings.base_url.rstrip('/')}/api/generate"
                        payload = {
                            "model": settings.model_name,
                            "prompt": "Say 'OK' if you are working.",
                            "stream": False,
                            "options": {
                                "num_predict": 10
                            }
                        }
                        gen_req = urllib.request.Request(
                            gen_url, 
                            data=json.dumps(payload).encode('utf-8'),
                            headers={'Content-Type': 'application/json'}
                        )
                        with urllib.request.urlopen(gen_req, timeout=30) as gen_response:
                            if gen_response.status == 200:
                                test_result = "Model responded successfully"
                    except Exception as e:
                        test_result = f"Model test failed: {str(e)}"
                
                return {
                    "status": "ok", 
                    "models": models,
                    "model_found": model_found,
                    "model_test": test_result,
                    "supports_tools": supports_tools
                }
            else:
                raise HTTPException(status_code=400, detail=f"Ollama returned status {response.status}")
    except urllib.error.URLError as e:
        raise HTTPException(status_code=400, detail=f"Connection failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Connection failed: {str(e)}")
