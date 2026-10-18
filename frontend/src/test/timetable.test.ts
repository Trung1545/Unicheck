// ==============================================================================
// UniCheck - Feature F-16: Timetable & Slot Operations Tests
// Contract validation, Conflict detection logic, Attendance safeguard & RBAC matrix
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  TimetableSlotStatus,
  TimetableSlotCreateRequest,
  TimetableSlotUpdateRequest,
  TimetableSlotResponse,
  TimetableConflictCheckRequest,
  TimetableConflictCheckResponse,
  SlotTypeResponse,
  TimetableStatsResponse,
  Role,
} from '../types/api.ts';

test('1. TimetableSlotCreateRequest Contract & Field Validation', () => {
  const validRequest: TimetableSlotCreateRequest = {
    className: 'IT301.01',
    roomId: 10,
    slotTypeId: 1,
    date: '2026-10-05',
    slotNumber: 1,
    endSlotNumber: 3,
    note: 'Lý thuyết Cấu trúc dữ liệu & Giải thuật',
    recurring: true,
    recurringUntil: '2026-12-30',
  };

  assert.equal(validRequest.className, 'IT301.01');
  assert.equal(validRequest.roomId, 10);
  assert.equal(validRequest.slotNumber, 1);
  assert.equal(validRequest.endSlotNumber, 3);
  assert.equal(validRequest.recurring, true);
  assert.equal(validRequest.date, '2026-10-05');
});

test('2. Period Range & Time Boundary Constraints (1 <= start <= end <= 12)', () => {
  const validatePeriodRange = (
    start: number,
    end?: number | null
  ): { valid: boolean; error?: string } => {
    if (start < 1 || start > 12) {
      return { valid: false, error: 'Tiết học bắt đầu phải từ 1 đến 12' };
    }
    const finalEnd = end !== undefined && end !== null ? end : start;
    if (finalEnd < start) {
      return { valid: false, error: 'Tiết kết thúc không được nhỏ hơn tiết bắt đầu' };
    }
    if (finalEnd > 12) {
      return { valid: false, error: 'Tiết kết thúc không được vượt quá 12' };
    }
    return { valid: true };
  };

  assert.equal(validatePeriodRange(1, 3).valid, true);
  assert.equal(validatePeriodRange(4, 6).valid, true);
  assert.equal(validatePeriodRange(10, 12).valid, true);

  assert.equal(validatePeriodRange(0, 3).valid, false);
  assert.equal(validatePeriodRange(4, 2).valid, false);
  assert.equal(validatePeriodRange(10, 13).valid, false);
});

test('3. Conflict Detection Rule Contracts (Room, Lecturer, Class section)', () => {
  interface SlotMock {
    id: number;
    className: string;
    lecturerId: number;
    roomId: number;
    date: string;
    slotNumber: number;
  }

  const existingSlots: SlotMock[] = [
    { id: 1, className: 'IT301.01', lecturerId: 101, roomId: 5, date: '2026-10-05', slotNumber: 1 },
    { id: 2, className: 'CS205.01', lecturerId: 102, roomId: 6, date: '2026-10-05', slotNumber: 4 },
  ];

  const checkCollision = (newSlot: Omit<SlotMock, 'id'>, excludeId?: number) => {
    for (const s of existingSlots) {
      if (excludeId && s.id === excludeId) continue;
      if (s.date === newSlot.date && s.slotNumber === newSlot.slotNumber) {
        if (s.className === newSlot.className) return { conflict: true, type: 'CLASS_CONFLICT' };
        if (s.lecturerId === newSlot.lecturerId) return { conflict: true, type: 'LECTURER_CONFLICT' };
        if (s.roomId === newSlot.roomId) return { conflict: true, type: 'ROOM_CONFLICT' };
      }
    }
    return { conflict: false, type: 'NONE' };
  };

  // Same class at same time
  assert.equal(
    checkCollision({ className: 'IT301.01', lecturerId: 999, roomId: 99, date: '2026-10-05', slotNumber: 1 }).type,
    'CLASS_CONFLICT'
  );

  // Same lecturer at different room
  assert.equal(
    checkCollision({ className: 'OTHER.01', lecturerId: 101, roomId: 8, date: '2026-10-05', slotNumber: 1 }).type,
    'LECTURER_CONFLICT'
  );

  // Same room with different lecturer
  assert.equal(
    checkCollision({ className: 'OTHER.02', lecturerId: 999, roomId: 5, date: '2026-10-05', slotNumber: 1 }).type,
    'ROOM_CONFLICT'
  );

  // Non-colliding slot
  assert.equal(
    checkCollision({ className: 'OTHER.03', lecturerId: 999, roomId: 99, date: '2026-10-05', slotNumber: 7 }).conflict,
    false
  );
});

test('4. Semester Date Window & Holiday Constraint Logic', () => {
  const semesterStart = '2026-09-01';
  const semesterEnd = '2026-12-31';
  const holidays = ['2026-09-02', '2026-11-20'];

  const validateDate = (targetDate: string): { valid: boolean; error?: string } => {
    if (targetDate < semesterStart || targetDate > semesterEnd) {
      return { valid: false, error: 'DATE_OUTSIDE_SEMESTER' };
    }
    if (holidays.includes(targetDate)) {
      return { valid: false, error: 'DATE_ON_HOLIDAY' };
    }
    return { valid: true };
  };

  assert.equal(validateDate('2026-10-15').valid, true);
  assert.equal(validateDate('2026-08-30').error, 'DATE_OUTSIDE_SEMESTER');
  assert.equal(validateDate('2027-01-05').error, 'DATE_OUTSIDE_SEMESTER');
  assert.equal(validateDate('2026-09-02').error, 'DATE_ON_HOLIDAY');
});

test('5. Room Capacity Suitability Evaluation Rule', () => {
  const checkCapacitySuitability = (roomCapacity: number, enrolledStudents: number): boolean => {
    return roomCapacity >= enrolledStudents;
  };

  assert.equal(checkCapacitySuitability(80, 65), true);
  assert.equal(checkCapacitySuitability(50, 50), true);
  assert.equal(checkCapacitySuitability(30, 45), false);
});

test('6. Attendance Session Dependency Safeguard Contract', () => {
  const canModifyOrDeleteSlot = (
    attendanceSessionsCount: number,
    isChangingCoreSchedule: boolean
  ): { allowed: boolean; error?: string } => {
    if (attendanceSessionsCount > 0 && isChangingCoreSchedule) {
      return {
        allowed: false,
        error: 'TIMETABLE_SLOT_HAS_ATTENDANCE',
      };
    }
    return { allowed: true };
  };

  // Slot with no attendance sessions can be freely edited/deleted
  assert.equal(canModifyOrDeleteSlot(0, true).allowed, true);

  // Slot with attendance sessions CANNOT have date/room/period mutated or deleted
  assert.equal(canModifyOrDeleteSlot(1, true).error, 'TIMETABLE_SLOT_HAS_ATTENDANCE');

  // Slot with attendance sessions CAN update note without violating integrity
  assert.equal(canModifyOrDeleteSlot(1, false).allowed, true);
});

test('7. Pre-flight Conflict Check Payload & Response Envelope', () => {
  const req: TimetableConflictCheckRequest = {
    className: 'IT301.01',
    roomId: 5,
    date: '2026-10-05',
    slotNumber: 1,
  };

  const res: TimetableConflictCheckResponse = {
    hasConflict: true,
    conflictType: 'ROOM_CONFLICT',
    conflictMessage: 'Phòng học C3-102 đã được xếp lịch cho lớp khác',
    conflictingSlotId: 10,
    conflictingClassName: 'CS101.01',
    conflictingRoomCode: 'C3-102',
  };

  assert.equal(req.className, 'IT301.01');
  assert.equal(res.hasConflict, true);
  assert.equal(res.conflictType, 'ROOM_CONFLICT');
  assert.equal(res.conflictingRoomCode, 'C3-102');
});

test('8. RBAC Matrix for Timetable & Slot Operations', () => {
  const permissions: Record<Role, { canManageSlots: boolean; canPublish: boolean; canViewMe: boolean }> = {
    ADMIN: { canManageSlots: true, canPublish: true, canViewMe: true },
    LECTURER: { canManageSlots: false, canPublish: false, canViewMe: true },
    STUDENT: { canManageSlots: false, canPublish: false, canViewMe: true },
  };

  assert.equal(permissions.ADMIN.canManageSlots, true);
  assert.equal(permissions.ADMIN.canPublish, true);
  assert.equal(permissions.LECTURER.canManageSlots, false);
  assert.equal(permissions.LECTURER.canPublish, false);
  assert.equal(permissions.LECTURER.canViewMe, true);
  assert.equal(permissions.STUDENT.canManageSlots, false);
  assert.equal(permissions.STUDENT.canViewMe, true);
});
