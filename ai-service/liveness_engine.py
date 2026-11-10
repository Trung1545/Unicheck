"""UniCheck AI Service - Liveness & Face Anti-Spoofing Engine

Implements real AI-based passive face anti-spoofing using MiniFASNet models
(MiniFASNetV2 and MiniFASNetV1SE) via ONNX Runtime CPU inference.

Pipeline:
1. Validate detected face geometry.
2. Crop face region using scale-aware bounding box transformation:
   - Scale 2.7 for close-up texture analysis (MiniFASNetV2)
   - Scale 4.0 for broader context and perimeter inspection (MiniFASNetV1SE)
3. Resize to 80x80 pixels with NCHW float32 tensor format.
4. Execute ONNX inference session(s) on CPU.
5. Apply Softmax to 3-class logits:
   - Class 0: Print attack (paper, photo print, cutout mask)
   - Class 1: Bona fide presentation (real physical human face)
   - Class 2: Replay attack (digital screen, smartphone, tablet display)
6. Compute calibrated real-face probability and evaluate against threshold.
7. Return comprehensive liveness decision with attack breakdown.

ATTACK LIMITATIONS DISCLAIMER:
- This is a single-frame passive anti-spoofing engine trained on 2D print and
  screen replay presentation attacks.
- It does NOT evaluate temporal continuity, 3D silicone mask attacks, or
  deepfake video streams. For high-security environments, pair with an
  interactive challenge-response protocol (e.g. randomized head turn prompts).
"""

import logging
import os
import cv2
import numpy as np
import onnxruntime as ort

import config

logger = logging.getLogger("unicheck.ai.liveness_engine")


class LivenessEngineError(Exception):
    """Exception raised for failures in the liveness anti-spoofing engine."""

    def __init__(self, message, error_code="ERR_1000", status_code=500):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code


class LivenessModelNotReadyError(LivenessEngineError):
    """Exception raised when anti-spoofing model weights are unavailable or failed to load."""

    def __init__(self, message="Dịch vụ chống giả mạo khuôn mặt (Anti-Spoofing) chưa sẵn sàng (Fail-Closed)"):
        super().__init__(message, error_code="ERR_3003", status_code=503)


def get_scaled_bounding_box(src_w: int, src_h: int, bbox: list, scale: float) -> tuple:
    """Computes expanded, scale-aware crop coordinates with image boundary clamping.

    Args:
        src_w: Width of source image.
        src_h: Height of source image.
        bbox: Bounding box [x, y, w, h].
        scale: Expansion scale factor (e.g. 2.7 or 4.0).

    Returns:
        tuple: (x1, y1, x2, y2) integer coordinates for slicing.
    """
    x, y, box_w, box_h = bbox
    box_w = max(1, box_w)
    box_h = max(1, box_h)

    # Constrain scale to avoid exceeding image limits
    max_scale = min((src_h - 1) / box_h, (src_w - 1) / box_w, scale)
    new_w = box_w * max_scale
    new_h = box_h * max_scale

    center_x = x + box_w / 2.0
    center_y = y + box_h / 2.0

    left_top_x = center_x - new_w / 2.0
    left_top_y = center_y - new_h / 2.0
    right_bottom_x = center_x + new_w / 2.0
    right_bottom_y = center_y + new_h / 2.0

    # Adjust boundary overflow
    if left_top_x < 0:
        right_bottom_x -= left_top_x
        left_top_x = 0
    if left_top_y < 0:
        right_bottom_y -= left_top_y
        left_top_y = 0
    if right_bottom_x > src_w - 1:
        left_top_x -= (right_bottom_x - src_w + 1)
        right_bottom_x = src_w - 1
    if right_bottom_y > src_h - 1:
        left_top_y -= (right_bottom_y - src_h + 1)
        right_bottom_y = src_h - 1

    x1 = max(0, int(round(left_top_x)))
    y1 = max(0, int(round(left_top_y)))
    x2 = min(src_w - 1, int(round(right_bottom_x)))
    y2 = min(src_h - 1, int(round(right_bottom_y)))

    return x1, y1, x2, y2


def crop_face_for_liveness(
    image: np.ndarray,
    bbox: list,
    scale: float,
    out_w: int = 80,
    out_h: int = 80,
) -> np.ndarray:
    """Crops face from image using scale factor and resizes to target network input dimensions."""
    src_h, src_w = image.shape[:2]
    x1, y1, x2, y2 = get_scaled_bounding_box(src_w, src_h, bbox, scale)

    if x2 <= x1 or y2 <= y1:
        raise LivenessEngineError("Tọa độ khuôn mặt không hợp lệ sau khi căn chỉnh tỷ lệ")

    cropped = image[y1 : y2 + 1, x1 : x2 + 1]
    if cropped.size == 0:
        raise LivenessEngineError("Vùng khuôn mặt cắt ra có kích thước rỗng")

    resized = cv2.resize(cropped, (out_w, out_h), interpolation=cv2.INTER_LINEAR)
    return resized


def softmax_logits(logits: np.ndarray) -> np.ndarray:
    """Computes numerically stable Softmax probabilities along axis 1."""
    e_x = np.exp(logits - np.max(logits, axis=1, keepdims=True))
    probs = e_x / np.sum(e_x, axis=1, keepdims=True)
    return probs


class LivenessEngine:
    """Manages MiniFASNet ONNX model sessions, preprocessing, inference, and liveness decisions."""

    def __init__(
        self,
        model_v2_path: str = None,
        model_v1se_path: str = None,
        mode: str = None,
        default_threshold: float = None,
    ):
        self.model_v2_path = model_v2_path or config.LIVENESS_MODEL_V2_PATH
        self.model_v1se_path = model_v1se_path or config.LIVENESS_MODEL_V1SE_PATH
        self.mode = (mode or config.LIVENESS_MODEL_MODE).lower()
        self.default_threshold = (
            default_threshold
            if default_threshold is not None
            else config.DEFAULT_LIVENESS_THRESHOLD
        )

        self.session_v2 = None
        self.input_name_v2 = None
        self.output_name_v2 = None

        self.session_v1se = None
        self.input_name_v1se = None
        self.output_name_v1se = None

        self.model_name = config.LIVENESS_MODEL_NAME
        self.model_version = config.LIVENESS_MODEL_VERSION

        self._init_sessions()

    def _init_sessions(self):
        """Initializes ONNX Runtime sessions with CPU execution provider."""
        opts = ort.SessionOptions()
        opts.intra_op_num_threads = int(os.environ.get("ORT_NUM_THREADS", "2"))
        opts.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
        opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL

        # 1. Load MiniFASNetV2 (Scale 2.7)
        if self.mode in ("ensemble", "v2"):
            if os.path.exists(self.model_v2_path):
                try:
                    self.session_v2 = ort.InferenceSession(
                        self.model_v2_path,
                        sess_options=opts,
                        providers=["CPUExecutionProvider"],
                    )
                    self.input_name_v2 = self.session_v2.get_inputs()[0].name
                    self.output_name_v2 = self.session_v2.get_outputs()[0].name
                    logger.info(
                        "MiniFASNetV2 loaded from %s (Input: %s, Output: %s)",
                        self.model_v2_path,
                        self.input_name_v2,
                        self.output_name_v2,
                    )
                except Exception as e:
                    logger.error("Failed to initialize MiniFASNetV2 session: %s", e)
                    self.session_v2 = None
            else:
                logger.warning("MiniFASNetV2 weights file not found at %s", self.model_v2_path)

        # 2. Load MiniFASNetV1SE (Scale 4.0)
        if self.mode in ("ensemble", "v1se"):
            if os.path.exists(self.model_v1se_path):
                try:
                    self.session_v1se = ort.InferenceSession(
                        self.model_v1se_path,
                        sess_options=opts,
                        providers=["CPUExecutionProvider"],
                    )
                    self.input_name_v1se = self.session_v1se.get_inputs()[0].name
                    self.output_name_v1se = self.session_v1se.get_outputs()[0].name
                    logger.info(
                        "MiniFASNetV1SE loaded from %s (Input: %s, Output: %s)",
                        self.model_v1se_path,
                        self.input_name_v1se,
                        self.output_name_v1se,
                    )
                except Exception as e:
                    logger.error("Failed to initialize MiniFASNetV1SE session: %s", e)
                    self.session_v1se = None
            else:
                logger.warning("MiniFASNetV1SE weights file not found at %s", self.model_v1se_path)

    @property
    def is_ready(self) -> bool:
        """Determines whether the engine is ready for inference according to configured mode."""
        if hasattr(self, "_force_unready") and self._force_unready:
            return False
        if self.mode == "v2":
            return self.session_v2 is not None
        if self.mode == "v1se":
            return self.session_v1se is not None
        # Default ensemble mode: prefer both ready, but gracefully operate if at least one is ready
        return self.session_v2 is not None or self.session_v1se is not None

    @is_ready.setter
    def is_ready(self, val: bool):
        self._force_unready = not val


    def _infer_single_model(
        self, session: ort.InferenceSession, input_name: str, tensor: np.ndarray
    ) -> np.ndarray:
        """Runs inference on a single ONNX session and returns class probability vector."""
        outputs = session.run(None, {input_name: tensor})
        logits = outputs[0]
        probs = softmax_logits(logits)
        return probs[0]

    def predict_liveness(
        self, image: np.ndarray, face_info: dict, threshold: float = None
    ) -> dict:
        """Evaluates whether the detected face is a real live person or a presentation attack.

        Args:
            image: Full BGR OpenCV image.
            face_info: Dictionary containing detected face metadata ('bbox', 'confidence').
            threshold: Optional decision threshold override.

        Returns:
            dict containing:
                is_live (bool): Decision whether face is real.
                liveness_score (float): Real face probability [0.0, 1.0].
                threshold (float): Decision threshold applied.
                model_name (str): Active model identifier.
                model_version (str): Model version string.
                mode (str): Operational mode (ensemble/v2/v1se).
                attack_type_detected (str or None): Classification of spoof attack if detected.
                probabilities (dict): Posterior probabilities across real, print_paper, screen_replay.
                face_confidence (float): Face detection confidence score.
                bounding_box (dict): Face bounding box coordinates.
        """
        if not self.is_ready:
            raise LivenessModelNotReadyError()

        if face_info and "image" in face_info and face_info["image"] is not None:
            image = face_info["image"]

        if image is None or image.size == 0:
            raise LivenessEngineError("Dữ liệu ảnh rỗng hoặc không hợp lệ")

        bbox_dict = face_info.get("bbox")
        if not bbox_dict:
            raise LivenessEngineError("Thông tin bounding box của khuôn mặt không tồn tại")

        # Convert bbox dict to [x, y, w, h] list
        bbox = [
            int(bbox_dict["x"]),
            int(bbox_dict["y"]),
            int(bbox_dict["width"]),
            int(bbox_dict["height"]),
        ]

        active_probs = []

        try:
            # 1. MiniFASNetV2 inference (Scale 2.7)
            if self.session_v2 is not None and self.mode in ("ensemble", "v2"):
                crop_v2 = crop_face_for_liveness(
                    image,
                    bbox,
                    scale=config.LIVENESS_SCALE_V2,
                    out_w=config.LIVENESS_INPUT_WIDTH,
                    out_h=config.LIVENESS_INPUT_HEIGHT,
                )
                tensor_v2 = (
                    crop_v2.astype(np.float32)
                    .transpose(2, 0, 1)[np.newaxis, :]
                )
                p_v2 = self._infer_single_model(
                    self.session_v2, self.input_name_v2, tensor_v2
                )
                active_probs.append(p_v2)

            # 2. MiniFASNetV1SE inference (Scale 4.0)
            if self.session_v1se is not None and self.mode in ("ensemble", "v1se"):
                crop_v1se = crop_face_for_liveness(
                    image,
                    bbox,
                    scale=config.LIVENESS_SCALE_V1SE,
                    out_w=config.LIVENESS_INPUT_WIDTH,
                    out_h=config.LIVENESS_INPUT_HEIGHT,
                )
                tensor_v1se = (
                    crop_v1se.astype(np.float32)
                    .transpose(2, 0, 1)[np.newaxis, :]
                )
                p_v1se = self._infer_single_model(
                    self.session_v1se, self.input_name_v1se, tensor_v1se
                )
                active_probs.append(p_v1se)

            if not active_probs:
                raise LivenessEngineError("Không có mô hình anti-spoofing nào khả dụng để thực hiện dự đoán")

            # Average probabilities across active models in ensemble
            final_probs = np.mean(active_probs, axis=0)

            # Sanity validation on model outputs
            if not np.all(np.isfinite(final_probs)):
                raise LivenessEngineError("Đầu ra mô hình liveness chứa giá trị bất thường (NaN/Infinity)")

            # Parse probabilities: Class 0 = Print/Paper, Class 1 = Real Face, Class 2 = Screen/Replay
            prob_print = float(final_probs[0])
            prob_real = float(final_probs[1])
            prob_replay = float(final_probs[2])

            # Apply Decision Threshold
            decision_thresh = (
                threshold if threshold is not None else self.default_threshold
            )
            is_live = bool(prob_real >= decision_thresh)

            # Classify presentation attack category when fake
            attack_type = None
            if not is_live:
                if prob_print >= prob_replay:
                    attack_type = "PRINT_PAPER_OR_CUTOUT"
                else:
                    attack_type = "SCREEN_OR_VIDEO_REPLAY"

            logger.info(
                "[LivenessDecision] is_live=%s, score=%.4f, threshold=%.2f, model=%s(%s), mode=%s, attack=%s, probs={real: %.4f, print: %.4f, screen: %.4f}",
                is_live,
                round(prob_real, 4),
                float(decision_thresh),
                self.model_name,
                self.model_version,
                self.mode,
                attack_type,
                round(prob_real, 4),
                round(prob_print, 4),
                round(prob_replay, 4),
            )

            return {
                "is_live": is_live,
                "liveness_score": round(prob_real, 4),
                "threshold": float(decision_thresh),
                "model_name": self.model_name,
                "model_version": self.model_version,
                "mode": self.mode,
                "attack_type_detected": attack_type,
                "probabilities": {
                    "real": round(prob_real, 4),
                    "print_paper": round(prob_print, 4),
                    "screen_replay": round(prob_replay, 4),
                },
                "face_confidence": face_info.get("confidence", 1.0),
                "bounding_box": bbox_dict,
            }

        except (LivenessEngineError, LivenessModelNotReadyError):
            raise
        except Exception as exc:
            logger.error("Unexpected error during liveness inference: %s", exc)
            raise LivenessEngineError(f"Lỗi thực thi suy luận liveness: {str(exc)}") from exc
