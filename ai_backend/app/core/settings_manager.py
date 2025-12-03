import json
import os
from pathlib import Path
from ..schemas.settings import OllamaSettings

SETTINGS_FILE = Path("settings.json")

class SettingsManager:
    @staticmethod
    def load_settings() -> OllamaSettings:
        if not SETTINGS_FILE.exists():
            return OllamaSettings()
        
        try:
            with open(SETTINGS_FILE, "r") as f:
                data = json.load(f)
            return OllamaSettings(**data)
        except Exception:
            return OllamaSettings()

    @staticmethod
    def save_settings(settings: OllamaSettings):
        with open(SETTINGS_FILE, "w") as f:
            json.dump(settings.model_dump(), f, indent=2)

settings_manager = SettingsManager()
