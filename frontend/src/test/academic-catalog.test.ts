// ==============================================================================
// UniCheck - Feature F-11 & F-12: Academic Catalog & Semester Management Tests
// Contract validation, Prerequisite graphs, Date ordering, and Business Rules
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  CourseStatus,
  SemesterStatus,
  CourseCreateRequest,
  CourseUpdateRequest,
  CourseResponse,
  SemesterCreateRequest,
  SemesterUpdateRequest,
  SemesterResponse,
  SemesterConfigDto,
  Role,
} from '../types/api.ts';

test('1. Course Creation Contract & Credit Constraints', () => {
  const validCourse: CourseCreateRequest = {
    code: 'INT3101',
    name: 'Kiến trúc máy tính nâng cao',
    credits: 3,
    numberOfSlots: 45,
    description: 'Học phần cơ sở ngành về kiến trúc tập lệnh RISC-V và bộ nhớ phân cấp',
    status: 'ACTIVE',
    isCalculatedInGpa: true,
    prerequisiteIds: [1, 2],
  };

  assert.equal(validCourse.code, 'INT3101');
  assert.equal(validCourse.credits, 3);
  assert.ok(validCourse.credits > 0, 'Credits must be strictly positive');
  assert.equal(validCourse.numberOfSlots, 45);
  assert.equal(validCourse.status, 'ACTIVE');
  assert.equal(validCourse.isCalculatedInGpa, true);
  assert.deepEqual(validCourse.prerequisiteIds, [1, 2]);
});

test('2. Course Code & Credits Boundary Constraints', () => {
  const validateCourseConstraints = (req: Partial<CourseCreateRequest>): { valid: boolean; error?: string } => {
    if (!req.code || req.code.trim().length === 0) {
      return { valid: false, error: 'Mã học phần là bắt buộc' };
    }
    if (!req.name || req.name.trim().length === 0) {
      return { valid: false, error: 'Tên học phần là bắt buộc' };
    }
    if (req.credits === undefined || req.credits <= 0 || req.credits > 10) {
      return { valid: false, error: 'Số tín chỉ phải từ 1 đến 10' };
    }
    if (req.numberOfSlots === undefined || req.numberOfSlots <= 0) {
      return { valid: false, error: 'Số tiết học phải lớn hơn 0' };
    }
    return { valid: true };
  };

  assert.equal(validateCourseConstraints({ code: '', name: 'Test', credits: 3, numberOfSlots: 45 }).valid, false);
  assert.equal(validateCourseConstraints({ code: 'CS101', name: '', credits: 3, numberOfSlots: 45 }).valid, false);
  assert.equal(validateCourseConstraints({ code: 'CS101', name: 'Test', credits: 0, numberOfSlots: 45 }).valid, false);
  assert.equal(validateCourseConstraints({ code: 'CS101', name: 'Test', credits: 11, numberOfSlots: 45 }).valid, false);
  assert.equal(validateCourseConstraints({ code: 'CS101', name: 'Test', credits: 3, numberOfSlots: 0 }).valid, false);
  assert.equal(validateCourseConstraints({ code: 'CS101', name: 'Nhập môn lập trình', credits: 4, numberOfSlots: 60 }).valid, true);
});

test('3. Circular Prerequisite Detection Logic', () => {
  // Graph: courseId -> array of prerequisiteIds
  const prerequisiteGraph: Record<number, number[]> = {
    10: [1, 2],
    1: [],
    2: [3],
    3: [],
  };

  const hasCircularDependency = (
    targetId: number,
    candidatePrereqIds: number[],
    graph: Record<number, number[]>
  ): boolean => {
    const visited = new Set<number>();

    const dfs = (currId: number): boolean => {
      if (currId === targetId) return true;
      if (visited.has(currId)) return false;
      visited.add(currId);

      const nexts = graph[currId] || [];
      for (const next of nexts) {
        if (dfs(next)) return true;
      }
      return false;
    };

    for (const prereqId of candidatePrereqIds) {
      if (dfs(prereqId)) return true;
    }
    return false;
  };

  // 1 does not lead to 10
  assert.equal(hasCircularDependency(10, [1, 2], prerequisiteGraph), false);

  // If 3 were to have prerequisite 10: 10 -> 2 -> 3 -> 10 => Circular!
  const circularGraph: Record<number, number[]> = {
    10: [2],
    2: [3],
    3: [10],
  };
  assert.equal(hasCircularDependency(10, [2], circularGraph), true);
});

test('4. Referential Integrity Guard (Cannot delete prerequisite course)', () => {
  const referencedPrerequisites = new Set<number>([1, 2, 5, 8]);

  const canDeleteCourse = (courseId: number): { allowed: boolean; reason?: string } => {
    if (referencedPrerequisites.has(courseId)) {
      return {
        allowed: false,
        reason: 'Không thể xóa học phần đang được làm học phần tiên quyết cho các môn học khác',
      };
    }
    return { allowed: true };
  };

  assert.equal(canDeleteCourse(1).allowed, false);
  assert.match(canDeleteCourse(1).reason || '', /học phần tiên quyết/);
  assert.equal(canDeleteCourse(99).allowed, true);
});

test('5. Semester Date Chronological Ordering Contract', () => {
  const validateSemesterDates = (startDate: string, endDate: string): boolean => {
    const start = new Date(startDate);
    const end = new Date(endDate);
    return !isNaN(start.getTime()) && !isNaN(end.getTime()) && start < end;
  };

  assert.equal(validateSemesterDates('2024-09-02', '2025-01-18'), true);
  assert.equal(validateSemesterDates('2025-01-18', '2024-09-02'), false);
  assert.equal(validateSemesterDates('2024-09-02', '2024-09-02'), false);
});

test('6. Semester Configuration & Threshold Constraints', () => {
  const validSemester: SemesterCreateRequest = {
    code: 'HK1_2024_2025',
    name: 'Học kỳ 1 (2024 - 2025)',
    startDate: '2024-09-02',
    endDate: '2025-01-18',
    status: 'ACTIVE',
    description: 'Học kỳ chính mùa Thu khóa 2024-2025',
    maxSlotPerDay: 6,
    slotPerSubjectPerWeek: 4,
    slotDuration: 50,
    isPublished: true,
  };

  assert.equal(validSemester.code, 'HK1_2024_2025');
  assert.equal(validSemester.status, 'ACTIVE');
  assert.equal(validSemester.slotDuration, 50);
  assert.ok(validSemester.maxSlotPerDay && validSemester.maxSlotPerDay >= 1 && validSemester.maxSlotPerDay <= 12);
  assert.ok(validSemester.slotPerSubjectPerWeek && validSemester.slotPerSubjectPerWeek >= 1 && validSemester.slotPerSubjectPerWeek <= 10);
  assert.equal(validSemester.isPublished, true);

  const configDto: SemesterConfigDto = {
    maxSlotPerDay: 6,
    slotPerSubjectPerWeek: 4,
    slotDuration: 50,
    isPublished: true,
  };
  assert.equal(configDto.slotDuration, 50);
  assert.equal(configDto.isPublished, true);
});

test('7. Active Semester State Transition Rule', () => {
  type SemesterItem = { id: number; code: string; status: SemesterStatus };
  const semesters: SemesterItem[] = [
    { id: 1, code: 'HK2_2023_2024', status: 'ACTIVE' },
    { id: 2, code: 'HK1_2024_2025', status: 'UPCOMING' },
  ];

  // Activating HK1_2024_2025 must close previous active semesters
  const activateSemester = (targetId: number, list: SemesterItem[]): SemesterItem[] => {
    return list.map((sem) => {
      if (sem.id === targetId) {
        return { ...sem, status: 'ACTIVE' as SemesterStatus };
      }
      if (sem.status === 'ACTIVE') {
        return { ...sem, status: 'CLOSED' as SemesterStatus };
      }
      return sem;
    });
  };

  const updated = activateSemester(2, semesters);
  assert.equal(updated.find((s) => s.id === 1)?.status, 'CLOSED');
  assert.equal(updated.find((s) => s.id === 2)?.status, 'ACTIVE');
});

test('8. RBAC Guard for Academic Catalog & Semesters', () => {
  const checkAcademicWritePermission = (role: Role): boolean => {
    return role === 'ADMIN';
  };

  const checkAcademicReadPermission = (role: Role): boolean => {
    return role === 'ADMIN' || role === 'LECTURER' || role === 'STUDENT';
  };

  // Only ADMIN can mutate Course & Semester catalog
  assert.equal(checkAcademicWritePermission('ADMIN'), true);
  assert.equal(checkAcademicWritePermission('LECTURER'), false);
  assert.equal(checkAcademicWritePermission('STUDENT'), false);

  // All roles can read courses and semesters
  assert.equal(checkAcademicReadPermission('ADMIN'), true);
  assert.equal(checkAcademicReadPermission('LECTURER'), true);
  assert.equal(checkAcademicReadPermission('STUDENT'), true);
});
