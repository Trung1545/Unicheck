"""UniCheck AI Service - Face Detector Module

Provides safe image decoding, validation, and multi-face detection using
OpenCV's YuNet ONNX neural detector with fallback to Haar Cascades.
"""

import base64
import binascii
import logging
import os
import cv2
import numpy as np

import config

logger = logging.getLogger("unicheck.ai.face_detector")


class FaceDetectionError(Exception):
    """Base exception for face detection errors."""

    def __init__(self, message, error_code="ERR_1001", status_code=400):
        super().__init__(message)
        self.message = message
        self.error_code = error_code
        self.status_code = status_code


class InvalidImageError(FaceDetectionError):
    """Raised when the base64 or image data cannot be parsed/decoded."""

    def __init__(self, message="Dữ liệu ảnh không hợp lệ hoặc bị hỏng"):
        super().__init__(message, error_code="ERR_1001", status_code=400)


class ImageDimensionExceededError(FaceDetectionError):
    """Raised when image resolution exceeds the maximum allowed threshold."""

    def __init__(
        self,
        message=f"Độ phân giải ảnh vượt quá giới hạn tối đa ({config.MAX_IMAGE_DIMENSION}px)",
    ):
        super().__init__(message, error_code="ERR_1001", status_code=400)


class NoFaceDetectedError(FaceDetectionError):
    """Raised when no face is found in the provided image."""

    def __init__(self, message="Không phát hiện khuôn mặt trong ảnh"):
        super().__init__(message, error_code="ERR_3001", status_code=400)


class MultipleFacesDetectedError(FaceDetectionError):
    """Raised when more than one face is detected in the image."""

    def __init__(
        self,
        count=2,
        message="Phát hiện nhiều hơn một khuôn mặt trong ảnh. Vui lòng chỉ chụp một người duy nhất",
    ):
        super().__init__(message, error_code="ERR_3002", status_code=400)
        self.count = count


class FaceTooSmallError(FaceDetectionError):
    """Raised when the detected face is below the minimum required bounding box."""

    def __init__(
        self,
        message=f"Khuôn mặt quá nhỏ (yêu cầu tối thiểu {config.MIN_FACE_WIDTH}x{config.MIN_FACE_HEIGHT}px)",
    ):
        super().__init__(message, error_code="ERR_1001", status_code=400)


def decode_image_base64(base64_str: str) -> np.ndarray:
    """Safely decodes a base64 encoded image string into an OpenCV BGR numpy array.

    Handles optional Data URL prefix, cleans whitespace/newlines, fixes padding,
    and applies PIL ImageOps.exif_transpose so that portrait/landscape images
    with EXIF orientation tags (e.g. from Android CameraX/Camera2) are transposed upright.
    """
    if not base64_str or not isinstance(base64_str, str):
        raise InvalidImageError("Dữ liệu ảnh base64 rỗng hoặc không đúng định dạng")

    # Strip Data URL header if present
    if "," in base64_str:
        base64_str = base64_str.split(",", 1)[1]

    # Clean whitespace, newlines, tabs
    base64_str = "".join(base64_str.split())

    # Fix base64 padding if missing
    missing_padding = len(base64_str) % 4
    if missing_padding:
        base64_str += "=" * (4 - missing_padding)

    # Validate size before decoding
    raw_len = len(base64_str)
    estimated_bytes = (raw_len * 3) // 4
    if estimated_bytes > config.MAX_PAYLOAD_BYTES:
        raise FaceDetectionError(
            f"Kích thước tệp vượt quá giới hạn cho phép ({config.MAX_PAYLOAD_BYTES // (1024*1024)}MB)",
            error_code="ERR_1001",
            status_code=413,
        )

    try:
        image_bytes = base64.b64decode(base64_str, validate=True)
    except (binascii.Error, ValueError) as exc:
        raise InvalidImageError("Chuỗi Base64 bị lỗi hoặc không thể giải mã") from exc

    if not image_bytes:
        raise InvalidImageError("Dữ liệu nhị phân sau giải mã rỗng")

    # Use PIL with ImageOps.exif_transpose to automatically orient image upright
    image = None
    try:
        import io
        from PIL import Image, ImageOps

        pil_img = Image.open(io.BytesIO(image_bytes))
        pil_img = ImageOps.exif_transpose(pil_img)
        if pil_img.mode != "RGB":
            pil_img = pil_img.convert("RGB")
        image = cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
    except Exception as pil_err:
        logger.warning("PIL exif_transpose decode failed: %s. Falling back to cv2.imdecode", pil_err)
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

    if image is None or image.size == 0:
        raise InvalidImageError("Không thể đọc định dạng ảnh (chỉ hỗ trợ JPEG/PNG)")

    h, w = image.shape[:2]
    if h > config.MAX_IMAGE_DIMENSION or w > config.MAX_IMAGE_DIMENSION:
        raise ImageDimensionExceededError(
            f"Kích thước ảnh {w}x{h}px vượt quá giới hạn tối đa {config.MAX_IMAGE_DIMENSION}px"
        )

    return image


class FaceDetector:
    """Robust face detector utilizing OpenCV's YuNet ONNX with Haar Cascade fallback."""

    def __init__(self, model_path: str = None):
        self.model_path = model_path or config.DETECTOR_MODEL_PATH
        self.yunet = None
        self.haar_cascade = None
        self._init_detector()

    def _init_detector(self):
        """Initializes YuNet ONNX detector or falls back to Haar Cascade."""
        if os.path.exists(self.model_path):
            try:
                self.yunet = cv2.FaceDetectorYN.create(
                    self.model_path,
                    "",
                    (320, 320),
                    score_threshold=config.DETECTION_SCORE_THRESHOLD,
                    nms_threshold=config.DETECTION_NMS_THRESHOLD,
                    top_k=config.DETECTION_TOP_K,
                )
                logger.info("YuNet ONNX FaceDetector successfully loaded from %s", self.model_path)
            except Exception as e:
                logger.warning("Failed to initialize YuNet FaceDetectorYN: %s. Using Haar Cascade fallback", e)
                self.yunet = None

        if self.yunet is None:
            haar_path = os.path.join(cv2.data.haarcascades, "haarcascade_frontalface_default.xml")
            if os.path.exists(haar_path):
                self.haar_cascade = cv2.CascadeClassifier(haar_path)
                logger.info("Haar Cascade FaceDetector loaded as fallback from %s", haar_path)
            else:
                logger.error("Neither YuNet nor Haar Cascade could be loaded!")

    @property
    def is_ready(self) -> bool:
        return (self.yunet is not None) or (self.haar_cascade is not None)

    def detect_faces(self, image: np.ndarray) -> list:
        """Detects all faces in the image.

        Returns a list of dicts:
        [
            {
                "bbox": {"x": int, "y": int, "width": int, "height": int},
                "confidence": float,
                "landmarks": list of 5 [x, y] coordinates (or None if Haar)
            },
            ...
        ]
        """
        h, w = image.shape[:2]
        detected = []

        if self.yunet is not None:
            self.yunet.setInputSize((w, h))
            retval, faces = self.yunet.detect(image)
            if faces is not None and len(faces) > 0:
                for f in faces:
                    x, y, bw, bh = int(f[0]), int(f[1]), int(f[2]), int(f[3])
                    score = float(f[14])
                    # 5 facial landmarks: right eye, left eye, nose, right mouth, left mouth
                    landmarks = [
                        [float(f[4]), float(f[5])],
                        [float(f[6]), float(f[7])],
                        [float(f[8]), float(f[9])],
                        [float(f[10]), float(f[11])],
                        [float(f[12]), float(f[13])],
                    ]
                    detected.append({
                        "bbox": {"x": x, "y": y, "width": bw, "height": bh},
                        "confidence": round(score, 4),
                        "landmarks": landmarks,
                    })
        elif self.haar_cascade is not None:
            gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
            faces = self.haar_cascade.detectMultiScale(
                gray, scaleFactor=1.1, minNeighbors=5, minSize=(config.MIN_FACE_WIDTH, config.MIN_FACE_HEIGHT)
            )
            for (x, y, bw, bh) in faces:
                detected.append({
                    "bbox": {"x": int(x), "y": int(y), "width": int(bw), "height": int(bh)},
                    "confidence": 0.90,
                    "landmarks": None,
                })

        return detected

    def detect_single_face(self, image: np.ndarray) -> dict:
        """Enforces single-face policy with auto-orientation recovery.

        If no face is detected in the default orientation (e.g. unflagged sensor rotation),
        attempts candidate rotations (90° CW, 90° CCW, 180°) to align the face upright.

        Raises:
            NoFaceDetectedError: if 0 faces found
            MultipleFacesDetectedError: if > 1 faces found
            FaceTooSmallError: if face bounding box is below min size
        """
        faces = self.detect_faces(image)
        upright_image = image

        if len(faces) == 0:
            for rot in (cv2.ROTATE_90_CLOCKWISE, cv2.ROTATE_90_COUNTERCLOCKWISE, cv2.ROTATE_180):
                candidate = cv2.rotate(image, rot)
                cand_faces = self.detect_faces(candidate)
                if len(cand_faces) > 0:
                    faces = cand_faces
                    upright_image = candidate
                    logger.info("Face detected after auto-orientation rotation (%s)", rot)
                    break

        count = len(faces)

        if count == 0:
            raise NoFaceDetectedError()
        if count > 1:
            raise MultipleFacesDetectedError(count=count)

        face = faces[0]
        bbox = face["bbox"]
        if bbox["width"] < config.MIN_FACE_WIDTH or bbox["height"] < config.MIN_FACE_HEIGHT:
            raise FaceTooSmallError()

        face["image"] = upright_image
        return face
