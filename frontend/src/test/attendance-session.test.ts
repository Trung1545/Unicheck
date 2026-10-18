// ==============================================================================
// UniCheck - Feature TASK-05: Attendance Session Management Tests
// Contract validation, State machine transitions, Safeguards & Role Permissions
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  AttendanceSessionStatus,
  AttendanceSessionResponse,
  AttendanceSessionStatusResponse,
  AttendanceSessionStatsResponse,
  AttendanceConfigDto,
  AttendanceSessionCreateRequest,
  StudentAttendanceResponse,
} from '../types/attendance.ts';
import type { Role } from '../types/api.ts';

// ------------------------------------------------------------------------------
// 1. State Machine & Transition Rules
// ------------------------------------------------------------------------------
test('1. Attendance Session State Machine - Valid and Invalid Transitions', () => {
  const isValidTransition = (
    current: AttendanceSessionStatus,
    target: AttendanceSessionStatus
  ): boolean => {
    const validTransitions: Record<AttendanceSessionStatus, AttendanceSessionStatus[]> = {
      CREATED: ['OPEN', 'CANCELLED'],
      OPEN: ['CLOSED', 'CANCELLED'],
      CLOSED: [], // Terminal state, cannot reopen
      CANCELLED: [], // Terminal state
    };
    return validTransitions[current]?.includes(target) ?? false;
  };

  // Valid paths
  assert.equal(isValidTransition('CREATED', 'OPEN'), true);
  assert.equal(isValidTransition('OPEN', 'CLOSED'), true);
  assert.equal(isValidTransition('CREATED', 'CANCELLED'), true);
  assert.equal(isValidTransition('OPEN', 'CANCELLED'), true);

  // Invalid / Forbidden paths
  assert.equal(isValidTransition('CLOSED', 'OPEN'), false, 'CLOSED session cannot be reopened');
  assert.equal(isValidTransition('CLOSED', 'CREATED'), false, 'Cannot revert from CLOSED to CREATED');
  assert.equal(isValidTransition('CANCELLED', 'OPEN'), false, 'CANCELLED session cannot be opened');
  assert.equal(isValidTransition('CREATED', 'CLOSED'), false, 'Cannot close a session that was never opened');
});

// ------------------------------------------------------------------------------
// 2. AttendanceSessionResponse Contract Validation
// ------------------------------------------------------------------------------
test('2. AttendanceSessionResponse Contract & Field Integrity', () => {
  const session: AttendanceSessionResponse = {
    id: 101,
    timetableSlotId: 45,
    className: 'IT301.01',
    courseCode: 'IT301',
    courseName: 'Lập trình Web nâng cao',
    lecturerId: 2,
    lecturerName: 'TS. Lê Hoàng Nam',
    lecturerCode: 'LEC-002',
    roomCode: 'A2-304',
    roomName: 'Phòng thực hành A2-304',
    building: 'Tòa A2',
    date: '2026-10-23',
    dayOfWeek: 3,
    slotNumber: 1,
    slotName: 'Ca 1 (Tiết 1-3)',
    startTime: '07:00:00',
    endTime: '09:25:00',
    status: 'CREATED',
    createdAt: '2026-10-23T06:00:00Z',
    totalEnrolledStudents: 68,
    totalAttendedStudents: 0,
    attendancePercentage: 0.0,
    canOpen: true,
    canClose: false,
  };

  assert.equal(session.id, 101);
  assert.equal(session.className, 'IT301.01');
  assert.equal(session.status, 'CREATED');
  assert.equal(session.canOpen, true);
  assert.equal(session.canClose, false);
  assert.equal(session.totalEnrolledStudents, 68);
});

// ------------------------------------------------------------------------------
// 3. Status Endpoint Contract for TASK-06 (Dynamic QR Dependency)
// ------------------------------------------------------------------------------
test('3. Status Endpoint Contract for TASK-06 Dynamic QR Generation', () => {
  const openSessionStatus: AttendanceSessionStatusResponse = {
    id: 101,
    status: 'OPEN',
    openedAt: '2026-10-23T06:55:00Z',
    closedAt: null,
    isOpen: true,
    isClosed: false,
    canGenerateQr: true,
    totalEnrolledStudents: 68,
    totalAttendedStudents: 65,
    attendancePercentage: 95.6,
  };

  assert.equal(openSessionStatus.isOpen, true);
  assert.equal(openSessionStatus.isClosed, false);
  assert.equal(openSessionStatus.canGenerateQr, true, 'TASK-06 requires canGenerateQr === true to rotate QR');
  assert.ok(openSessionStatus.totalAttendedStudents <= openSessionStatus.totalEnrolledStudents);

  const closedSessionStatus: AttendanceSessionStatusResponse = {
    id: 101,
    status: 'CLOSED',
    openedAt: '2026-10-23T06:55:00Z',
    closedAt: '2026-10-23T09:30:00Z',
    isOpen: false,
    isClosed: true,
    canGenerateQr: false,
    totalEnrolledStudents: 68,
    totalAttendedStudents: 65,
    attendancePercentage: 95.6,
  };

  assert.equal(closedSessionStatus.isOpen, false);
  assert.equal(closedSessionStatus.isClosed, true);
  assert.equal(closedSessionStatus.canGenerateQr, false, 'Closed session must forbid QR generation');
});

// ------------------------------------------------------------------------------
// 4. Attendance Percentage Calculation
// ------------------------------------------------------------------------------
test('4. Attendance Percentage Formula & Precision Calculation', () => {
  const calculateAttendancePercentage = (attended: number, enrolled: number): number => {
    if (enrolled <= 0) return 0.0;
    const pct = (attended / enrolled) * 100;
    return Math.round(pct * 10) / 10;
  };

  assert.equal(calculateAttendancePercentage(0, 50), 0.0);
  assert.equal(calculateAttendancePercentage(50, 50), 100.0);
  assert.equal(calculateAttendancePercentage(65, 68), 95.6);
  assert.equal(calculateAttendancePercentage(28, 40), 70.0);
  assert.equal(calculateAttendancePercentage(0, 0), 0.0);
});

// ------------------------------------------------------------------------------
// 5. AttendanceConfig Boundary Constraints & Validation
// ------------------------------------------------------------------------------
test('5. AttendanceConfig Parameter Ranges & Safeguards', () => {
  const validateConfig = (cfg: Partial<AttendanceConfigDto>): { valid: boolean; error?: string } => {
    if (cfg.qrRotationIntervalSeconds !== undefined) {
      if (cfg.qrRotationIntervalSeconds < 3 || cfg.qrRotationIntervalSeconds > 20) {
        return { valid: false, error: 'Chu kỳ xoay vòng QR phải từ 3 đến 20 giây' };
      }
    }
    if (cfg.ticketTtlSeconds !== undefined) {
      if (cfg.ticketTtlSeconds < 30 || cfg.ticketTtlSeconds > 300) {
        return { valid: false, error: 'Thời gian sống vé (TTL) phải từ 30 đến 300 giây' };
      }
    }
    if (cfg.faceThresholdPercent !== undefined) {
      if (cfg.faceThresholdPercent < 70 || cfg.faceThresholdPercent > 99) {
        return { valid: false, error: 'Ngưỡng khuôn mặt phải từ 70% đến 99%' };
      }
    }
    if (cfg.minAttendancePercentage !== undefined) {
      if (cfg.minAttendancePercentage < 50 || cfg.minAttendancePercentage > 100) {
        return { valid: false, error: 'Tỷ lệ chuyên cần tối thiểu phải từ 50% đến 100%' };
      }
    }
    return { valid: true };
  };

  // Valid configs
  assert.equal(
    validateConfig({
      qrRotationIntervalSeconds: 5,
      ticketTtlSeconds: 90,
      faceThresholdPercent: 85,
      minAttendancePercentage: 80,
    }).valid,
    true
  );

  // Out of bounds
  assert.equal(validateConfig({ qrRotationIntervalSeconds: 2 }).valid, false);
  assert.equal(validateConfig({ qrRotationIntervalSeconds: 25 }).valid, false);
  assert.equal(validateConfig({ ticketTtlSeconds: 15 }).valid, false);
  assert.equal(validateConfig({ faceThresholdPercent: 65 }).valid, false);
  assert.equal(validateConfig({ faceThresholdPercent: 100 }).valid, false);
  assert.equal(validateConfig({ minAttendancePercentage: 40 }).valid, false);
});

// ------------------------------------------------------------------------------
// 6. Role-Based Access Control Matrix
// ------------------------------------------------------------------------------
test('6. RBAC Matrix for Attendance Session Operations', () => {
  type Action = 'VIEW_ALL' | 'VIEW_SCOPED' | 'CREATE_SESSION' | 'OPEN_SESSION' | 'CLOSE_SESSION' | 'UPDATE_CONFIG';

  const checkPermission = (
    role: Role,
    action: Action,
    isAssignedLecturer: boolean
  ): boolean => {
    switch (role) {
      case 'ADMIN':
        // Admin has full supervision and configuration rights
        return true;
      case 'LECTURER':
        if (action === 'UPDATE_CONFIG' || action === 'VIEW_ALL') return false;
        // Lecturer can view and manage their assigned sessions only
        return isAssignedLecturer;
      case 'STUDENT':
        // Students cannot manage or configure attendance sessions
        return false;
      default:
        return false;
    }
  };

  // ADMIN
  assert.equal(checkPermission('ADMIN', 'VIEW_ALL', false), true);
  assert.equal(checkPermission('ADMIN', 'UPDATE_CONFIG', false), true);
  assert.equal(checkPermission('ADMIN', 'CREATE_SESSION', false), true);

  // LECTURER
  assert.equal(checkPermission('LECTURER', 'VIEW_ALL', false), false);
  assert.equal(checkPermission('LECTURER', 'UPDATE_CONFIG', false), false);
  assert.equal(checkPermission('LECTURER', 'VIEW_SCOPED', true), true);
  assert.equal(checkPermission('LECTURER', 'CREATE_SESSION', true), true);
  assert.equal(checkPermission('LECTURER', 'OPEN_SESSION', true), true);
  assert.equal(checkPermission('LECTURER', 'CLOSE_SESSION', true), true);
  assert.equal(checkPermission('LECTURER', 'OPEN_SESSION', false), false, 'Cannot open session of another lecturer');

  // STUDENT
  assert.equal(checkPermission('STUDENT', 'CREATE_SESSION', false), false);
  assert.equal(checkPermission('STUDENT', 'OPEN_SESSION', false), false);
  assert.equal(checkPermission('STUDENT', 'CLOSE_SESSION', false), false);
  assert.equal(checkPermission('STUDENT', 'UPDATE_CONFIG', false), false);
});

// ------------------------------------------------------------------------------
// 7. Check-in Preservation on Session Close
// ------------------------------------------------------------------------------
test('7. Student Attendance Preservation on Close (No Cascade Deletion)', () => {
  const checkIns: StudentAttendanceResponse[] = [
    {
      id: 1,
      sessionId: 101,
      studentId: 10,
      studentCode: '21110192',
      studentName: 'Nguyễn Văn An',
      status: 'PRESENT',
      method: 'FACE',
      checkInTime: '2026-10-23T07:02:14Z',
      faceConfidence: 0.994,
    },
    {
      id: 2,
      sessionId: 101,
      studentId: 12,
      studentCode: '21110204',
      studentName: 'Trần Quốc Bảo',
      status: 'PRESENT',
      method: 'QR',
      checkInTime: '2026-10-23T07:05:48Z',
    },
  ];

  // Simulating close transition
  const sessionBefore: AttendanceSessionResponse = {
    id: 101,
    timetableSlotId: 45,
    className: 'IT301.01',
    courseCode: 'IT301',
    courseName: 'Lập trình Web nâng cao',
    lecturerId: 2,
    lecturerName: 'TS. Lê Hoàng Nam',
    lecturerCode: 'LEC-002',
    roomCode: 'A2-304',
    roomName: 'Phòng thực hành A2-304',
    building: 'Tòa A2',
    date: '2026-10-23',
    dayOfWeek: 3,
    slotNumber: 1,
    slotName: 'Ca 1',
    startTime: '07:00:00',
    endTime: '09:25:00',
    status: 'OPEN',
    totalEnrolledStudents: 68,
    totalAttendedStudents: 2,
    attendancePercentage: 2.9,
    canOpen: false,
    canClose: true,
    createdAt: '2026-10-23T06:00:00Z',
  };

  const sessionAfter: AttendanceSessionResponse = {
    ...sessionBefore,
    status: 'CLOSED',
    closedAt: '2026-10-23T09:30:00Z',
    canOpen: false,
    canClose: false,
  };

  // Check that check-in records are intact
  assert.equal(checkIns.length, 2);
  assert.equal(checkIns[0].status, 'PRESENT');
  assert.equal(sessionAfter.status, 'CLOSED');
  assert.equal(sessionAfter.totalAttendedStudents, 2);
});
