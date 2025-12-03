"""Template CRUD smoke tests."""
from fastapi.testclient import TestClient

from app.main import create_app

client = TestClient(create_app())


def test_create_and_list_templates() -> None:
    payload = {
        "name": "Test Template",
        "description": "Test description",
        "type": "business",
        "prompt_template": "Hello {name}",
        "variables": [{"name": "name"}],
    }
    response = client.post("/api/templates", json=payload)
    assert response.status_code == 201

    list_response = client.get("/api/templates")
    assert list_response.status_code == 200
    assert list_response.json()["total"] >= 1
