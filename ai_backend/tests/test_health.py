"""Basic health endpoint test."""
from fastapi.testclient import TestClient

from app.main import create_app


client = TestClient(create_app())


def test_health_ok() -> None:
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
