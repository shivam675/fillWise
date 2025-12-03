import json
from pathlib import Path
from typing import List, Optional
from datetime import datetime
from ..schemas.template_config import Template, TemplateCreate, TemplateUpdate

TEMPLATES_FILE = Path("templates.json")

class TemplateManager:
    def __init__(self):
        self._ensure_file()

    def _ensure_file(self):
        if not TEMPLATES_FILE.exists():
            with open(TEMPLATES_FILE, "w") as f:
                json.dump([], f)

    def _load_templates(self) -> List[dict]:
        try:
            with open(TEMPLATES_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, FileNotFoundError):
            return []

    def _save_templates(self, templates: List[dict]):
        with open(TEMPLATES_FILE, "w") as f:
            json.dump(templates, f, indent=2, default=str)

    def list_templates(self, search: Optional[str] = None) -> List[Template]:
        raw_data = self._load_templates()
        templates = [Template(**item) for item in raw_data]
        
        if search:
            search_lower = search.lower()
            templates = [
                t for t in templates 
                if search_lower in t.name.lower() or 
                   (t.description and search_lower in t.description.lower())
            ]
        
        # Sort by updated_at desc
        templates.sort(key=lambda x: x.updated_at, reverse=True)
        return templates

    def get_template(self, template_id: str) -> Optional[Template]:
        templates = self.list_templates()
        for t in templates:
            if t.id == template_id:
                return t
        return None

    def create_template(self, payload: TemplateCreate) -> Template:
        templates = self.list_templates()
        new_template = Template(**payload.model_dump())
        
        # Convert to dict for storage
        templates_data = [t.model_dump() for t in templates]
        templates_data.append(new_template.model_dump())
        
        self._save_templates(templates_data)
        return new_template

    def update_template(self, template_id: str, payload: TemplateUpdate) -> Optional[Template]:
        templates = self.list_templates()
        updated_template = None
        
        templates_data = []
        for t in templates:
            if t.id == template_id:
                update_data = payload.model_dump(exclude_unset=True)
                updated_t = t.model_copy(update=update_data)
                updated_t.updated_at = datetime.utcnow()
                updated_template = updated_t
                templates_data.append(updated_t.model_dump())
            else:
                templates_data.append(t.model_dump())
        
        if updated_template:
            self._save_templates(templates_data)
            
        return updated_template

    def delete_template(self, template_id: str) -> bool:
        templates = self.list_templates()
        initial_len = len(templates)
        templates = [t for t in templates if t.id != template_id]
        
        if len(templates) < initial_len:
            self._save_templates([t.model_dump() for t in templates])
            return True
        return False

template_manager = TemplateManager()
