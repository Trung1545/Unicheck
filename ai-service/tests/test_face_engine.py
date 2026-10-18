"""UniCheck AI Service - Face Engine Comprehensive Unit & Integration Test Suite

Verifies all 15 test requirements specified in TASK-03:
1. No face in image (ERR_3001)
2. Multiple faces in image (ERR_3002)
3. Corrupted image bytes (ERR_1001)
4. Malformed Base64 string (ERR_1001)
5. Over-dimensioned image rejection
6. Valid face extraction (200 OK)
7. Finite and non-zero embeddings
8. Strict L2 normalization verification
9. Cosine similarity of identical / similar vectors (Matched)
10. Cosine similarity of different identities (Unmatched)
11. Dimension mismatch error handling
12. Model load failure graceful handling
13. Threshold validation boundary checks
14. API response envelope contracts
15. Liveness fail-closed enforcement
"""

import base64
import os
import sys
import cv2
import numpy as np
import pytest

# Ensure parent directory is in path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import app
from config import MODEL_NAME, MODEL_VERSION, EMBEDDING_DIMENSION
from face_detector import (
    FaceDetector,
    decode_image_base64,
    NoFaceDetectedError,
    MultipleFacesDetectedError,
    InvalidImageError,
    ImageDimensionExceededError,
)
from face_engine import FaceEngine, FaceEngineError
from face_matcher import (
    compute_cosine_similarity,
    compute_euclidean_distance,
    verify_vectors,
    FaceMatchingError,
)


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture(scope="session")
def test_images():
    """Generates and loads test images for the session."""
    tests_dir = os.path.dirname(os.path.abspath(__file__))

    # 1. Valid face image (sample_face.jpg)
    sample_face_path = os.path.join(tests_dir, "sample_face.jpg")
    with open(sample_face_path, "rb") as f:
        valid_face_b64 = base64.b64encode(f.read()).decode("utf-8")

    # 2. Second face image (second_face.jpg)
    second_face_path = os.path.join(tests_dir, "second_face.jpg")
    with open(second_face_path, "rb") as f:
        second_face_b64 = base64.b64encode(f.read()).decode("utf-8")

    # 3. Two faces image (two_faces.jpg)
    two_faces_path = os.path.join(tests_dir, "two_faces.jpg")
    with open(two_faces_path, "rb") as f:
        two_faces_b64 = base64.b64encode(f.read()).decode("utf-8")

    # 4. No face image (no_face.png)
    no_face_path = os.path.join(tests_dir, "no_face.png")
    with open(no_face_path, "rb") as f:
        no_face_b64 = base64.b64encode(f.read()).decode("utf-8")

    return {
        "valid_face_b64": valid_face_b64,
        "second_face_b64": second_face_b64,
        "two_faces_b64": two_faces_b64,
        "no_face_b64": no_face_b64,
    }


# ==============================================================================
# TEST CASE 1: Không có mặt (No face in image)
# ==============================================================================
def test_1_no_face_detected(client, test_images):
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": test_images["no_face_b64"]},
    )
    assert res.status_code == 400
    data = res.get_json()
    assert data["success"] is False
    assert data["errorCode"] == "ERR_3001"
    assert data["data"]["face_detected"] is False
    assert "Không phát hiện khuôn mặt" in data["message"]


# ==============================================================================
# TEST CASE 2: Có nhiều mặt (Multiple faces in image)
# ==============================================================================
def test_2_multiple_faces_detected(client, test_images):
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": test_images["two_faces_b64"]},
    )
    assert res.status_code == 400
    data = res.get_json()
    assert data["success"] is False
    assert data["errorCode"] == "ERR_3002"
    assert data["data"]["face_detected"] is False
    assert data["data"]["face_count"] >= 2
    assert "nhiều hơn một khuôn mặt" in data["message"]


# ==============================================================================
# TEST CASE 3: Ảnh hỏng (Corrupted image bytes)
# ==============================================================================
def test_3_corrupted_image(client):
    corrupted_bytes = b"ThisIsNotAValidJpegHeaderDataOrPixelStream1234567890"
    corrupted_b64 = base64.b64encode(corrupted_bytes).decode("utf-8")
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": corrupted_b64},
    )
    assert res.status_code == 400
    data = res.get_json()
    assert data["success"] is False
    assert data["errorCode"] == "ERR_1001"
    assert "không thể đọc" in data["message"].lower() or "không hợp lệ" in data["message"].lower()


# ==============================================================================
# TEST CASE 4: Base64 lỗi (Malformed Base64 string)
# ==============================================================================
def test_4_malformed_base64(client):
    malformed_b64 = "%%%Not_Valid_Base64_String$$$!!!"
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": malformed_b64},
    )
    assert res.status_code == 400
    data = res.get_json()
    assert data["success"] is False
    assert data["errorCode"] == "ERR_1001"
    assert "base64" in data["message"].lower()


# ==============================================================================
# TEST CASE 5: Ảnh quá lớn (Exceeding max dimension)
# ==============================================================================
def test_5_image_dimension_exceeded():
    with pytest.raises(ImageDimensionExceededError):
        # Create an oversized image 5000x100
        oversized = np.zeros((100, 5000, 3), dtype=np.uint8)
        _, buf = cv2.imencode(".jpg", oversized)
        b64 = base64.b64encode(buf.tobytes()).decode("utf-8")
        decode_image_base64(b64)


# ==============================================================================
# TEST CASE 6: Ảnh hợp lệ (Valid Face Detection & Extraction)
# ==============================================================================
def test_6_valid_face_extraction(client, test_images):
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": test_images["valid_face_b64"]},
    )
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["errorCode"] is None
    assert data["data"]["face_detected"] is True
    assert data["data"]["embedding_dimension"] == 512
    assert len(data["data"]["embedding"]) == 512
    assert data["data"]["model_name"] == MODEL_NAME
    assert data["data"]["model_version"] == MODEL_VERSION
    assert "bounding_box" in data["data"]
    assert data["data"]["bounding_box"]["width"] > 0
    assert data["data"]["bounding_box"]["height"] > 0


# ==============================================================================
# TEST CASE 7: Embedding hữu hạn và khác zero
# ==============================================================================
def test_7_embedding_finite_and_nonzero(client, test_images):
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": test_images["valid_face_b64"]},
    )
    data = res.get_json()
    emb = np.array(data["data"]["embedding"], dtype=np.float32)

    assert np.all(np.isfinite(emb)), "Embedding contains NaN or Inf"
    norm = np.linalg.norm(emb)
    assert norm > 1e-6, "Embedding is a zero vector"
    # Verify that not all elements are 0.0 (not mock [0.0]*128)
    assert not np.allclose(emb, 0.0), "Embedding must not be an all-zero vector"


# ==============================================================================
# TEST CASE 8: L2 Normalization (Norm == 1.0)
# ==============================================================================
def test_8_l2_normalization(client, test_images):
    res = client.post(
        "/api/v1/face/extract-embedding",
        json={"image_base64": test_images["valid_face_b64"]},
    )
    data = res.get_json()
    emb = np.array(data["data"]["embedding"], dtype=np.float32)
    l2_norm = float(np.linalg.norm(emb))
    assert abs(l2_norm - 1.0) < 1e-4, f"L2 norm {l2_norm} differs from 1.0"


# ==============================================================================
# TEST CASE 9: Cosine similarity của vector tương đồng (Same Identity Match)
# ==============================================================================
def test_9_cosine_similarity_same_identity(client, test_images):
    # Verify using verify-face endpoint with two images of the same person
    res = client.post(
        "/api/v1/face/verify-face",
        json={
            "source_image_base64": test_images["valid_face_b64"],
            "target_image_base64": test_images["valid_face_b64"],
            "threshold": 0.68,
        },
    )
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["errorCode"] is None
    assert data["data"]["matched"] is True
    assert data["data"]["similarity_score"] >= 0.99
    assert data["data"]["metric"] == "cosine"


# ==============================================================================
# TEST CASE 10: Cosine similarity của vector khác nhau (Different Identities)
# ==============================================================================
def test_10_cosine_similarity_different_identities(client, test_images):
    res = client.post(
        "/api/v1/face/verify-face",
        json={
            "source_image_base64": test_images["valid_face_b64"],
            "target_image_base64": test_images["second_face_b64"],
            "threshold": 0.68,
        },
    )
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is False
    assert data["errorCode"] == "ERR_3004"
    assert data["data"]["matched"] is False
    assert data["data"]["similarity_score"] < 0.68


# ==============================================================================
# TEST CASE 11: Dimension mismatch (Khác kích thước vector)
# ==============================================================================
def test_11_dimension_mismatch():
    vec_512 = [0.1] * 512
    vec_128 = [0.1] * 128
    with pytest.raises(FaceMatchingError) as exc_info:
        compute_cosine_similarity(vec_512, vec_128)
    assert "Kích thước vector không khớp" in str(exc_info.value)

    with pytest.raises(FaceMatchingError):
        compute_euclidean_distance(vec_512, vec_128)


# ==============================================================================
# TEST CASE 12: Model load failure handling
# ==============================================================================
def test_12_model_load_failure():
    # Pass non-existent path
    engine_dummy = FaceEngine(model_path="/non/existent/path/to/model.onnx")
    assert engine_dummy.is_ready is False

    detector_dummy = FaceDetector(model_path="/non/existent/path/to/yunet.onnx")
    # Haar fallback should kick in if available, or detector handles missing gracefully
    assert detector_dummy is not None


# ==============================================================================
# TEST CASE 13: Threshold validation (Boundary checks)
# ==============================================================================
def test_13_threshold_validation():
    v1 = np.ones(512, dtype=np.float32) / np.sqrt(512)
    v2 = np.ones(512, dtype=np.float32) / np.sqrt(512)

    # Valid thresholds
    res_default = verify_vectors(v1, v2)
    assert res_default["threshold"] == 0.68

    res_custom = verify_vectors(v1, v2, threshold=0.75)
    assert res_custom["threshold"] == 0.75

    # Out-of-bounds thresholds
    with pytest.raises(FaceMatchingError) as exc_info:
        verify_vectors(v1, v2, threshold=1.5)
    assert "khoảng [-1.0, 1.0]" in str(exc_info.value)

    with pytest.raises(FaceMatchingError):
        verify_vectors(v1, v2, threshold=-2.0)

    with pytest.raises(FaceMatchingError):
        verify_vectors(v1, v2, threshold="not-a-number")


# ==============================================================================
# TEST CASE 14: API Contract (Envelope and Health Check)
# ==============================================================================
def test_14_api_contracts(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = res.get_json()
    assert data["success"] is True
    assert data["data"]["status"] == "UP"
    assert data["data"]["model_ready"] is True
    assert data["data"]["detector_ready"] is True
    assert data["data"]["model_name"] == MODEL_NAME
    assert data["data"]["embedding_dimension"] == 512
    assert data["errorCode"] is None


# ==============================================================================
# TEST CASE 15: Liveness fail-closed khi model chưa sẵn sàng (Anti-spoofing)
# ==============================================================================
def test_15_liveness_fail_closed(client):
    res = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": "dummy", "challenge": "blink"},
    )
    assert res.status_code == 501
    data = res.get_json()
    assert data["success"] is False
    assert data["errorCode"] == "ERR_3003"
    assert data["data"]["is_live"] is False
    assert data["data"]["status"] == "UNAVAILABLE"
    assert data["data"]["fail_closed"] is True
