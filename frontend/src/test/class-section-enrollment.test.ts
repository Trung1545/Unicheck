// ==============================================================================
// UniCheck - Feature F-14 & F-15: Class Section & Enrollment Management Tests
// Contract validation, Capacity bounds, Duplicate guards, and RBAC matrix
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  ClassSectionStatus,
  EnrollmentStatus,
  ClassSectionCreateRequest,
  ClassSectionUpdateRequest,
  ClassSectionResponse,
  EnrollmentCreateRequest,
  EnrollmentResponse,
  Role,
} from '../types/api.ts';

test('1. ClassSectionCreateRequest Contract & Primary Key Validation', () => {
  const validRequest: ClassSectionCreateRequest = {
    className: 'IT301.01',
    courseId: 10,
    semesterId: 1,
    lecturerId: 2,
    maxStudents: 70,
    numberOfSlots: 70,
    status: 'OPEN',
  };

  assert.equal(validRequest.className, 'IT301.01');
  assert.equal(validRequest.courseId, 10);
  assert.equal(validRequest.semesterId, 1);
  assert.equal(validRequest.lecturerId, 2);
  assert.equal(validRequest.maxStudents, 70);
  assert.equal(validRequest.numberOfSlots, 70);
  assert.equal(validRequest.status, 'OPEN');
});

test('2. Class Section Primary Key & Capacity Constraints', () => {
  const validateClassSection = (req: Partial<ClassSectionCreateRequest>): { valid: boolean; error?: string } => {
    if (!req.className || req.className.trim().length === 0) {
      return { valid: false, error: 'Mã lớp học phần là bắt buộc' };
    }
    if (req.className.length > 50) {
      return { valid: false, error: 'Mã lớp không được vượt quá 50 ký tự' };
    }
    if (req.courseId === undefined || req.courseId <= 0) {
      return { valid: false, error: 'Học phần là bắt buộc' };
    }
    if (req.semesterId === undefined || req.semesterId <= 0) {
      return { valid: false, error: 'Học kỳ là bắt buộc' };
    }
    if (req.numberOfSlots === undefined || req.numberOfSlots <= 0) {
      return { valid: false, error: 'Sĩ số tối đa phải lớn hơn 0' };
    }
    return { valid: true };
  };

  assert.equal(validateClassSection({ className: '', courseId: 1, semesterId: 1, numberOfSlots: 45 }).valid, false);
  assert.equal(validateClassSection({ className: 'A'.repeat(51), courseId: 1, semesterId: 1, numberOfSlots: 45 }).valid, false);
  assert.equal(validateClassSection({ className: 'CS101.01', courseId: 0, semesterId: 1, numberOfSlots: 45 }).valid, false);
  assert.equal(validateClassSection({ className: 'CS101.01', courseId: 1, semesterId: 0, numberOfSlots: 45 }).valid, false);
  assert.equal(validateClassSection({ className: 'CS101.01', courseId: 1, semesterId: 1, numberOfSlots: 0 }).valid, false);
  assert.equal(validateClassSection({ className: 'CS101.01', courseId: 1, semesterId: 1, numberOfSlots: 50 }).valid, true);
});

test('3. Class Capacity Guard: Prevent Enrolling Past Max Slots', () => {
  const checkCapacityAvailable = (enrolledCount: number, maxSlots: number): boolean => {
    return enrolledCount < maxSlots;
  };

  assert.equal(checkCapacityAvailable(68, 70), true, 'Capacity available when 68/70');
  assert.equal(checkCapacityAvailable(69, 70), true, 'Capacity available when 69/70');
  assert.equal(checkCapacityAvailable(70, 70), false, 'Capacity exceeded when 70/70');
  assert.equal(checkCapacityAvailable(71, 70), false, 'Capacity exceeded when 71/70');
});

test('4. Enrollment Duplicate Prevention Guard', () => {
  const existingEnrollments = [
    { studentId: 101, className: 'IT301.01' },
    { studentId: 102, className: 'IT301.01' },
    { studentId: 103, className: 'IT301.02' },
  ];

  const isDuplicateEnrollment = (studentId: number, className: string): boolean => {
    return existingEnrollments.some(
      (e) => e.studentId === studentId && e.className === className
    );
  };

  assert.equal(isDuplicateEnrollment(101, 'IT301.01'), true, 'Student 101 is duplicate in IT301.01');
  assert.equal(isDuplicateEnrollment(103, 'IT301.01'), false, 'Student 103 is not in IT301.01');
  assert.equal(isDuplicateEnrollment(104, 'IT301.01'), false, 'New student 104 is not duplicate');
});

test('5. Student Role Enforcement for Enrollment', () => {
  const userRoles: Record<number, Role> = {
    1: 'ADMIN',
    2: 'LECTURER',
    3: 'STUDENT',
    4: 'STUDENT',
  };

  const canBeEnrolled = (userId: number): boolean => {
    return userRoles[userId] === 'STUDENT';
  };

  assert.equal(canBeEnrolled(1), false, 'ADMIN cannot be enrolled as student');
  assert.equal(canBeEnrolled(2), false, 'LECTURER cannot be enrolled as student');
  assert.equal(canBeEnrolled(3), true, 'STUDENT can be enrolled');
  assert.equal(canBeEnrolled(4), true, 'STUDENT can be enrolled');
});

test('6. Class Section Status Lifecycle Validation', () => {
  const validTransitions: Record<ClassSectionStatus, ClassSectionStatus[]> = {
    OPEN: ['ACTIVE', 'CANCELLED'],
    ACTIVE: ['CLOSED', 'CANCELLED'],
    CLOSED: [],
    CANCELLED: [],
  };

  const isValidTransition = (from: ClassSectionStatus, to: ClassSectionStatus): boolean => {
    return validTransitions[from]?.includes(to) ?? false;
  };

  assert.equal(isValidTransition('OPEN', 'ACTIVE'), true);
  assert.equal(isValidTransition('ACTIVE', 'CLOSED'), true);
  assert.equal(isValidTransition('CLOSED', 'OPEN'), false);
  assert.equal(isValidTransition('CANCELLED', 'ACTIVE'), false);
});

test('7. Capacity Update Guard: Cannot Reduce Below Enrolled Count', () => {
  const canUpdateCapacity = (newSlots: number, currentEnrolled: number): boolean => {
    return newSlots >= currentEnrolled;
  };

  assert.equal(canUpdateCapacity(65, 60), true, 'Can reduce from 70 to 65 if enrolled is 60');
  assert.equal(canUpdateCapacity(60, 60), true, 'Can reduce to exact enrolled count');
  assert.equal(canUpdateCapacity(55, 60), false, 'Cannot reduce below enrolled count');
});

test('8. RBAC Matrix for Class & Enrollment Management', () => {
  type Action = 'CREATE_CLASS' | 'EDIT_CLASS' | 'DELETE_CLASS' | 'ENROLL_STUDENT' | 'UNENROLL_STUDENT' | 'VIEW_ALL_CLASSES' | 'VIEW_ASSIGNED_CLASSES';

  const checkPermission = (role: Role, action: Action): boolean => {
    if (role === 'ADMIN') return true;
    if (role === 'LECTURER') {
      return action === 'VIEW_ASSIGNED_CLASSES';
    }
    if (role === 'STUDENT') {
      return false; // Students cannot manage classes or enroll themselves in admin panel
    }
    return false;
  };

  assert.equal(checkPermission('ADMIN', 'CREATE_CLASS'), true);
  assert.equal(checkPermission('ADMIN', 'ENROLL_STUDENT'), true);
  assert.equal(checkPermission('ADMIN', 'DELETE_CLASS'), true);

  assert.equal(checkPermission('LECTURER', 'VIEW_ASSIGNED_CLASSES'), true);
  assert.equal(checkPermission('LECTURER', 'CREATE_CLASS'), false);
  assert.equal(checkPermission('LECTURER', 'ENROLL_STUDENT'), false);

  assert.equal(checkPermission('STUDENT', 'CREATE_CLASS'), false);
  assert.equal(checkPermission('STUDENT', 'ENROLL_STUDENT'), false);
});
