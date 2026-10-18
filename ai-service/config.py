"""UniCheck AI Service - Configuration Module

Defines model paths, inference thresholds, image constraints, and runtime
settings for Face Detection, Alignment, and ArcFace Feature Extraction.
"""

import os

# Base Directories
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.environ.get("AI_MODEL_DIR", os.path.join(BASE_DIR, "models"))

# Model Weights Paths
DETECTOR_MODEL_PATH = os.environ.get(
    "AI_DETECTOR_MODEL_PATH",
    os.path.join(MODEL_DIR, "face_detection_yunet_2023mar.onnx"),
)
RECOGNITION_MODEL_PATH = os.environ.get(
    "AI_RECOGNITION_MODEL_PATH", os.path.join(MODEL_DIR, "w600k_mbf.onnx")
)

# Model Metadata
MODEL_NAME = "ArcFace-MobileFaceNet"
MODEL_VERSION = "w600k_mbf_v1"
DETECTOR_NAME = "YuNet-2023mar"
EMBEDDING_DIMENSION = 512

# Detection Hyperparameters
DETECTION_SCORE_THRESHOLD = float(
    os.environ.get("AI_DETECTION_SCORE_THRESHOLD", "0.6")
)
DETECTION_NMS_THRESHOLD = float(
    os.environ.get("AI_DETECTION_NMS_THRESHOLD", "0.3")
)
DETECTION_TOP_K = int(os.environ.get("AI_DETECTION_TOP_K", "5000"))

# Quality & Face Geometry Constraints
MIN_FACE_WIDTH = int(os.environ.get("AI_MIN_FACE_WIDTH", "60"))
MIN_FACE_HEIGHT = int(os.environ.get("AI_MIN_FACE_HEIGHT", "60"))
MAX_IMAGE_DIMENSION = int(os.environ.get("AI_MAX_IMAGE_DIMENSION", "4096"))
MAX_PAYLOAD_BYTES = int(
    os.environ.get("AI_MAX_PAYLOAD_BYTES", str(10 * 1024 * 1024))
)  # 10MB

# Face Verification Thresholds
# Standard ArcFace Cosine Similarity Threshold:
# Empirically calibrated for Far/Frr balance on Glint360k/WebFace600k:
# Cosine similarity >= 0.68 signifies high confidence identity match.
DEFAULT_SIMILARITY_THRESHOLD = float(
    os.environ.get("AI_FACE_MATCH_THRESHOLD", "0.68")
)
MIN_SIMILARITY_THRESHOLD = -1.0
MAX_SIMILARITY_THRESHOLD = 1.0

# Supported image MIME types / extensions
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "webp"}

# Liveness Anti-Spoofing Model Settings (MiniFASNet / Silent-Face-Anti-Spoofing)
LIVENESS_MODEL_V2_PATH = os.environ.get(
    "AI_LIVENESS_MODEL_V2_PATH",
    os.path.join(MODEL_DIR, "MiniFASNetV2.onnx"),
)
LIVENESS_MODEL_V1SE_PATH = os.environ.get(
    "AI_LIVENESS_MODEL_V1SE_PATH",
    os.path.join(MODEL_DIR, "MiniFASNetV1SE.onnx"),
)
LIVENESS_MODEL_MODE = os.environ.get("AI_LIVENESS_MODEL_MODE", "ensemble")  # "ensemble", "v2", or "v1se"
LIVENESS_MODEL_NAME = "MiniFASNet-Ensemble"
LIVENESS_MODEL_VERSION = "v2_v1se_onnx"
LIVENESS_INPUT_WIDTH = 80
LIVENESS_INPUT_HEIGHT = 80
LIVENESS_SCALE_V2 = 2.7
LIVENESS_SCALE_V1SE = 4.0

# Calibrated Liveness Decision Threshold (Posterior Real-Face Probability)
# Score >= 0.70 confirms physical bona fide live person
DEFAULT_LIVENESS_THRESHOLD = float(
    os.environ.get("AI_LIVENESS_THRESHOLD", "0.70")
)

