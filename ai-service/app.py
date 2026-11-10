"""UniCheck AI Microservice - Flask Application Entrypoint

Exposes REST endpoints for:
- Health check with model readiness inspection
- Deep feature extraction using ArcFace/MobileFaceNet
- Face verification & identity matching using Cosine Similarity
- Fail-closed Liveness contract (Anti-spoofing scheduled for TASK-07)
"""

import logging
import os
from flask import Flask, jsonify, request
from flask_cors import CORS

import config
from face_detector import (
    FaceDetector,
    FaceDetectionError,
    NoFaceDetectedError,
    MultipleFacesDetectedError,
    decode_image_base64,
)
from face_engine import FaceEngine, FaceEngineError
from face_matcher import verify_vectors, FaceMatchingError
from liveness_engine import (
    LivenessEngine,
    LivenessEngineError,
    LivenessModelNotReadyError,
)


# Configure structured logging without leaking biometrics
logging.basicConfig(
    level=logging.INFO,
    format="[%(asctime)s] [%(levelname)s] [%(name)s]: %(message)s",
)
logger = logging.getLogger("unicheck.ai.app")

app = Flask(__name__)
CORS(app)

# Limit request payload size to 10MB
app.config["MAX_CONTENT_LENGTH"] = config.MAX_PAYLOAD_BYTES

# Global Engine, Detector & Liveness Singletons (Loaded on startup)
detector = FaceDetector(config.DETECTOR_MODEL_PATH)
engine = FaceEngine(config.RECOGNITION_MODEL_PATH)
liveness_engine = LivenessEngine(
    config.LIVENESS_MODEL_V2_PATH,
    config.LIVENESS_MODEL_V1SE_PATH,
    mode=config.LIVENESS_MODEL_MODE,
    default_threshold=config.DEFAULT_LIVENESS_THRESHOLD,
)



@app.errorhandler(413)
def request_entity_too_large(error):
    return (
        jsonify({
            "success": False,
            "data": None,
            "message": f"Kích thước tệp vượt quá giới hạn cho phép ({config.MAX_PAYLOAD_BYTES // (1024*1024)}MB)",
            "errorCode": "ERR_1001",
        }),
        413,
    )


@app.errorhandler(404)
def not_found(error):
    return (
        jsonify({
            "success": False,
            "data": None,
            "message": "Tài nguyên không tồn tại",
            "errorCode": "ERR_1002",
        }),
        404,
    )


@app.errorhandler(405)
def method_not_allowed(error):
    return (
        jsonify({
            "success": False,
            "data": None,
            "message": "Phương thức HTTP không được hỗ trợ",
            "errorCode": "ERR_1003",
        }),
        405,
    )


@app.errorhandler(500)
def internal_error(error):
    logger.error("Internal unhandled exception: %s", error)
    return (
        jsonify({
            "success": False,
            "data": None,
            "message": "Lỗi máy chủ AI nội bộ",
            "errorCode": "ERR_1000",
        }),
        500,
    )


@app.route("/health", methods=["GET"])
def health():
    """Health check endpoint distinguishing service running from model readiness."""
    is_ready = detector.is_ready and engine.is_ready and liveness_engine.is_ready
    status_str = "UP" if is_ready else "DEGRADED"

    return (
        jsonify({
            "success": True,
            "data": {
                "status": status_str,
                "service": "UniCheck AI Microservice",
                "version": "1.0.0",
                "model_ready": engine.is_ready,
                "detector_ready": detector.is_ready,
                "liveness_ready": liveness_engine.is_ready,
                "model_name": config.MODEL_NAME,
                "model_version": config.MODEL_VERSION,
                "liveness_model_name": liveness_engine.model_name,
                "liveness_model_version": liveness_engine.model_version,
                "liveness_mode": liveness_engine.mode,
                "liveness_threshold": liveness_engine.default_threshold,
                "embedding_dimension": engine.output_dim,
                "detector_name": config.DETECTOR_NAME,
            },
            "message": (
                "AI Service is healthy and all models (Detector, Recognition, Liveness) are ready"
                if is_ready
                else "AI Service is running but one or more models are degraded or missing"
            ),
            "errorCode": None,
        }),
        200,
    )


@app.route("/api/v1/face/extract-embedding", methods=["POST"])
def extract_embedding():
    """Extracts a 512-dimensional L2-normalized ArcFace embedding from an image.

    Payload:
        { "image_base64": "<base64 encoded image string>" }
    """
    data = request.get_json(silent=True) or {}
    image_base64 = data.get("image_base64")

    if not image_base64:
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": "Dữ liệu ảnh 'image_base64' không được để trống",
                "errorCode": "ERR_1001",
            }),
            400,
        )

    try:
        # 1. Decode Image safely
        image = decode_image_base64(image_base64)

        # 2. Detect Single Face
        face_info = detector.detect_single_face(image)
        upright_image = face_info.get("image", image)

        # 3. Extract Feature Vector via ArcFace ONNX
        embedding = engine.extract_embedding(upright_image, face_info)

        return (
            jsonify({
                "success": True,
                "data": {
                    "embedding": embedding.tolist(),
                    "embedding_dimension": len(embedding),
                    "model_name": config.MODEL_NAME,
                    "model_version": config.MODEL_VERSION,
                    "face_detected": True,
                    "confidence": face_info["confidence"],
                    "bounding_box": face_info["bbox"],
                    "quality": {
                        "face_width": face_info["bbox"]["width"],
                        "face_height": face_info["bbox"]["height"],
                    },
                },
                "message": "Trích xuất đặc trưng khuôn mặt thành công",
                "errorCode": None,
            }),
            200,
        )

    except NoFaceDetectedError as e:
        logger.info("Face extraction failed: No face detected")
        return (
            jsonify({
                "success": False,
                "data": {
                    "face_detected": False,
                    "model_name": config.MODEL_NAME,
                    "model_version": config.MODEL_VERSION,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except MultipleFacesDetectedError as e:
        logger.info("Face extraction failed: Multiple faces detected (%d)", e.count)
        return (
            jsonify({
                "success": False,
                "data": {
                    "face_detected": False,
                    "face_count": e.count,
                    "model_name": config.MODEL_NAME,
                    "model_version": config.MODEL_VERSION,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except FaceDetectionError as e:
        logger.warning("Face detection constraint error: %s", e.message)
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except FaceEngineError as e:
        logger.error("Face engine runtime error: %s", e.message)
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except Exception as e:
        logger.error("Unexpected error in extract_embedding: %s", e)
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": "Lỗi nội bộ khi xử lý trích xuất khuôn mặt",
                "errorCode": "ERR_1000",
            }),
            500,
        )


@app.route("/api/v1/face/verify-face", methods=["POST"])
def verify_face():
    """Verifies whether two face representations belong to the same identity.

    Accepts:
        - Two embeddings: source_embedding, target_embedding
        - Or two base64 images: source_image_base64, target_image_base64
        - Or mixed: source_embedding, target_image_base64
    Optional:
        - threshold: float (default config.DEFAULT_SIMILARITY_THRESHOLD = 0.68)
        - metric: "cosine" (default) or "euclidean"
    """
    data = request.get_json(silent=True) or {}
    threshold = data.get("threshold", config.DEFAULT_SIMILARITY_THRESHOLD)
    metric = data.get("metric", "cosine")

    source_emb = data.get("source_embedding")
    target_emb = data.get("target_embedding")

    try:
        # If image base64 provided instead of embedding, extract on the fly
        if source_emb is None and data.get("source_image_base64"):
            img = decode_image_base64(data["source_image_base64"])
            face = detector.detect_single_face(img)
            source_emb = engine.extract_embedding(face.get("image", img), face)

        if target_emb is None and data.get("target_image_base64"):
            img = decode_image_base64(data["target_image_base64"])
            face = detector.detect_single_face(img)
            target_emb = engine.extract_embedding(face.get("image", img), face)

        if source_emb is None or target_emb is None:
            return (
                jsonify({
                    "success": False,
                    "data": None,
                    "message": "Yêu cầu cung cấp hai vector đặc trưng (source_embedding, target_embedding) hoặc hai ảnh base64",
                    "errorCode": "ERR_1001",
                }),
                400,
            )

        result = verify_vectors(source_emb, target_emb, threshold=threshold, metric=metric)

        is_matched = result["matched"]
        msg = (
            "Xác thực so khớp khuôn mặt thành công"
            if is_matched
            else "Khuôn mặt không khớp với hồ sơ đã đăng ký"
        )
        err_code = None if is_matched else "ERR_3004"

        return (
            jsonify({
                "success": is_matched,
                "data": result,
                "message": msg,
                "errorCode": err_code,
            }),
            200,
        )

    except FaceDetectionError as e:
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except FaceMatchingError as e:
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except Exception as e:
        logger.error("Unexpected error in verify_face: %s", e)
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": "Lỗi xử lý so khớp khuôn mặt",
                "errorCode": "ERR_1000",
            }),
            500,
        )


@app.route("/api/v1/face/check-liveness", methods=["POST"])
def check_liveness():
    """Evaluates facial liveness and presentation attack status.

    Pipeline:
    1. Decode and validate Base64 image payload.
    2. Detect single face using YuNet (reject 0 or >1 faces).
    3. Execute MiniFASNet anti-spoofing model inference (scale-aware crops).
    4. Compute calibrated real-face probability and apply threshold decision.
    5. Return ISO/IEC 30107 compliant liveness assessment with attack breakdown.

    Payload:
        {
            "image_base64": "<base64 encoded image string>",
            "threshold": 0.70  # optional override (default config.DEFAULT_LIVENESS_THRESHOLD)
        }
    """
    data = request.get_json(silent=True) or {}
    image_base64 = data.get("image_base64")
    threshold = data.get("threshold")

    if not image_base64:
        return (
            jsonify({
                "success": False,
                "data": None,
                "message": "Dữ liệu ảnh 'image_base64' không được để trống",
                "errorCode": "ERR_1001",
            }),
            400,
        )

    # Fail closed if anti-spoofing engine is not ready
    if not liveness_engine.is_ready:
        logger.error("check_liveness invoked but liveness_engine is NOT ready (Fail-Closed)")
        return (
            jsonify({
                "success": False,
                "data": {
                    "is_live": False,
                    "status": "UNAVAILABLE",
                    "fail_closed": True,
                },
                "message": "Dịch vụ chống giả mạo khuôn mặt (Anti-Spoofing) chưa sẵn sàng (Fail-Closed)",
                "errorCode": "ERR_3003",
            }),
            503,
        )

    try:
        # 1. Decode Image safely
        image = decode_image_base64(image_base64)

        # 2. Detect Single Face
        face_info = detector.detect_single_face(image)
        upright_image = face_info.get("image", image)

        # 3. Predict Liveness via MiniFASNet ONNX Engine
        result = liveness_engine.predict_liveness(upright_image, face_info, threshold=threshold)

        is_live = result["is_live"]
        msg = (
            "Kiểm tra thực thể (liveness) thành công - Khuôn mặt người thật"
            if is_live
            else "Phát hiện dấu hiệu giả mạo khuôn mặt (Presentation Attack Detected)"
        )

        return (
            jsonify({
                "success": True,
                "data": {
                    "is_live": is_live,
                    "liveness_score": result["liveness_score"],
                    "threshold": result["threshold"],
                    "model_name": result["model_name"],
                    "model_version": result["model_version"],
                    "mode": result["mode"],
                    "face_detected": True,
                    "confidence": result["face_confidence"],
                    "bounding_box": result["bounding_box"],
                    "attack_type_detected": result["attack_type_detected"],
                    "probabilities": result["probabilities"],
                },
                "message": msg,
                "errorCode": None,
            }),
            200,
        )

    except NoFaceDetectedError as e:
        logger.info("Liveness check failed: No face detected")
        return (
            jsonify({
                "success": False,
                "data": {
                    "face_detected": False,
                    "is_live": False,
                    "model_name": liveness_engine.model_name,
                    "model_version": liveness_engine.model_version,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except MultipleFacesDetectedError as e:
        logger.info("Liveness check failed: Multiple faces detected (%d)", e.count)
        return (
            jsonify({
                "success": False,
                "data": {
                    "face_detected": False,
                    "face_count": e.count,
                    "is_live": False,
                    "model_name": liveness_engine.model_name,
                    "model_version": liveness_engine.model_version,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except FaceDetectionError as e:
        logger.warning("Liveness check face detection error: %s", e.message)
        return (
            jsonify({
                "success": False,
                "data": {
                    "is_live": False,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except LivenessModelNotReadyError as e:
        logger.error("Liveness check failed: %s", e.message)
        return (
            jsonify({
                "success": False,
                "data": {
                    "is_live": False,
                    "status": "UNAVAILABLE",
                    "fail_closed": True,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except LivenessEngineError as e:
        logger.error("Liveness engine error: %s", e.message)
        return (
            jsonify({
                "success": False,
                "data": {
                    "is_live": False,
                    "fail_closed": True,
                },
                "message": e.message,
                "errorCode": e.error_code,
            }),
            e.status_code,
        )

    except Exception as e:
        logger.error("Unexpected error in check_liveness: %s", e)
        return (
            jsonify({
                "success": False,
                "data": {
                    "is_live": False,
                    "fail_closed": True,
                },
                "message": "Lỗi nội bộ khi kiểm tra thực thể khuôn mặt (Fail-Closed)",
                "errorCode": "ERR_1000",
            }),
            500,
        )


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=False)
