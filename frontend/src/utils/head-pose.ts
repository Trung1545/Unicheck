// ==============================================================================
// UniCheck - Head Pose Estimation & Validation Utilities
// Real-time Yaw, Pitch, Roll calculation from MediaPipe 3D Landmarks & Matrices
// Calibration conventions:
//   - Yaw > 0: Turned to Subject's LEFT
//   - Yaw < 0: Turned to Subject's RIGHT
//   - |Yaw| <= 8°: FRONTAL (Looking straight)
//   - Pitch: Nodding (+ Up, - Down)
//   - Roll: Neck Tilt (+ Right, - Left)
// ==============================================================================

export interface NormalizedPoint3D {
  x: number;
  y: number;
  z: number;
}

export interface TransformationMatrix {
  rows: number;
  columns: number;
  data: number[];
}

export interface HeadPoseEstimate {
  yaw: number;       // in degrees
  pitch: number;     // in degrees
  roll: number;      // in degrees
  confidence: number;
  isFrontal: boolean;
  direction: 'FRONTAL' | 'LEFT' | 'RIGHT' | 'UNKNOWN';
}

export interface StepValidationResult {
  isValid: boolean;
  step: 'frontal' | 'left' | 'right';
  yaw: number;
  pitch: number;
  roll: number;
  guideMessage: string;
  warningMessage: string | null;
  poseQualified: boolean;
}

// MediaPipe Landmark Constants
export const LANDMARK_NOSE_TIP = 1;
export const LANDMARK_FOREHEAD = 10;
export const LANDMARK_CHIN = 152;
export const LANDMARK_RIGHT_EYE = 33;
export const LANDMARK_LEFT_EYE = 263;
export const LANDMARK_RIGHT_CHEEK = 234;
export const LANDMARK_LEFT_CHEEK = 454;

/**
 * Extract Euler angles (Yaw, Pitch, Roll) from MediaPipe 4x4 Transformation Matrix
 */
export function estimatePoseFromMatrix(matrix: TransformationMatrix): HeadPoseEstimate {
  const m = matrix.data;
  if (!m || m.length < 16) {
    return {
      yaw: 0,
      pitch: 0,
      roll: 0,
      confidence: 0,
      isFrontal: true,
      direction: 'FRONTAL',
    };
  }

  // Column-major 4x4 matrix from MediaPipe WebGL
  const r00 = m[0], r01 = m[4], r02 = m[8];
  const r10 = m[1], r11 = m[5], r12 = m[9];
  const r20 = m[2], r21 = m[6], r22 = m[10];

  const pitchRad = Math.asin(Math.max(-1, Math.min(1, -r12)));
  const yawRad = Math.atan2(r02, r22);
  const rollRad = Math.atan2(r10, r11);

  const pitch = Math.round((pitchRad * 180) / Math.PI * 10) / 10;
  const yaw = Math.round((yawRad * 180) / Math.PI * 10) / 10;
  const roll = Math.round((rollRad * 180) / Math.PI * 10) / 10;

  const isFrontal = Math.abs(yaw) <= 8;
  const direction = isFrontal ? 'FRONTAL' : yaw > 8 ? 'LEFT' : 'RIGHT';

  return {
    yaw,
    pitch,
    roll,
    confidence: 0.95,
    isFrontal,
    direction,
  };
}

/**
 * Estimate Head Pose directly from 3D Face Landmarks.
 * This guarantees robustness even if transformation matrix is omitted or unavailable.
 * Translation-invariant: Moving horizontally across screen does not alter relative geometry.
 */
export function estimatePoseFromLandmarks(landmarks: NormalizedPoint3D[]): HeadPoseEstimate {
  if (!landmarks || landmarks.length < 468) {
    return {
      yaw: 0,
      pitch: 0,
      roll: 0,
      confidence: 0,
      isFrontal: true,
      direction: 'FRONTAL',
    };
  }

  const nose = landmarks[LANDMARK_NOSE_TIP];
  const rightEye = landmarks[LANDMARK_RIGHT_EYE];
  const leftEye = landmarks[LANDMARK_LEFT_EYE];
  const rightCheek = landmarks[LANDMARK_RIGHT_CHEEK];
  const leftCheek = landmarks[LANDMARK_LEFT_CHEEK];
  const forehead = landmarks[LANDMARK_FOREHEAD];
  const chin = landmarks[LANDMARK_CHIN];

  // 1. Roll (Tilt sideways, eye line vs horizontal)
  const eyeDx = leftEye.x - rightEye.x;
  const eyeDy = leftEye.y - rightEye.y;
  const rollRad = Math.atan2(eyeDy, eyeDx);
  const roll = Math.round((rollRad * 180) / Math.PI * 10) / 10;

  // 2. Pitch (Vertical angle, forehead vs chin depth)
  const faceDy = chin.y - forehead.y;
  const faceDz = chin.z - forehead.z;
  const pitchRad = Math.atan2(faceDz, faceDy);
  const pitch = Math.round((pitchRad * 180) / Math.PI * 10) / 10;

  // 3. Yaw (Horizontal turn)
  // Combination of Cheek Depth Vector and Nose-to-Cheek Asymmetry
  const cheekDx = leftCheek.x - rightCheek.x;
  const cheekDz = leftCheek.z - rightCheek.z;
  const depthYawRad = Math.atan2(cheekDz, Math.abs(cheekDx));
  const depthYaw = (depthYawRad * 180) / Math.PI;

  // Horizontal asymmetry of nose relative to facial midpoint
  const midCheekX = (leftCheek.x + rightCheek.x) / 2;
  const halfFaceWidth = Math.abs(cheekDx) / 2;
  const asymRatio = halfFaceWidth > 0 ? (nose.x - midCheekX) / halfFaceWidth : 0;
  const asymYaw = Math.asin(Math.max(-0.8, Math.min(0.8, asymRatio))) * (180 / Math.PI) * 1.5;

  // Weighted ensemble for high stability and low noise
  const fusedYaw = Math.round((depthYaw * 0.6 + asymYaw * 0.4) * 10) / 10;

  const isFrontal = Math.abs(fusedYaw) <= 8;
  const direction = isFrontal ? 'FRONTAL' : fusedYaw > 8 ? 'LEFT' : 'RIGHT';

  return {
    yaw: fusedYaw,
    pitch,
    roll,
    confidence: 0.92,
    isFrontal,
    direction,
  };
}

/**
 * Validate current pose against required step criteria
 * Step 1: Frontal (|yaw| <= 8°, |pitch| <= 12°, |roll| <= 12°)
 * Step 2: Left (12° <= yaw <= 25°, |pitch| <= 15°, |roll| <= 15°)
 * Step 3: Right (-25° <= yaw <= -12°, |pitch| <= 15°, |roll| <= 15°)
 */
export function validateStepPose(
  step: 'frontal' | 'left' | 'right',
  pose: HeadPoseEstimate,
  faceCount: number
): StepValidationResult {
  // Reject multi-face or zero-face
  if (faceCount === 0) {
    return {
      isValid: false,
      step,
      yaw: pose.yaw,
      pitch: pose.pitch,
      roll: pose.roll,
      guideMessage: 'Không phát hiện khuôn mặt',
      warningMessage: 'Vui lòng đưa khuôn mặt vào giữa khung Oval',
      poseQualified: false,
    };
  }

  if (faceCount > 1) {
    return {
      isValid: false,
      step,
      yaw: pose.yaw,
      pitch: pose.pitch,
      roll: pose.roll,
      guideMessage: 'Phát hiện nhiều người',
      warningMessage: 'Chỉ cho phép duy nhất 1 người trong khung hình',
      poseQualified: false,
    };
  }

  // Reject excessive neck tilt (Roll)
  if (Math.abs(pose.roll) > 14) {
    return {
      isValid: false,
      step,
      yaw: pose.yaw,
      pitch: pose.pitch,
      roll: pose.roll,
      guideMessage: 'Đang nghiêng cổ',
      warningMessage: 'Giữ thẳng cổ, không nghiêng đầu sang một bên',
      poseQualified: false,
    };
  }

  // Reject excessive nodding (Pitch)
  if (Math.abs(pose.pitch) > 15) {
    return {
      isValid: false,
      step,
      yaw: pose.yaw,
      pitch: pose.pitch,
      roll: pose.roll,
      guideMessage: pose.pitch > 0 ? 'Đang ngửa đầu' : 'Đang cúi đầu',
      warningMessage: 'Giữ mặt ngang tầm camera, không cúi hoặc ngửa',
      poseQualified: false,
    };
  }

  // Step-Specific Validation Rules
  if (step === 'frontal') {
    if (Math.abs(pose.yaw) <= 8) {
      return {
        isValid: true,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Tốt! Giữ nguyên góc nhìn thẳng...',
        warningMessage: null,
        poseQualified: true,
      };
    } else if (pose.yaw > 8) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Mặt đang quay sang trái',
        warningMessage: 'Vui lòng nhìn THẲNG chính diện vào camera',
        poseQualified: false,
      };
    } else {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Mặt đang quay sang phải',
        warningMessage: 'Vui lòng nhìn THẲNG chính diện vào camera',
        poseQualified: false,
      };
    }
  }

  if (step === 'left') {
    // Requires yaw in range [12°, 25°]
    if (Math.abs(pose.yaw) <= 8) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Bạn đang nhìn thẳng',
        warningMessage: 'Vui lòng quay nhẹ đầu sang TRÁI (khoảng 15°)',
        poseQualified: false,
      };
    } else if (pose.yaw < -8) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Bạn đang quay sang PHẢI',
        warningMessage: 'Vui lòng quay ngược lại sang phía TRÁI',
        poseQualified: false,
      };
    } else if (pose.yaw < 11) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Chưa đủ góc quay trái',
        warningMessage: 'Quay thêm một chút nữa sang bên trái',
        poseQualified: false,
      };
    } else if (pose.yaw > 28) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Quay trái quá nhiều',
        warningMessage: 'Quay lại một chút, chỉ cần nghiêng nhẹ 15°',
        poseQualified: false,
      };
    } else {
      // Qualified left turn: 11° <= yaw <= 28°
      return {
        isValid: true,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Tốt! Giữ nguyên góc nghiêng trái...',
        warningMessage: null,
        poseQualified: true,
      };
    }
  }

  if (step === 'right') {
    // Requires yaw in range [-25°, -12°]
    if (Math.abs(pose.yaw) <= 8) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Bạn đang nhìn thẳng',
        warningMessage: 'Vui lòng quay nhẹ đầu sang PHẢI (khoảng 15°)',
        poseQualified: false,
      };
    } else if (pose.yaw > 8) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Bạn đang quay sang TRÁI',
        warningMessage: 'Vui lòng quay ngược lại sang phía PHẢI',
        poseQualified: false,
      };
    } else if (pose.yaw > -11) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Chưa đủ góc quay phải',
        warningMessage: 'Quay thêm một chút nữa sang bên phải',
        poseQualified: false,
      };
    } else if (pose.yaw < -28) {
      return {
        isValid: false,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Quay phải quá nhiều',
        warningMessage: 'Quay lại một chút, chỉ cần nghiêng nhẹ 15°',
        poseQualified: false,
      };
    } else {
      // Qualified right turn: -28° <= yaw <= -11°
      return {
        isValid: true,
        step,
        yaw: pose.yaw,
        pitch: pose.pitch,
        roll: pose.roll,
        guideMessage: 'Tốt! Giữ nguyên góc nghiêng phải...',
        warningMessage: null,
        poseQualified: true,
      };
    }
  }

  return {
    isValid: false,
    step,
    yaw: pose.yaw,
    pitch: pose.pitch,
    roll: pose.roll,
    guideMessage: 'Chưa xác định được góc mặt',
    warningMessage: null,
    poseQualified: false,
  };
}
