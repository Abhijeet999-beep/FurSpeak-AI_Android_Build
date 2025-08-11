import pytest
from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_app_health():
    """Test that the app is running and accessible"""
    response = client.get("/")
    assert response.status_code == 404  # Root endpoint not defined, should return 404

def test_detect_endpoint_exists():
    """Test that the detect endpoint exists"""
    response = client.post("/detect/")
    assert response.status_code == 422  # Should return validation error for missing file

def test_app_structure():
    """Test that the app has the expected structure"""
    assert app.title == "FastAPI"
    assert hasattr(app, 'mount')
