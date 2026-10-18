"""UniCheck AI Service - Face Engine (Feature Extractor)

Implements ArcFace/MobileFaceNet deep feature extraction pipeline:
Face Detection -> Landmark Alignment (112x112) -> Normalization -> ONNX Inference -> L2 Normalized Embeddings.
"""

import logging
import os
import cv2
import numpy as np
import onnxruntime as ort

import config

logger = logging.getLogger("unicheck.ai.face_engine")

# Standard 112x112 ArcFace / InsightFace reference landmark points
REFERENCE_LANDMARKS_112 = np.array(
    [
        [38.2946, 51.6963],  # right eye
        [73.5318, 51.5014],  # left eye
        [56.0252, 71.7366],  # nose tip
        [41.5493, 92.3655],  # right mouth corner
        [70.7299, 92.2041],  # left mouth corner
    ],
    dtype=np.float32,
)


class FaceEngineError(Exception):
    """Exception raised for failures in the face extraction engine."""

    def __init__(self, message, error_code="ERR_1000", status_code=500):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code


class FaceEngine:
    """Manages the ArcFace ONNX model session, image alignment, and embedding extraction."""

    def __init__(self, model_path: str = None):
        self.model_path = model_path or config.RECOGNITION_MODEL_PATH
        self.session = None
        self.input_name = None
        self.output_name = None
        self.output_dim = config.EMBEDDING_DIMENSION
        self._init_session()

    def _init_session(self):
        """Loads ONNX Runtime inference session with CPUExecutionProvider."""
        if not os.path.exists(self.model_path):
            logger.error("ArcFace model file not found at %s", self.model_path)
            return

        try:
            opts = ort.SessionOptions()
            opts.intra_op_num_threads = int(os.environ.get("ORT_NUM_THREADS", "2"))
            opts.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
            opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

            self.session = ort.InferenceSession(
                self.model_path,
                sess_options=opts,
                providers=["CPUExecutionProvider"],
            )

            # Discover input and output node names & shapes
            inputs = self.session.get_inputs()
            self.input_name = inputs[0].name

            outputs = self.session.get_outputs()
            self.output_name = outputs[0].name
            out_shape = outputs[0].shape
            if len(out_shape) >= 2 and isinstance(out_shape[1], int):
                self.output_dim = out_shape[1]

            logger.info(
                "ArcFace ONNX session loaded from %s (Input: %s, Output: %s, Dimension: %d)",
                self.model_path,
                self.input_name,
                self.output_name,
                self.output_dim,
            )
        except Exception as e:
            logger.error("Failed to load ArcFace ONNX session: %s", e)
            self.session = None

    @property
    def is_ready(self) -> bool:
        return self.session is not None

    def align_face(
        self, image: np.ndarray, bbox: dict, landmarks: list = None
    ) -> np.ndarray:
        """Aligns the detected face to a standard 112x112 portrait using 5 landmarks.

        Falls back to bounded bounding-box crop with margin if landmarks are
        unavailable.
        """
        h, w = image.shape[:2]

        # Use 5 facial landmarks for similarity affine transformation
        if landmarks and len(landmarks) == 5:
            src_pts = np.array(landmarks, dtype=np.float32)
            M, _ = cv2.estimateAffinePartial2D(
                src_pts, REFERENCE_LANDMARKS_112, method=cv2.LMEDS
            )
            if M is not None:
                aligned = cv2.warpAffine(
                    image, M, (112, 112), borderValue=0.0
                )
                return aligned

        # Fallback: Crop with 20% margin
        bx = max(0, bbox["x"])
        by = max(0, bbox["y"])
        bw = bbox["width"]
        bh = bbox["height"]

        margin_x = int(bw * 0.1)
        margin_y = int(bh * 0.1)

        x1 = max(0, bx - margin_x)
        y1 = max(0, by - margin_y)
        x2 = min(w, bx + bw + margin_x)
        y2 = min(h, by + bh + margin_y)

        crop = image[y1:y2, x1:x2]
        if crop.size == 0:
            raise FaceEngineError("Không thể cắt khuôn mặt từ tọa độ bounding box")

        return cv2.resize(crop, (112, 112), interpolation=cv2.INTER_LINEAR)

    def preprocess_aligned_face(self, aligned_bgr: np.ndarray) -> np.ndarray:
        """Preprocesses 112x112 BGR face image:

        BGR -> RGB -> normalize to [-1.0, 1.0] -> NCHW tensor float32.
        """
        rgb = cv2.cvtColor(aligned_bgr, cv2.COLOR_BGR2RGB).astype(np.float32)
        # Standard ArcFace input normalization: (x - 127.5) / 128.0
        normalized = (rgb - 127.5) / 128.0
        # Transpose from (112, 112, 3) to (3, 112, 112)
        transposed = np.transpose(normalized, (2, 0, 1))
        # Add batch dimension -> (1, 3, 112, 112)
        tensor = np.expand_dims(transposed, axis=0)
        return tensor

    def extract_embedding(
        self, image: np.ndarray, face_info: dict
    ) -> np.ndarray:
        """Executes full embedding pipeline for a single detected face.

        Returns:
            np.ndarray: 512-dimensional L2-normalized float32 vector.
        """
        if not self.is_ready:
            raise FaceEngineError(
                "Động cơ nhận diện khuôn mặt chưa sẵn sàng hoặc model chưa tải được",
                error_code="ERR_1000",
                status_code=503,
            )

        bbox = face_info["bbox"]
        landmarks = face_info.get("landmarks")

        # 1. Align face
        aligned = self.align_face(image, bbox, landmarks)

        # 2. Preprocess
        tensor = self.preprocess_aligned_face(aligned)

        # 3. Model inference
        try:
            outputs = self.session.run(None, {self.input_name: tensor})
            raw_emb = outputs[0][0].astype(np.float32)
        except Exception as e:
            logger.error("ONNX model execution failed: %s", e)
            raise FaceEngineError(
                f"Lỗi thực thi mô hình nhận diện: {str(e)}",
                error_code="ERR_1000",
                status_code=500,
            ) from e

        # 4. Rigorous Sanity Checks
        if not np.all(np.isfinite(raw_emb)):
            raise FaceEngineError(
                "Vector đặc trưng chứa giá trị bất thường (NaN/Infinity)"
            )

        norm = float(np.linalg.norm(raw_emb))
        if norm < 1e-6:
            raise FaceEngineError(
                "Vector đặc trưng có chuẩn độ dài bằng 0 (Zero vector)"
            )

        # 5. L2 Normalization
        normalized_emb = raw_emb / norm

        # Ensure strict unit length
        assert (
            abs(float(np.linalg.norm(normalized_emb)) - 1.0) < 1e-4
        ), "L2 Normalization verification failed"

        return normalized_emb
