import base64
import os
import sys
import pytest

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
from app import app


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def sample_face_b64():
    sample_path = os.path.join(os.path.dirname(__file__), "sample_face.jpg")
    with open(sample_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def test_health_check(client):
    response = client.get("/health")
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["success"] is True
    assert json_data["data"]["status"] == "UP"
    assert json_data["data"]["model_ready"] is True
    assert json_data["errorCode"] is None


def test_extract_embedding_real(client, sample_face_b64):
    response = client.post(
        "/api/v1/face/extract-embedding", json={"image_base64": sample_face_b64}
    )
    assert response.status_code == 200
    json_data = response.get_json()
    assert json_data["success"] is True
    assert "embedding" in json_data["data"]
    assert len(json_data["data"]["embedding"]) == 512
    assert json_data["data"]["face_detected"] is True
    assert json_data["errorCode"] is None


def test_check_liveness_fail_closed(client):
    response = client.post("/api/v1/face/check-liveness", json={})
    assert response.status_code == 501
    json_data = response.get_json()
    assert json_data["success"] is False
    assert json_data["data"]["is_live"] is False
    assert json_data["data"]["status"] == "UNAVAILABLE"
    assert json_data["errorCode"] == "ERR_3003"
