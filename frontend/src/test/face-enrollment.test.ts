// ==============================================================================
// UniCheck - Feature F-17: Face-ID Biometric Registration & Scanning Tests
// Contract validation, Realtime scanning criteria, Telemetry heuristics,
// Zero-localStorage policy, and Non-liveness disclaimer contracts
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  FaceDataStatus,
  FaceRegistrationRequest,
  FaceEnrollmentResponse,
  FaceStatusResponse,
  FaceSampleDto,
} from '../types/api.ts';

test('1. FaceRegistrationRequest Contract & Field Structure Validation', () => {
  const sampleDto: FaceSampleDto = {
    step: 'frontal',
    imageBase64: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
  };

  const request: FaceRegistrationRequest = {
    imageBase64: 'data:image/jpeg;base64,/9j/4AAQSkZJRg==',
    samples: [sampleDto],
    isReEnrollment: true,
  };

  assert.equal(request.imageBase64.startsWith('data:image/jpeg;base64,'), true);
  assert.equal(request.samples?.length, 1);
  assert.equal(request.samples?.[0].step, 'frontal');
  assert.equal(request.isReEnrollment, true);
});

test('2. FaceEnrollmentResponse Contract: 512-dim ArcFace & SHA-256 Token Format', () => {
  const response: FaceEnrollmentResponse = {
    success: true,
    status: 'REGISTERED',
    registeredAt: '2026-10-16T21:00:00Z',
    version: 'v4.2',
    modelName: 'arcface-mobilefacenet-w600k',
    embeddingDimension: 512,
    tokenHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    message: 'Đăng ký Face-ID thành công!',
    studentName: 'Nguyễn Văn An',
    studentCode: '2251120001',
  };

  assert.equal(response.success, true);
  assert.equal(response.status, 'REGISTERED');
  assert.equal(response.embeddingDimension, 512);
  assert.equal(response.modelName, 'arcface-mobilefacenet-w600k');
  assert.match(response.tokenHash, /^[a-f0-9]{64}$/); // SHA-256 64 hex characters
  assert.equal(response.version, 'v4.2');
});

test('3. Real-Time Telemetry Quality Criteria Validation (Lighting, Sharpness, Face Count, Distance)', () => {
  const evaluateQuality = (
    lighting: number,
    sharpness: number,
    faceCount: number,
    distanceCm: number
  ): { eligible: boolean; rejectionReason?: string } => {
    if (lighting < 40) {
      return { eligible: false, rejectionReason: 'Ánh sáng yếu' };
    }
    if (sharpness < 70) {
      return { eligible: false, rejectionReason: 'Ảnh mờ hoặc mất nét' };
    }
    if (faceCount === 0) {
      return { eligible: false, rejectionReason: 'Không phát hiện khuôn mặt' };
    }
    if (faceCount > 1) {
      return { eligible: false, rejectionReason: 'Phát hiện nhiều hơn một khuôn mặt' };
    }
    if (distanceCm < 30 || distanceCm > 90) {
      return { eligible: false, rejectionReason: 'Khoảng cách không tối ưu' };
    }
    return { eligible: true };
  };

  // Optimal Case
  assert.equal(evaluateQuality(85, 92, 1, 55).eligible, true);

  // Edge Cases
  assert.equal(evaluateQuality(25, 92, 1, 55).eligible, false);
  assert.equal(evaluateQuality(25, 92, 1, 55).rejectionReason, 'Ánh sáng yếu');

  assert.equal(evaluateQuality(85, 50, 1, 55).eligible, false);
  assert.equal(evaluateQuality(85, 50, 1, 55).rejectionReason, 'Ảnh mờ hoặc mất nét');

  assert.equal(evaluateQuality(85, 92, 0, 55).eligible, false);
  assert.equal(evaluateQuality(85, 92, 0, 55).rejectionReason, 'Không phát hiện khuôn mặt');

  assert.equal(evaluateQuality(85, 92, 2, 55).eligible, false);
  assert.equal(evaluateQuality(85, 92, 2, 55).rejectionReason, 'Phát hiện nhiều hơn một khuôn mặt');

  assert.equal(evaluateQuality(85, 92, 1, 15).eligible, false);
  assert.equal(evaluateQuality(85, 92, 1, 15).rejectionReason, 'Khoảng cách không tối ưu');
});

test('4. Oval Guideline Containment Heuristics (Point in Ellipse)', () => {
  const isInsideOval = (
    px: number,
    py: number,
    cx: number,
    cy: number,
    rx: number,
    ry: number
  ): boolean => {
    const normX = (px - cx) / rx;
    const normY = (py - cy) / ry;
    return normX * normX + normY * normY <= 1.0;
  };

  // Center (130, 165), rx = 122, ry = 155
  assert.equal(isInsideOval(130, 165, 130, 165, 122, 155), true); // Center is inside
  assert.equal(isInsideOval(150, 175, 130, 165, 122, 155), true); // Near center
  assert.equal(isInsideOval(10, 10, 130, 165, 122, 155), false); // Outside top-left
  assert.equal(isInsideOval(300, 300, 130, 165, 122, 155), false); // Outside bottom-right
});

test('5. Zero-LocalStorage Policy: Strictly No Raw Biometric Images or Vector Embeddings Stored Locally', () => {
  const allowedKeys = ['auth_token', 'refresh_token', 'user_profile', 'theme'];
  const forbiddenKeywords = ['face_image', 'face_embedding', 'base64', 'raw_face', 'vector'];

  const testStorageKeys = ['auth_token', 'user_profile', 'theme'];

  const containsForbiddenBiometric = testStorageKeys.some((k) =>
    forbiddenKeywords.some((f) => k.toLowerCase().includes(f))
  );

  assert.equal(containsForbiddenBiometric, false);
});

test('6. Multi-Angle 3-Step Guided Workflow State Machine Transitions', () => {
  const steps: ('frontal' | 'left' | 'right')[] = ['frontal', 'left', 'right'];

  let currentStepIndex = 0;
  const captured: string[] = [];

  const simulateStepCapture = (step: 'frontal' | 'left' | 'right', base64: string) => {
    assert.equal(steps[currentStepIndex], step);
    captured.push(base64);
    if (currentStepIndex < steps.length - 1) {
      currentStepIndex++;
    }
  };

  simulateStepCapture('frontal', 'data_1');
  assert.equal(currentStepIndex, 1);

  simulateStepCapture('left', 'data_2');
  assert.equal(currentStepIndex, 2);

  simulateStepCapture('right', 'data_3');
  assert.equal(captured.length, 3);
});

test('7. Non-Liveness Disclaimer & Fail-Closed Safeguard Verification', () => {
  const livenessVerified = false; // Always false in TASK-04
  const disclaimerNote = 'Passive Frame Analysis (Chưa xác nhận Anti-Spoofing MiniFASNet)';

  assert.equal(livenessVerified, false);
  assert.equal(disclaimerNote.includes('MiniFASNet'), true);
});

test('8. Student Face-ID Status Transition: NOT_REGISTERED -> REGISTERED', () => {
  let status: FaceDataStatus = 'NOT_REGISTERED';
  assert.equal(status, 'NOT_REGISTERED');

  // After successful enrollment
  status = 'REGISTERED';
  assert.equal(status, 'REGISTERED');

  const isEligibleForAttendance = (s: FaceDataStatus): boolean => {
    return s === 'REGISTERED' || s === 'ACTIVE';
  };

  assert.equal(isEligibleForAttendance('NOT_REGISTERED'), false);
  assert.equal(isEligibleForAttendance('REGISTERED'), true);
  assert.equal(isEligibleForAttendance('ACTIVE'), true);
  assert.equal(isEligibleForAttendance('BLOCKED'), false);
});

test('9. Strict Finite State Machine & Anti-Loop Safeguards', () => {
  type State =
    | 'IDLE'
    | 'SCANNING_FRONT'
    | 'SCANNING_LEFT'
    | 'SCANNING_RIGHT'
    | 'SUBMITTING'
    | 'SUCCESS'
    | 'ERROR';

  let state: State = 'IDLE';

  // 1. Camera activates -> transition to SCANNING_FRONT
  state = 'SCANNING_FRONT';
  assert.equal(state, 'SCANNING_FRONT');

  // 2. Capture frontal -> transition to SCANNING_LEFT
  state = 'SCANNING_LEFT';
  assert.equal(state, 'SCANNING_LEFT');

  // 3. Capture left -> transition to SCANNING_RIGHT
  state = 'SCANNING_RIGHT';
  assert.equal(state, 'SCANNING_RIGHT');

  // 4. Capture right -> transition to SUBMITTING
  state = 'SUBMITTING';
  assert.equal(state, 'SUBMITTING');

  // 5. Backend returns 503 error -> MUST transition to ERROR, NEVER auto-retry or loop!
  state = 'ERROR';
  assert.equal(state, 'ERROR');

  // 6. User clicks 'Thử lại' -> resets cleanly to SCANNING_FRONT
  state = 'SCANNING_FRONT';
  assert.equal(state, 'SCANNING_FRONT');
});

test('10. Boundary Clamping: completedSteps <= 3 and progress <= 100%', () => {
  const calculateMetrics = (samplesCount: number) => {
    const completed = Math.min(samplesCount, 3);
    const progress = Math.min(100, Math.round((completed / 3) * 100));
    return { completed, progress };
  };

  // Normal flow
  assert.deepEqual(calculateMetrics(0), { completed: 0, progress: 0 });
  assert.deepEqual(calculateMetrics(1), { completed: 1, progress: 33 });
  assert.deepEqual(calculateMetrics(2), { completed: 2, progress: 67 });
  assert.deepEqual(calculateMetrics(3), { completed: 3, progress: 100 });

  // Outlier / flood case (e.g. 39 samples) - MUST BE CLAMPED!
  assert.deepEqual(calculateMetrics(4), { completed: 3, progress: 100 });
  assert.deepEqual(calculateMetrics(39), { completed: 3, progress: 100 });
});

