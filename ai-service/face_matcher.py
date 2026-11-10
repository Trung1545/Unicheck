"""UniCheck AI Service - Face Matcher Module

Performs identity verification using Cosine Similarity and Euclidean Distance
with strict vector integrity validation and configurable thresholding.
"""

import logging
import numpy as np

import config

logger = logging.getLogger("unicheck.ai.face_matcher")


class FaceMatchingError(Exception):
    """Exception raised when vector comparison fails."""

    def __init__(self, message, error_code="ERR_1001", status_code=400):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code


def validate_vector(vector, name="Vector") -> np.ndarray:
    """Validates vector is non-empty, 1D array of finite numbers."""
    if vector is None:
        raise FaceMatchingError(f"{name} không được để trống")

    if not isinstance(vector, (list, tuple, np.ndarray)):
        raise FaceMatchingError(f"{name} phải là mảng hoặc danh sách số thực")

    arr = np.asarray(vector, dtype=np.float32)

    if arr.ndim != 1 or arr.size == 0:
        raise FaceMatchingError(f"{name} phải là vector 1 chiều khác rỗng")

    if not np.all(np.isfinite(arr)):
        raise FaceMatchingError(f"{name} chứa giá trị bất thường (NaN hoặc Infinity)")

    norm = float(np.linalg.norm(arr))
    if norm < 1e-6:
        raise FaceMatchingError(f"{name} có độ dài xấp xỉ 0 (Zero vector)")

    # Ensure L2 normalization
    return arr / norm


def compute_cosine_similarity(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """Computes Cosine Similarity between two L2-normalized vectors.

    Returns float in range [-1.0, 1.0].
    """
    v1 = validate_vector(vec1, "Vector 1")
    v2 = validate_vector(vec2, "Vector 2")

    if v1.shape[0] != v2.shape[0]:
        raise FaceMatchingError(
            f"Kích thước vector không khớp ({v1.shape[0]} != {v2.shape[0]}). Chỉ có thể so sánh vector từ cùng một mô hình"
        )

    sim = float(np.dot(v1, v2))
    return float(np.clip(sim, -1.0, 1.0))


def compute_euclidean_distance(vec1: np.ndarray, vec2: np.ndarray) -> float:
    """Computes Euclidean distance between two vectors."""
    v1 = validate_vector(vec1, "Vector 1")
    v2 = validate_vector(vec2, "Vector 2")

    if v1.shape[0] != v2.shape[0]:
        raise FaceMatchingError(
            f"Kích thước vector không khớp ({v1.shape[0]} != {v2.shape[0]})"
        )

    dist = float(np.linalg.norm(v1 - v2))
    return dist


def verify_vectors(
    embedding1,
    embedding2,
    threshold: float = None,
    metric: str = "cosine"
) -> dict:
    """Verifies if two embeddings belong to the same identity.

    Args:
        embedding1: First embedding vector (e.g. stored profile)
        embedding2: Second embedding vector (e.g. check-in selfie)
        threshold: Decision threshold (defaults to config.DEFAULT_SIMILARITY_THRESHOLD)
        metric: Comparison metric ('cosine' or 'euclidean')

    Returns:
        dict: {
            "matched": bool,
            "similarity_score": float,
            "threshold": float,
            "metric": str,
            "euclidean_distance": float
        }
    """
    if threshold is None:
        threshold = config.DEFAULT_SIMILARITY_THRESHOLD
    else:
        try:
            threshold = float(threshold)
        except (ValueError, TypeError):
            raise FaceMatchingError("Ngưỡng so khớp (threshold) phải là số thực")

        if threshold < config.MIN_SIMILARITY_THRESHOLD or threshold > config.MAX_SIMILARITY_THRESHOLD:
            raise FaceMatchingError(
                f"Ngưỡng so khớp phải nằm trong khoảng [{config.MIN_SIMILARITY_THRESHOLD}, {config.MAX_SIMILARITY_THRESHOLD}]"
            )

    cosine_sim = compute_cosine_similarity(embedding1, embedding2)
    euclidean_dist = compute_euclidean_distance(embedding1, embedding2)

    if metric == "euclidean":
        matched = euclidean_dist <= threshold
    else:
        matched = cosine_sim >= threshold

    return {
        "matched": bool(matched),
        "similarity_score": round(cosine_sim, 4),
        "similarity": round(cosine_sim, 4),
        "threshold": round(threshold, 4),
        "metric": metric,
        "euclidean_distance": round(euclidean_dist, 4),
        "distance": round(euclidean_dist, 4),
        "model_name": config.MODEL_NAME,
        "model_version": config.MODEL_VERSION,
    }
