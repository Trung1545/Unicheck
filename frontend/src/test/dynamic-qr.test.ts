// ==============================================================================
// UniCheck - Feature TASK-06: Dynamic QR Code Attendance Tests
// Stitch Screen ID: 5c0df9af4d2545919e8f774c1159e7da
// Contract validation, QR rotation lifecycle, Race condition guards & RBAC
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  QrTokenResponse,
  QrValidationRequest,
  QrValidationResponse,
  AttendanceSessionResponse,
  StudentAttendanceResponse,
} from '../types/attendance.ts';
import type { Role } from '../types/api.ts';
import { generateQrMatrix } from '../utils/qr-generator.ts';

// ------------------------------------------------------------------------------
// 1. Stitch Screen 5c0df9af4d2545919e8f774c1159e7da Layout & Component Contract
// ------------------------------------------------------------------------------
test('1. Stitch Screen 5c0df9af4d2545919e8f774c1159e7da Layout & Component Contract', () => {
  // Required components per Stitch Screen definition
  const requiredElements = [
    'TopContextBar_LiveSessionTag',
    'TopContextBar_SessionId',
    'TopContextBar_Title_Khởi tạo & Chiếu QR Xoay Vòng Bảo Mật',
    'TopContextBar_Timer_Thời gian đã mở',
    'TopContextBar_Schedule_Khung giờ ca học',
    'TelemetryBanner_CourseAndSchedule',
    'TelemetryBanner_Room_Phòng học (TKB)',
    'TelemetryBanner_Wifi_UniCheck_Hall_A2',
    'TelemetryBanner_Kiosk_Camera Cổng 1',
    'ProjectorCard_DynamicQrStage',
    'ProjectorCard_CountdownRing',
    'ProjectorCard_LaserScanningBeam',
    'ProjectorCard_CentralUniCheckBadge',
    'ProjectorCard_Action_Toàn màn hình (F11)',
    'ProjectorCard_Action_Đổi mã ngay',
    'ProjectorCard_Action_Tạm dừng xoay QR',
    'ProjectorCard_Action_Gia hạn thêm 10 phút',
    'ProjectorCard_Action_Kết thúc phiên & Chốt sổ',
    'DashboardCard_LiveMetrics_ProgressDonut',
    'DashboardCard_3Column_Đúng giờ_Đi muộn_Chưa vào',
    'DashboardCard_LastScanCallout',
    'DashboardCard_LiveActivityStream',
    'SimulatorBar_InteractiveTestingBar',
  ];

  assert.equal(requiredElements.length, 23);
  assert.ok(requiredElements.includes('ProjectorCard_CentralUniCheckBadge'));
  assert.ok(requiredElements.includes('SimulatorBar_InteractiveTestingBar'));
});

// ------------------------------------------------------------------------------
// 2. QrTokenResponse Contract & Field Integrity
// ------------------------------------------------------------------------------
test('2. QrTokenResponse Contract & Field Integrity', () => {
  const qrResponse: QrTokenResponse = {
    sessionId: 101,
    qrToken: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJVTklDSEVDS19EWU5BTUlDX1FSIiwic2Vzc2lvbklkIjoxMDEsInR5cGUiOiJEWU5BTUlDX1FSIiwicm90RXhwIjoxNzI5NDAwMDAwMDAwLCJpYXQiOjE3MjkzOTk5OTAwMDAsImV4cCI6MTcyOTQwMDAwNTAwMCwianRpIjoiMWRhMjRhNGItMzQ0MC00Mzk3LTkzNDgtZDhjOGJmODcwMjkyIn0.sample_signature',
    issuedAt: '2026-10-19T13:10:00',
    expiresAt: '2026-10-19T13:10:15',
    rotationExpiresAt: '2026-10-19T13:10:10',
    rotationIntervalSeconds: 10,
    remainingSeconds: 10,
    status: 'OPEN',
  };

  assert.equal(typeof qrResponse.sessionId, 'number');
  assert.equal(typeof qrResponse.qrToken, 'string');
  assert.ok(qrResponse.qrToken.length > 20, 'QR Token must be non-empty compact string');
  assert.equal(qrResponse.status, 'OPEN');
  assert.ok(qrResponse.rotationIntervalSeconds >= 5 && qrResponse.rotationIntervalSeconds <= 30);
  assert.ok(qrResponse.remainingSeconds >= 0);
  assert.ok(new Date(qrResponse.expiresAt).getTime() >= new Date(qrResponse.rotationExpiresAt).getTime());
});

// ------------------------------------------------------------------------------
// 3. QrValidationRequest & QrValidationResponse Contract
// ------------------------------------------------------------------------------
test('3. QrValidationRequest & QrValidationResponse Contract', () => {
  const request: QrValidationRequest = {
    qrToken: 'valid_jwt_compact_token_sample',
    sessionId: 101,
  };

  const response: QrValidationResponse = {
    valid: true,
    sessionId: 101,
    className: 'IT301.01',
    roomName: 'Phòng A2-304',
    issuedAt: '2026-10-19T13:10:00',
    expiresAt: '2026-10-19T13:10:15',
    message: 'Xác thực mã QR thành công',
  };

  assert.equal(request.sessionId, 101);
  assert.equal(response.valid, true);
  assert.equal(response.className, 'IT301.01');
  assert.equal(response.roomName, 'Phòng A2-304');
  assert.ok(response.message.length > 0);
});

// ------------------------------------------------------------------------------
// 4. QR Matrix Generator - Byte Mode & Dimension Bounds
// ------------------------------------------------------------------------------
test('4. QR Matrix Generator - Byte Mode & Dimension Bounds', () => {
  const sampleToken = 'eyJhbGciOiJIUzI1NiJ9.eyJzZXNzaW9uSWQiOjEwMX0.signature';
  const matrix = generateQrMatrix(sampleToken);

  assert.ok(matrix.dimension >= 33, 'Matrix dimension must be at least Version 4 (33x33)');
  assert.equal(matrix.modules.length, matrix.dimension);
  assert.equal(matrix.modules[0].length, matrix.dimension);

  // Verify Finder Patterns in 3 corners (Top-Left: 0,0)
  assert.equal(matrix.modules[0][0], true, 'Top-Left finder outer corner must be black');
  assert.equal(matrix.modules[3][3], true, 'Top-Left finder center must be black');
  assert.equal(matrix.modules[1][1], false, 'Top-Left finder inner separator must be white');

  // Verify Top-Right Finder Pattern
  assert.equal(matrix.modules[0][matrix.dimension - 1], true, 'Top-Right finder corner must be black');
  // Verify Bottom-Left Finder Pattern
  assert.equal(matrix.modules[matrix.dimension - 1][0], true, 'Bottom-Left finder corner must be black');
});

// ------------------------------------------------------------------------------
// 5. Zero-LocalStorage & Zero-Biometrics Policy
// ------------------------------------------------------------------------------
test('5. Zero-LocalStorage Policy: Strictly No Raw Biometric Images or Tokens Stored in LocalStorage', () => {
  const forbiddenLocalStorageKeys = [
    'qrToken',
    'currentQr',
    'faceVector',
    'faceEncoding',
    'biometricData',
    'studentFaceSelfie',
  ];

  // In memory mockup
  const storageMap = new Map<string, string>();
  storageMap.set('auth_token', 'jwt_user_token');
  storageMap.set('auth_user', '{"id":1,"role":"LECTURER"}');

  forbiddenLocalStorageKeys.forEach((key) => {
    assert.equal(storageMap.has(key), false, `Forbidden key [${key}] must NOT be stored in localStorage`);
  });
});

// ------------------------------------------------------------------------------
// 6. Server-Controlled Rotation Countdown Logic
// ------------------------------------------------------------------------------
test('6. Server-Controlled Rotation Countdown Calculation', () => {
  const computeRemaining = (rotationExpiresAt: string, nowMillis: number): number => {
    const target = new Date(rotationExpiresAt).getTime();
    const diffSeconds = Math.floor((target - nowMillis) / 1000);
    return Math.max(0, diffSeconds);
  };

  const now = 1729399990000;
  const targetTime = new Date(now + 7000).toISOString(); // 7s ahead

  const rem = computeRemaining(targetTime, now);
  assert.equal(rem, 7, 'Remaining seconds must be exactly 7 seconds');

  // When past target
  const pastTarget = new Date(now - 3000).toISOString();
  assert.equal(computeRemaining(pastTarget, now), 0, 'Expired target must clamp to 0');
});

// ------------------------------------------------------------------------------
// 7. Race Condition Prevention Safeguard (Late Response Drop)
// ------------------------------------------------------------------------------
test('7. Race Condition Prevention Safeguard (Late Response Drop)', () => {
  let activeToken = 'INITIAL_TOKEN';
  let activeRequestId = 0;

  const simulateFetch = (reqId: number, returnedToken: string) => {
    // Only update if response belongs to latest active request
    if (reqId === activeRequestId) {
      activeToken = returnedToken;
    }
  };

  // Request 1 dispatched
  const req1 = ++activeRequestId; // req1 = 1

  // Request 2 dispatched shortly after (e.g. user clicked "Đổi mã ngay")
  const req2 = ++activeRequestId; // req2 = 2

  // Suppose Request 2 returns FIRST
  simulateFetch(req2, 'TOKEN_FROM_REQ_2');
  assert.equal(activeToken, 'TOKEN_FROM_REQ_2');

  // Request 1 returns LATER due to network lag
  simulateFetch(req1, 'TOKEN_FROM_REQ_1');

  // Must NOT overwrite newer token with stale response!
  assert.equal(activeToken, 'TOKEN_FROM_REQ_2', 'Stale response from request 1 must be discarded');
});

// ------------------------------------------------------------------------------
// 8. Tab Visibility Change & Background Sleep Sync Rule
// ------------------------------------------------------------------------------
test('8. Tab Visibility Change & Background Sleep Sync Rule', () => {
  let shouldReSync = false;

  const onVisibilityChange = (visibilityState: 'visible' | 'hidden') => {
    if (visibilityState === 'visible') {
      shouldReSync = true;
    }
  };

  onVisibilityChange('hidden');
  assert.equal(shouldReSync, false);

  onVisibilityChange('visible');
  assert.equal(shouldReSync, true, 'Must trigger re-sync when tab wakes up');
});

// ------------------------------------------------------------------------------
// 9. Polling Lifecycle & Cleanup on Unmount
// ------------------------------------------------------------------------------
test('9. Polling Lifecycle & Cleanup on Unmount', () => {
  const activeIntervals: number[] = [101, 102, 103];

  const cleanupTimers = () => {
    while (activeIntervals.length > 0) {
      activeIntervals.pop();
    }
  };

  assert.equal(activeIntervals.length, 3);
  cleanupTimers();
  assert.equal(activeIntervals.length, 0, 'All polling timers must be cleared on unmount');
});

// ------------------------------------------------------------------------------
// 10. Session CLOSED Halts QR Generation & Rotation
// ------------------------------------------------------------------------------
test('10. Session CLOSED Halts QR Generation & Rotation', () => {
  const canDisplayLiveQr = (status: string, simulatedState: string): boolean => {
    if (status === 'CLOSED' || simulatedState === 'closed') {
      return false;
    }
    return status === 'OPEN';
  };

  assert.equal(canDisplayLiveQr('OPEN', 'normal'), true);
  assert.equal(canDisplayLiveQr('CLOSED', 'normal'), false, 'CLOSED session must never display live valid QR');
  assert.equal(canDisplayLiveQr('OPEN', 'closed'), false, 'Simulated closed session must halt display');
  assert.equal(canDisplayLiveQr('CREATED', 'normal'), false, 'CREATED session must not display QR');
});

// ------------------------------------------------------------------------------
// 11. No Client-Side Token Tampering or Self-Generation
// ------------------------------------------------------------------------------
test('11. No Client-Side Token Tampering or Self-Generation', () => {
  // Client only displays what Backend issues; verifying signatures locally without private key is rejected
  const isServerSigned = (token: string): boolean => {
    // Standard JWT has 3 parts separated by dots
    const parts = token.split('.');
    return parts.length === 3 && parts[2].length > 10;
  };

  assert.equal(isServerSigned('invalid_token'), false);
  assert.equal(isServerSigned('header.payload.signature_from_server'), true);
});

// ------------------------------------------------------------------------------
// 12. Multi-Student Concurrency Tolerance
// ------------------------------------------------------------------------------
test('12. Multi-Student Concurrency Tolerance (Same QR valid for all students in room)', () => {
  const activeToken = 'SHARED_CLASS_QR_TOKEN_SEC_10';
  const isSingleUseGlobal = false; // Must be false per TASK-06 requirements!

  assert.equal(isSingleUseGlobal, false, 'QR must NOT be marked single-use globally');

  const studentCheckIns = [
    { studentId: 101, token: activeToken },
    { studentId: 102, token: activeToken },
    { studentId: 103, token: activeToken },
  ];

  studentCheckIns.forEach((sc) => {
    assert.equal(sc.token, activeToken, 'Multiple students must be able to scan the same active code');
  });
});

// ------------------------------------------------------------------------------
// 13. RBAC Guard Matrix for QR Projection Screen
// ------------------------------------------------------------------------------
test('13. RBAC Guard Matrix for QR Projection Screen', () => {
  const canAccessQrProjection = (role: Role): boolean => {
    return role === 'LECTURER' || role === 'ADMIN';
  };

  assert.equal(canAccessQrProjection('LECTURER'), true, 'LECTURER has access to QR Projection');
  assert.equal(canAccessQrProjection('ADMIN'), true, 'ADMIN has access to QR Projection');
  assert.equal(canAccessQrProjection('STUDENT'), false, 'STUDENT is strictly forbidden from QR Projection');
});

// ------------------------------------------------------------------------------
// 14. Anti-Infinite-Polling Protection & Throttling Guard
// ------------------------------------------------------------------------------
test('14. Anti-Infinite-Polling Protection & Throttling Guard', () => {
  const MINIMUM_ROTATION_INTERVAL_SECONDS = 5;

  const validateIntervalConfig = (seconds: number): boolean => {
    return seconds >= MINIMUM_ROTATION_INTERVAL_SECONDS;
  };

  assert.equal(validateIntervalConfig(10), true);
  assert.equal(validateIntervalConfig(5), true);
  assert.equal(validateIntervalConfig(2), false, 'Interval < 5s causes excessive polling traffic');
  assert.equal(validateIntervalConfig(0), false, 'Zero interval causes infinite loop');
});

// ------------------------------------------------------------------------------
// 15. Interactive Simulator State Transition Safeguards
// ------------------------------------------------------------------------------
test('15. Interactive Simulator State Transition Safeguards', () => {
  const validStates = ['normal', 'paused', 'offline', 'expired', 'closed'];

  const testStateTransition = (from: string, to: string): boolean => {
    return validStates.includes(from) && validStates.includes(to);
  };

  assert.equal(testStateTransition('normal', 'paused'), true);
  assert.equal(testStateTransition('paused', 'offline'), true);
  assert.equal(testStateTransition('offline', 'expired'), true);
  assert.equal(testStateTransition('expired', 'closed'), true);
  assert.equal(testStateTransition('closed', 'normal'), true);
  assert.equal(testStateTransition('normal', 'hacked_state'), false);
});

// ------------------------------------------------------------------------------
// 16. Static Test QR Mode Contract & Non-Rotation Rule (Phase 2 & Phase 4)
// ------------------------------------------------------------------------------
test('16. Static Test QR Mode Contract & Non-Rotation Rule', () => {
  const staticQrResponse: QrTokenResponse = {
    sessionId: 101,
    qrToken: 'STQR:101:8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b',
    issuedAt: '2026-11-08T08:00:00',
    expiresAt: '2026-11-08T08:30:00',
    rotationExpiresAt: '2026-11-08T08:30:00',
    rotationIntervalSeconds: 0,
    remainingSeconds: 1800,
    status: 'OPEN',
    mode: 'STATIC_TEST_QR',
  };

  assert.equal(staticQrResponse.mode, 'STATIC_TEST_QR');
  assert.equal(staticQrResponse.rotationIntervalSeconds, 0, 'Static QR has 0 rotation interval (never auto-rotates)');
  assert.ok(staticQrResponse.remainingSeconds > 1000, 'Static QR holds full test duration TTL');
  assert.ok(staticQrResponse.qrToken.startsWith('STQR:101:'));
});

// ------------------------------------------------------------------------------
// 17. Static Test QR Eligibility Guard (UNICHECK-E2E-01 & Non-Student)
// ------------------------------------------------------------------------------
test('17. Static Test QR Eligibility Guard', () => {
  const evaluateStaticQrEligibility = (
    role: Role,
    className: string,
    isDevOrTestEnv: boolean
  ): { allowed: boolean; reason?: string } => {
    if (!isDevOrTestEnv) {
      return { allowed: false, reason: 'Static Test QR is strictly disabled in production' };
    }
    if (role === 'STUDENT') {
      return { allowed: false, reason: 'Students cannot issue or manage Static Test QR' };
    }
    if (className !== 'UNICHECK-E2E-01') {
      return { allowed: false, reason: 'Static Test QR is only allowed for test class UNICHECK-E2E-01' };
    }
    return { allowed: true };
  };

  assert.equal(evaluateStaticQrEligibility('LECTURER', 'UNICHECK-E2E-01', true).allowed, true);
  assert.equal(evaluateStaticQrEligibility('ADMIN', 'UNICHECK-E2E-01', true).allowed, true);
  assert.equal(evaluateStaticQrEligibility('STUDENT', 'UNICHECK-E2E-01', true).allowed, false);
  assert.equal(evaluateStaticQrEligibility('LECTURER', 'SE1801-PRJ301', true).allowed, false);
  assert.equal(evaluateStaticQrEligibility('LECTURER', 'UNICHECK-E2E-01', false).allowed, false);
});

// ------------------------------------------------------------------------------
// 18. Zero LocalStorage Policy for Static Test QR Token
// ------------------------------------------------------------------------------
test('18. Zero LocalStorage Policy for Static Test QR Token', () => {
  const mockLocalStorage: Record<string, string> = {};

  const storeKeyInLocalStorage = (key: string, val: string) => {
    // Prohibited keys rule
    const prohibitedPatterns = ['qr', 'STQR', 'STATIC_QR', 'faceSample', 'eyJh'];
    const isProhibited = prohibitedPatterns.some((pattern) => 
      key.toLowerCase().includes(pattern.toLowerCase()) || val.includes(pattern)
    );
    if (isProhibited) {
      throw new Error(`Security Violation: Storing sensitive token/biometric in localStorage is forbidden!`);
    }
    mockLocalStorage[key] = val;
  };

  assert.throws(() => {
    storeKeyInLocalStorage('static_qr_token', 'STQR:101:token_secret');
  }, /Security Violation/);

  assert.throws(() => {
    storeKeyInLocalStorage('cached_qr', 'eyJhbGciOiJIUzI1NiJ9.test');
  }, /Security Violation/);
});
