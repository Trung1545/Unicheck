"""UniCheck AI Service - Liveness & Anti-Spoofing Test Suite

Comprehensive unit, contract, integration, and real-model tests for:
- MiniFASNet ONNX Engine (V2, V1SE, and Ensemble)
- Scale-aware face cropping and image boundary clamping
- Real bona fide human faces vs. presentation attack samples (Print, Screen Replay)
- Edge cases: No face, Multiple faces, Corrupt Base64, Large payloads
- Thresholding behavior, Fail-Closed error handling, and Non-hardcoded verification
"""

import base64
import os
import sys
import time
import cv2
import numpy as np
import pytest

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
import config
from app import app
import app as flask_app
from face_detector import (
    FaceDetector,
    NoFaceDetectedError,
    MultipleFacesDetectedError,
    InvalidImageError,
    decode_image_base64,
)
from liveness_engine import (
    LivenessEngine,
    LivenessEngineError,
    LivenessModelNotReadyError,
    get_scaled_bounding_box,
    crop_face_for_liveness,
    softmax_logits,
)


@pytest.fixture
def client():
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def sample_face_b64():
    p = os.path.join(os.path.dirname(__file__), "sample_face.jpg")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@pytest.fixture
def second_face_b64():
    p = os.path.join(os.path.dirname(__file__), "second_face.jpg")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@pytest.fixture
def real_t1_b64():
    p = os.path.join(os.path.dirname(__file__), "image_T1.jpg")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@pytest.fixture
def spoof_f1_b64():
    p = os.path.join(os.path.dirname(__file__), "image_F1.jpg")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@pytest.fixture
def spoof_f2_b64():
    p = os.path.join(os.path.dirname(__file__), "image_F2.jpg")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@pytest.fixture
def two_faces_b64():
    p = os.path.join(os.path.dirname(__file__), "two_faces.jpg")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


@pytest.fixture
def no_face_b64():
    p = os.path.join(os.path.dirname(__file__), "no_face.png")
    with open(p, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


# ============================================================================
# 1. MATHEMATICAL PREPROCESSING & CROP TESTS
# ============================================================================

def test_scaled_bounding_box_within_bounds():
    """Verify that scale-aware bounding box expansions are properly clamped within image edges."""
    src_w, src_h = 640, 480
    bbox = [200, 150, 100, 120]  # x, y, w, h
    scale = 2.7
    x1, y1, x2, y2 = get_scaled_bounding_box(src_w, src_h, bbox, scale)

    assert 0 <= x1 < x2 <= src_w - 1
    assert 0 <= y1 < y2 <= src_h - 1
    # Check that expansion occurred
    assert (x2 - x1) > bbox[2]
    assert (y2 - y1) > bbox[3]


def test_scaled_bounding_box_corner_clamping():
    """Verify that a bounding box touching image edges does not exceed image boundaries."""
    src_w, src_h = 300, 300
    bbox = [10, 10, 100, 100]
    scale = 4.0
    x1, y1, x2, y2 = get_scaled_bounding_box(src_w, src_h, bbox, scale)

    assert x1 >= 0
    assert y1 >= 0
    assert x2 <= src_w - 1
    assert y2 <= src_h - 1


def test_crop_face_for_liveness():
    """Verify face cropping produces expected 80x80 BGR image."""
    img = np.zeros((480, 640, 3), dtype=np.uint8)
    img[100:250, 200:350] = 200  # synthetic face rectangle
    bbox = [200, 100, 150, 150]

    crop = crop_face_for_liveness(img, bbox, scale=2.7, out_w=80, out_h=80)
    assert crop.shape == (80, 80, 3)
    assert crop.dtype == np.uint8


def test_softmax_logits():
    """Verify softmax converts arbitrary logits into valid probability distribution summing to 1.0."""
    logits = np.array([[2.0, 5.0, 1.0], [-1.0, 0.0, 1.0]], dtype=np.float32)
    probs = softmax_logits(logits)

    assert probs.shape == (2, 3)
    assert np.all(probs >= 0.0)
    assert np.all(probs <= 1.0)
    assert np.allclose(np.sum(probs, axis=1), [1.0, 1.0], atol=1e-5)


# ============================================================================
# 2. REAL MODEL INFERENCE & CLASSIFICATION TESTS
# ============================================================================

def test_liveness_engine_bona_fide_samples(real_t1_b64, sample_face_b64, second_face_b64):
    """Verify that authentic human faces yield high liveness scores (>=0.70)."""
    engine = flask_app.liveness_engine
    detector = flask_app.detector
    assert engine.is_ready is True

    for b64 in [real_t1_b64, sample_face_b64, second_face_b64]:
        img = decode_image_base64(b64)
        face_info = detector.detect_single_face(img)
        result = engine.predict_liveness(img, face_info)

        assert result["is_live"] is True
        assert result["liveness_score"] >= 0.70
        assert result["probabilities"]["real"] >= 0.70
        assert result["attack_type_detected"] is None


def test_liveness_engine_spoof_presentation_attacks(spoof_f1_b64, spoof_f2_b64):
    """Verify that presentation attacks (photo print, screen replay) are correctly rejected."""
    engine = flask_app.liveness_engine
    detector = flask_app.detector

    # Sample F1: 2D Photo print / cutout attack
    img_f1 = decode_image_base64(spoof_f1_b64)
    face_f1 = detector.detect_single_face(img_f1)
    res_f1 = engine.predict_liveness(img_f1, face_f1)

    assert res_f1["is_live"] is False
    assert res_f1["liveness_score"] < 0.70
    assert res_f1["attack_type_detected"] in ("PRINT_PAPER_OR_CUTOUT", "SCREEN_OR_VIDEO_REPLAY")

    # Sample F2: Replay on screen / video display
    img_f2 = decode_image_base64(spoof_f2_b64)
    face_f2 = detector.detect_single_face(img_f2)
    res_f2 = engine.predict_liveness(img_f2, face_f2)

    assert res_f2["is_live"] is False
    assert res_f2["liveness_score"] < 0.50
    assert res_f2["probabilities"]["screen_replay"] > 0.50
    assert res_f2["attack_type_detected"] == "SCREEN_OR_VIDEO_REPLAY"


def test_liveness_engine_modes():
    """Verify that the engine supports individual modes (v2 only, v1se only, ensemble)."""
    engine_v2 = LivenessEngine(mode="v2")
    assert engine_v2.is_ready is True

    engine_v1se = LivenessEngine(mode="v1se")
    assert engine_v1se.is_ready is True

    engine_ens = LivenessEngine(mode="ensemble")
    assert engine_ens.is_ready is True


# ============================================================================
# 3. THRESHOLDING & NO HARDCODING VERIFICATION
# ============================================================================

def test_dynamic_threshold_decision(sample_face_b64):
    """Verify that threshold parameter dynamically controls the liveness decision."""
    engine = flask_app.liveness_engine
    detector = flask_app.detector
    img = decode_image_base64(sample_face_b64)
    face_info = detector.detect_single_face(img)

    # Standard threshold 0.70 -> should be live
    res_normal = engine.predict_liveness(img, face_info, threshold=0.70)
    assert res_normal["is_live"] is True

    # Ultra-strict threshold (0.9999) -> if score is 0.9948, it should fail
    res_strict = engine.predict_liveness(img, face_info, threshold=0.99999)
    assert res_strict["is_live"] is False
    assert res_strict["threshold"] == 0.99999


def test_no_hardcoded_liveness_score(real_t1_b64, spoof_f2_b64):
    """Strictly verify that scores are model-computed floating point values and not hardcoded."""
    engine = flask_app.liveness_engine
    detector = flask_app.detector

    img_real = decode_image_base64(real_t1_b64)
    face_real = detector.detect_single_face(img_real)
    score_real = engine.predict_liveness(img_real, face_real)["liveness_score"]

    img_spoof = decode_image_base64(spoof_f2_b64)
    face_spoof = detector.detect_single_face(img_spoof)
    score_spoof = engine.predict_liveness(img_spoof, face_spoof)["liveness_score"]

    # Scores must significantly differ and not be fixed dummy constants
    assert score_real != score_spoof
    assert score_real > 0.95
    assert score_spoof < 0.10


# ============================================================================
# 4. API CONTRACT & HTTP ERROR RESPONSES
# ============================================================================

def test_api_check_liveness_success_contract(client, real_t1_b64):
    """Verify POST /api/v1/face/check-liveness returns standard UniCheck envelope."""
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": real_t1_b64, "threshold": 0.75},
    )
    assert response.status_code == 200
    json_data = response.get_json()

    assert json_data["success"] is True
    assert json_data["errorCode"] is None
    data = json_data["data"]
    assert data["is_live"] is True
    assert isinstance(data["liveness_score"], float)
    assert data["threshold"] == 0.75
    assert data["model_name"] == "MiniFASNet-Ensemble"
    assert data["model_version"] == "v2_v1se_onnx"
    assert data["face_detected"] is True
    assert "bounding_box" in data
    assert "probabilities" in data


def test_api_check_liveness_spoof_detection(client, spoof_f2_b64):
    """Verify POST /api/v1/face/check-liveness correctly identifies spoof presentation."""
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": spoof_f2_b64},
    )
    assert response.status_code == 200
    json_data = response.get_json()

    assert json_data["success"] is True
    assert json_data["data"]["is_live"] is False
    assert json_data["data"]["liveness_score"] < 0.50
    assert json_data["data"]["attack_type_detected"] == "SCREEN_OR_VIDEO_REPLAY"
    assert "Phát hiện dấu hiệu giả mạo" in json_data["message"]


def test_api_check_liveness_no_face_rejection(client, no_face_b64):
    """Verify image with no face returns 400 with ERR_3001."""
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": no_face_b64},
    )
    assert response.status_code == 400
    json_data = response.get_json()

    assert json_data["success"] is False
    assert json_data["data"]["face_detected"] is False
    assert json_data["data"]["is_live"] is False
    assert json_data["errorCode"] == "ERR_3001"


def test_api_check_liveness_multiple_faces_rejection(client, two_faces_b64):
    """Verify image with multiple faces returns 400 with ERR_3002."""
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": two_faces_b64},
    )
    assert response.status_code == 400
    json_data = response.get_json()

    assert json_data["success"] is False
    assert json_data["data"]["face_detected"] is False
    assert json_data["data"]["is_live"] is False
    assert json_data["data"]["face_count"] >= 2
    assert json_data["errorCode"] == "ERR_3002"


def test_api_check_liveness_invalid_base64(client):
    """Verify invalid base64 string returns 400 with ERR_1001."""
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": "Not_Valid_Base64_String!!!"},
    )
    assert response.status_code == 400
    json_data = response.get_json()

    assert json_data["success"] is False
    assert json_data["errorCode"] == "ERR_1001"


def test_api_check_liveness_payload_too_large(client):
    """Verify payload exceeding size limit returns 413 with ERR_1001."""
    huge_payload = "A" * (config.MAX_PAYLOAD_BYTES + 1024)
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": huge_payload},
    )
    assert response.status_code == 413
    json_data = response.get_json()

    assert json_data["success"] is False
    assert json_data["errorCode"] == "ERR_1001"


def test_api_check_liveness_fail_closed_on_unready_engine(client, real_t1_b64, monkeypatch):
    """Verify fail-closed behavior (HTTP 503, ERR_3003) when engine is unavailable."""
    monkeypatch.setattr(flask_app.liveness_engine, "is_ready", False)
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": real_t1_b64},
    )
    assert response.status_code == 503
    json_data = response.get_json()

    assert json_data["success"] is False
    assert json_data["data"]["is_live"] is False
    assert json_data["data"]["fail_closed"] is True
    assert json_data["errorCode"] == "ERR_3003"


def test_api_check_liveness_fail_closed_on_inference_exception(client, real_t1_b64, monkeypatch):
    """Verify fail-closed behavior when inference runtime throws unexpected exception."""
    def mock_predict(*args, **kwargs):
        raise LivenessEngineError("Simulated ONNX C++ runtime graph failure")

    monkeypatch.setattr(flask_app.liveness_engine, "predict_liveness", mock_predict)
    response = client.post(
        "/api/v1/face/check-liveness",
        json={"image_base64": real_t1_b64},
    )
    assert response.status_code == 500
    json_data = response.get_json()

    assert json_data["success"] is False
    assert json_data["data"]["is_live"] is False
    assert json_data["data"]["fail_closed"] is True


# ============================================================================
# 5. CPU LATENCY & PERFORMANCE BENCHMARK
# ============================================================================

def test_cpu_liveness_inference_latency(real_t1_b64):
    """Verify end-to-end inference latency on CPU is well under 100ms."""
    engine = flask_app.liveness_engine
    detector = flask_app.detector

    img = decode_image_base64(real_t1_b64)
    face_info = detector.detect_single_face(img)

    # Warmup
    for _ in range(5):
        engine.predict_liveness(img, face_info)

    latencies = []
    for _ in range(20):
        t0 = time.perf_counter()
        engine.predict_liveness(img, face_info)
        latencies.append((time.perf_counter() - t0) * 1000)

    p50 = float(np.median(latencies))
    p95 = float(np.percentile(latencies, 95))

    # CPU inference budget is 100ms; typical is 2-10ms
    assert p50 < 50.0, f"p50 latency {p50}ms exceeded 50ms budget"
    assert p95 < 100.0, f"p95 latency {p95}ms exceeded 100ms budget"


# ============================================================================
# 6. INTEGRATION & COMPATIBILITY WITH FACE RECOGNITION (TASK-03)
# ============================================================================

def test_liveness_and_recognition_compatibility(client, real_t1_b64, second_face_b64):
    """Verify that liveness and recognition operate seamlessly on the same image."""
    # 1. Run Liveness
    resp_liveness = client.post(
        "/api/v1/face/check-liveness", json={"image_base64": real_t1_b64}
    )
    assert resp_liveness.status_code == 200
    assert resp_liveness.get_json()["data"]["is_live"] is True

    # 2. Run Embedding Extraction
    resp_extract = client.post(
        "/api/v1/face/extract-embedding", json={"image_base64": real_t1_b64}
    )
    assert resp_extract.status_code == 200
    emb = resp_extract.get_json()["data"]["embedding"]
    assert len(emb) == 512

    # 3. Verify Identity Matching
    resp_verify = client.post(
        "/api/v1/face/verify-face",
        json={"source_embedding": emb, "target_embedding": emb},
    )
    assert resp_verify.status_code == 200
    assert resp_verify.get_json()["data"]["matched"] is True
