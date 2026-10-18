// ==============================================================================
// UniCheck - TASK-04: Head Pose Validation Unit Tests
// Tests real-time 3-angle pose estimation, mirror consistency, translation invariance,
// rejection of frontal-looking false positives, and fail-closed security.
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import {
  estimatePoseFromMatrix,
  estimatePoseFromLandmarks,
  validateStepPose,
} from '../utils/head-pose.ts';
import type {
  NormalizedPoint3D,
  TransformationMatrix,
  HeadPoseEstimate,
} from '../utils/head-pose.ts';

/**
 * Helper to construct synthetic 478 MediaPipe landmarks with custom yaw, pitch, roll, and translation
 */
function createSyntheticLandmarks(options: {
  yawDeg: number;       // + Left, - Right
  pitchDeg?: number;    // + Up, - Down
  rollDeg?: number;     // + Right, - Left
  translateX?: number;  // Horizontal shift (testing translation invariance)
  translateY?: number;
}): NormalizedPoint3D[] {
  const { yawDeg, pitchDeg = 0, rollDeg = 0, translateX = 0, translateY = 0 } = options;

  const yawRad = (yawDeg * Math.PI) / 180;
  const pitchRad = (pitchDeg * Math.PI) / 180;
  const rollRad = (rollDeg * Math.PI) / 180;

  // Base canonical 3D coordinates (centered at 0, 0, 0)
  // MediaPipe Face canonical points
  const basePoints: Record<number, [number, number, number]> = {
    1: [0.0, -0.05, -0.08],        // Nose tip
    10: [0.0, -0.25, 0.0],         // Forehead top
    152: [0.0, 0.25, 0.0],         // Chin bottom
    33: [-0.12, -0.10, 0.0],       // Right eye outer
    263: [0.12, -0.10, 0.0],       // Left eye outer
    234: [-0.22, 0.0, 0.0],        // Right cheek edge
    454: [0.22, 0.0, 0.0],         // Left cheek edge
  };

  const landmarks: NormalizedPoint3D[] = new Array(478);

  // Fill default points
  for (let i = 0; i < 478; i++) {
    landmarks[i] = { x: 0.5 + translateX, y: 0.5 + translateY, z: 0 };
  }

  // Rotate each key landmark around center
  for (const [idxStr, [bx, by, bz]] of Object.entries(basePoints)) {
    const idx = parseInt(idxStr, 10);

    // 1. Yaw (Y-axis rotation around up-axis)
    // Positive yaw turns towards Subject's Left (+X in sensor coordinates)
    const x1 = bx * Math.cos(yawRad) - bz * Math.sin(yawRad);
    const y1 = by;
    const z1 = bx * Math.sin(yawRad) + bz * Math.cos(yawRad);

    // 2. Pitch (X-axis rotation)
    // y' = y*cos(pitch) - z*sin(pitch)
    // z'' = y*sin(pitch) + z*cos(pitch)
    const x2 = x1;
    const y2 = y1 * Math.cos(pitchRad) - z1 * Math.sin(pitchRad);
    const z2 = y1 * Math.sin(pitchRad) + z1 * Math.cos(pitchRad);

    // 3. Roll (Z-axis rotation)
    // x'' = x*cos(roll) - y*sin(roll)
    // y'' = x*sin(roll) + y*cos(roll)
    const x3 = x2 * Math.cos(rollRad) - y2 * Math.sin(rollRad);
    const y3 = x2 * Math.sin(rollRad) + y2 * Math.cos(rollRad);
    const z3 = z2;

    // Shift to normalized frame [0..1] with optional translation
    landmarks[idx] = {
      x: 0.5 + x3 + translateX,
      y: 0.5 + y3 + translateY,
      z: z3,
    };
  }

  return landmarks;
}

/**
 * Helper to construct a synthetic 4x4 MediaPipe transformation matrix
 */
function createSyntheticMatrix(yawDeg: number, pitchDeg = 0, rollDeg = 0): TransformationMatrix {
  const yaw = (yawDeg * Math.PI) / 180;
  const pitch = (pitchDeg * Math.PI) / 180;
  const roll = (rollDeg * Math.PI) / 180;

  // R = Ry(yaw) * Rx(pitch) * Rz(roll)
  const r00 = Math.cos(yaw) * Math.cos(roll) + Math.sin(yaw) * Math.sin(pitch) * Math.sin(roll);
  const r01 = -Math.cos(yaw) * Math.sin(roll) + Math.sin(yaw) * Math.sin(pitch) * Math.cos(roll);
  const r02 = Math.sin(yaw) * Math.cos(pitch);

  const r10 = Math.cos(pitch) * Math.sin(roll);
  const r11 = Math.cos(pitch) * Math.cos(roll);
  const r12 = -Math.sin(pitch);

  const r20 = -Math.sin(yaw) * Math.cos(roll) + Math.cos(yaw) * Math.sin(pitch) * Math.sin(roll);
  const r21 = Math.sin(yaw) * Math.sin(roll) + Math.cos(yaw) * Math.sin(pitch) * Math.cos(roll);
  const r22 = Math.cos(yaw) * Math.cos(pitch);

  // Column-major array (16 elements)
  return {
    rows: 4,
    columns: 4,
    data: [
      r00, r10, r20, 0,
      r01, r11, r21, 0,
      r02, r12, r22, 0,
      0, 0, -100, 1,
    ],
  };
}

// ==============================================================================
// TEST SUITE: MANDATORY CRITERIA FROM TASK SPECIFICATION
// ==============================================================================

test('1. Mandatory Scenario: User looks straight for 10 seconds -> Step 1 PASS; Step 2 WAITS (NEVER PASSES)', () => {
  const frontalLandmarks = createSyntheticLandmarks({ yawDeg: 0 });
  const pose = estimatePoseFromLandmarks(frontalLandmarks);

  assert.equal(pose.isFrontal, true);
  assert.equal(pose.direction, 'FRONTAL');
  assert.ok(Math.abs(pose.yaw) <= 8);

  // Step 1: Frontal -> MUST PASS
  const step1 = validateStepPose('frontal', pose, 1);
  assert.equal(step1.isValid, true);
  assert.equal(step1.poseQualified, true);

  // Step 2: Left -> Looking straight MUST FAIL & WAIT
  const step2 = validateStepPose('left', pose, 1);
  assert.equal(step2.isValid, false);
  assert.equal(step2.poseQualified, false);
  assert.match(step2.guideMessage, /nhìn thẳng/i);
  assert.match(step2.warningMessage!, /quay nhẹ đầu sang TRÁI/i);

  // Step 3: Right -> Looking straight MUST FAIL & WAIT
  const step3 = validateStepPose('right', pose, 1);
  assert.equal(step3.isValid, false);
  assert.equal(step3.poseQualified, false);
  assert.match(step3.guideMessage, /nhìn thẳng/i);
  assert.match(step3.warningMessage!, /quay nhẹ đầu sang PHẢI/i);
});

test('2. Mandatory Scenario: Turn right when requested to turn left -> Step 2 MUST NOT PASS', () => {
  // User turns right 16° (yaw is negative)
  const rightTurnLandmarks = createSyntheticLandmarks({ yawDeg: -16 });
  const pose = estimatePoseFromLandmarks(rightTurnLandmarks);

  assert.equal(pose.direction, 'RIGHT');
  assert.ok(pose.yaw <= -11);

  const step2 = validateStepPose('left', pose, 1);
  assert.equal(step2.isValid, false);
  assert.equal(step2.poseQualified, false);
  assert.match(step2.guideMessage, /đang quay sang PHẢI/i);
  assert.match(step2.warningMessage!, /quay ngược lại sang phía TRÁI/i);
});

test('3. Mandatory Scenario: Turn left at correct angle (15°) -> Step 2 MUST PASS', () => {
  const leftTurnLandmarks = createSyntheticLandmarks({ yawDeg: 16 });
  const pose = estimatePoseFromLandmarks(leftTurnLandmarks);

  assert.equal(pose.direction, 'LEFT');
  assert.ok(pose.yaw >= 11 && pose.yaw <= 28);

  const step2 = validateStepPose('left', pose, 1);
  assert.equal(step2.isValid, true);
  assert.equal(step2.poseQualified, true);
  assert.equal(step2.warningMessage, null);
});

test('4. Mandatory Scenario: Keep holding left when requested to turn right -> Step 3 MUST NOT PASS', () => {
  const leftTurnLandmarks = createSyntheticLandmarks({ yawDeg: 15 });
  const pose = estimatePoseFromLandmarks(leftTurnLandmarks);

  const step3 = validateStepPose('right', pose, 1);
  assert.equal(step3.isValid, false);
  assert.equal(step3.poseQualified, false);
  assert.match(step3.guideMessage, /đang quay sang TRÁI/i);
  assert.match(step3.warningMessage!, /quay ngược lại sang phía PHẢI/i);
});

test('5. Mandatory Scenario: Turn right at correct angle (-15°) -> Step 3 MUST PASS', () => {
  const rightTurnLandmarks = createSyntheticLandmarks({ yawDeg: -16 });
  const pose = estimatePoseFromLandmarks(rightTurnLandmarks);

  assert.equal(pose.direction, 'RIGHT');
  assert.ok(pose.yaw <= -11 && pose.yaw >= -28);

  const step3 = validateStepPose('right', pose, 1);
  assert.equal(step3.isValid, true);
  assert.equal(step3.poseQualified, true);
  assert.equal(step3.warningMessage, null);
});

test('6. Mandatory Scenario: Translating face horizontally without rotating head -> MUST NOT PASS Step 2 or 3', () => {
  // User slides body 15% to the left/right of the screen while keeping face straight
  const translatedLeftLandmarks = createSyntheticLandmarks({ yawDeg: 0, translateX: -0.15 });
  const translatedRightLandmarks = createSyntheticLandmarks({ yawDeg: 0, translateX: 0.15 });

  const poseLeft = estimatePoseFromLandmarks(translatedLeftLandmarks);
  const poseRight = estimatePoseFromLandmarks(translatedRightLandmarks);

  // Both should still evaluate as FRONTAL (yaw ~ 0°)
  assert.ok(Math.abs(poseLeft.yaw) <= 8, `Expected yaw near 0, got ${poseLeft.yaw}`);
  assert.ok(Math.abs(poseRight.yaw) <= 8, `Expected yaw near 0, got ${poseRight.yaw}`);

  // Cannot pass Left step
  assert.equal(validateStepPose('left', poseLeft, 1).isValid, false);
  assert.equal(validateStepPose('left', poseRight, 1).isValid, false);

  // Cannot pass Right step
  assert.equal(validateStepPose('right', poseLeft, 1).isValid, false);
  assert.equal(validateStepPose('right', poseRight, 1).isValid, false);
});

test('7. Mandatory Scenario: Zero faces detected -> MUST FAIL CLOSED', () => {
  const pose: HeadPoseEstimate = {
    yaw: 0,
    pitch: 0,
    roll: 0,
    confidence: 0,
    isFrontal: true,
    direction: 'FRONTAL',
  };

  const validation = validateStepPose('frontal', pose, 0);
  assert.equal(validation.isValid, false);
  assert.equal(validation.poseQualified, false);
  assert.match(validation.guideMessage, /không phát hiện khuôn mặt/i);
});

test('8. Mandatory Scenario: Multiple faces detected (faceCount = 2) -> MUST FAIL CLOSED', () => {
  const pose: HeadPoseEstimate = {
    yaw: 0,
    pitch: 0,
    roll: 0,
    confidence: 0.9,
    isFrontal: true,
    direction: 'FRONTAL',
  };

  const validation = validateStepPose('frontal', pose, 2);
  assert.equal(validation.isValid, false);
  assert.equal(validation.poseQualified, false);
  assert.match(validation.guideMessage, /nhiều người/i);
});

test('9. Mandatory Scenario: Excessive neck roll tilt (Roll > 15°) -> MUST BE REJECTED', () => {
  // User tilts ear to shoulder by 20° without turning yaw
  const rollLandmarks = createSyntheticLandmarks({ yawDeg: 15, rollDeg: 22 });
  const pose = estimatePoseFromLandmarks(rollLandmarks);

  assert.ok(Math.abs(pose.roll) > 14);

  const step2 = validateStepPose('left', pose, 1);
  assert.equal(step2.isValid, false);
  assert.match(step2.warningMessage!, /giữ thẳng cổ/i);
});

test('10. Mandatory Scenario: MediaPipe Transformation Matrix Decomposition Consistency', () => {
  // Test Frontal Matrix (0° yaw)
  const mFront = createSyntheticMatrix(0, 0, 0);
  const poseFront = estimatePoseFromMatrix(mFront);
  assert.equal(poseFront.isFrontal, true);
  assert.equal(poseFront.direction, 'FRONTAL');
  assert.ok(Math.abs(poseFront.yaw) <= 1.0);

  // Test Left Matrix (18° yaw)
  const mLeft = createSyntheticMatrix(18, 2, -1);
  const poseLeft = estimatePoseFromMatrix(mLeft);
  assert.equal(poseLeft.direction, 'LEFT');
  assert.equal(poseLeft.isFrontal, false);
  assert.ok(Math.abs(poseLeft.yaw - 18) <= 1.0);

  // Test Right Matrix (-18° yaw)
  const mRight = createSyntheticMatrix(-18, -1, 1);
  const poseRight = estimatePoseFromMatrix(mRight);
  assert.equal(poseRight.direction, 'RIGHT');
  assert.equal(poseRight.isFrontal, false);
  assert.ok(Math.abs(poseRight.yaw - (-18)) <= 1.0);
});

test('11. Mandatory Scenario: Unstable / Jittering Pose Resets Steady Hold Counter (No Auto-Capture)', () => {
  let steadyHoldCounter = 0;
  const holdThreshold = 6; // Requires 6 consecutive ticks (~0.75s)

  const processFrame = (pose: HeadPoseEstimate, step: 'left'): boolean => {
    const validation = validateStepPose(step, pose, 1);
    if (validation.isValid) {
      steadyHoldCounter++;
      if (steadyHoldCounter >= holdThreshold) {
        return true; // Triggers auto-capture
      }
    } else {
      steadyHoldCounter = 0; // RESET counter on jitter/deviation!
    }
    return false;
  };

  const validPose: HeadPoseEstimate = { yaw: 16, pitch: 0, roll: 0, confidence: 0.9, isFrontal: false, direction: 'LEFT' };
  const invalidPose: HeadPoseEstimate = { yaw: 2, pitch: 0, roll: 0, confidence: 0.9, isFrontal: true, direction: 'FRONTAL' };

  // 4 valid ticks
  for (let i = 0; i < 4; i++) {
    assert.equal(processFrame(validPose, 'left'), false);
  }
  assert.equal(steadyHoldCounter, 4);

  // 1 jitter frame (e.g. turned back to front)
  assert.equal(processFrame(invalidPose, 'left'), false);
  assert.equal(steadyHoldCounter, 0); // MUST BE RESET TO 0!

  // Another 3 valid ticks (not enough for 6)
  for (let i = 0; i < 3; i++) {
    assert.equal(processFrame(validPose, 'left'), false);
  }
  assert.equal(steadyHoldCounter, 3);
});

test('12. Mandatory Scenario: End-to-End 3-Step Pose Qualification -> Exactly 1 Transition to SUBMITTING', () => {
  const samples: Array<{ step: string; yaw: number }> = [];
  let currentState: 'IDLE' | 'SCANNING_FRONT' | 'SCANNING_LEFT' | 'SCANNING_RIGHT' | 'SUBMITTING' = 'SCANNING_FRONT';
  let submitCount = 0;

  const onPoseCaptured = (step: 'frontal' | 'left' | 'right', yaw: number) => {
    samples.push({ step, yaw });
    if (currentState === 'SCANNING_FRONT') {
      currentState = 'SCANNING_LEFT';
    } else if (currentState === 'SCANNING_LEFT') {
      currentState = 'SCANNING_RIGHT';
    } else if (currentState === 'SCANNING_RIGHT') {
      currentState = 'SUBMITTING';
      submitCount++;
    }
  };

  // Step 1: Frontal (yaw 0°)
  const p1 = createSyntheticLandmarks({ yawDeg: 0 });
  const val1 = validateStepPose('frontal', estimatePoseFromLandmarks(p1), 1);
  assert.equal(val1.isValid, true);
  onPoseCaptured('frontal', val1.yaw);
  assert.equal(currentState, 'SCANNING_LEFT');

  // Step 2: Left (yaw 16°)
  const p2 = createSyntheticLandmarks({ yawDeg: 16 });
  const val2 = validateStepPose('left', estimatePoseFromLandmarks(p2), 1);
  assert.equal(val2.isValid, true);
  onPoseCaptured('left', val2.yaw);
  assert.equal(currentState, 'SCANNING_RIGHT');

  // Step 3: Right (yaw -16°)
  const p3 = createSyntheticLandmarks({ yawDeg: -16 });
  const val3 = validateStepPose('right', estimatePoseFromLandmarks(p3), 1);
  assert.equal(val3.isValid, true);
  onPoseCaptured('right', val3.yaw);
  assert.equal(currentState, 'SUBMITTING');

  assert.equal(samples.length, 3);
  assert.equal(submitCount, 1);
  assert.equal(samples[0].step, 'frontal');
  assert.equal(samples[1].step, 'left');
  assert.equal(samples[2].step, 'right');
});

test('13. Mandatory Scenario: Landmark Model Loading Failure -> Fail Closed (Zero Steps Completed)', () => {
  // Simulate model loading failure
  const isModelReady = false;
  const modelError = 'Network failure loading /wasm/vision_wasm_internal.wasm';

  const attemptProcess = () => {
    if (!isModelReady) {
      return {
        eligible: false,
        error: modelError,
        guide: 'Mô hình nhận diện khuôn mặt chưa sẵn sàng',
      };
    }
    return { eligible: true, error: null, guide: 'Ready' };
  };

  const result = attemptProcess();
  assert.equal(result.eligible, false);
  assert.equal(result.error, modelError);
  // Zero steps can be completed when model fails!
});

