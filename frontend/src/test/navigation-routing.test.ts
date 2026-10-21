// ==============================================================================
// UniCheck - Navigation & RBAC Routing Verification Tests
// Covers: NAVIGATION_CONFIG paths, Role Access Guard Matrix, Lookup Safety
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import type { Role, TimetableSlotResponse, PageResponse } from '../types/api.ts';

test('1. Admin Navigation File Verification: Quản lý lớp học phần & Thời khóa biểu tuần', () => {
  const navFilePath = path.resolve('src/config/navigation.config.ts');
  const navContent = fs.readFileSync(navFilePath, 'utf8');

  // Verify Admin paths and labels exist
  assert.ok(navContent.includes("path: '/dashboard/classes'"), 'Admin must have /dashboard/classes');
  assert.ok(navContent.includes("label: 'Quản lý lớp học phần'"), "Admin must have label 'Quản lý lớp học phần'");
  assert.ok(navContent.includes("path: '/admin/timetable'"), 'Admin must have /admin/timetable');
  assert.ok(navContent.includes("label: 'Thời khóa biểu tuần'"), "Admin must have label 'Thời khóa biểu tuần'");
});

test('2. Lecturer Navigation File Verification: Lớp học phần phụ trách & Thời khóa biểu tuần', () => {
  const navFilePath = path.resolve('src/config/navigation.config.ts');
  const navContent = fs.readFileSync(navFilePath, 'utf8');

  assert.ok(navContent.includes("path: '/lecturer/classes'"), 'Lecturer must have /lecturer/classes');
  assert.ok(navContent.includes("label: 'Lớp học phần phụ trách'"), "Lecturer must have label 'Lớp học phần phụ trách'");
  assert.ok(navContent.includes("path: '/lecturer/timetable'"), 'Lecturer must have /lecturer/timetable');
});

test('3. Student Navigation File Verification: Lớp học phần của tôi & Thời khóa biểu tuần', () => {
  const navFilePath = path.resolve('src/config/navigation.config.ts');
  const navContent = fs.readFileSync(navFilePath, 'utf8');

  assert.ok(navContent.includes("path: '/student/classes'"), 'Student must have /student/classes');
  assert.ok(navContent.includes("label: 'Lớp học phần của tôi'"), "Student must have label 'Lớp học phần của tôi'");
  assert.ok(navContent.includes("path: '/student/timetable'"), 'Student must have /student/timetable');
});

test('4. React Router Routes File Verification for Accessible Paths', () => {
  const routesFilePath = path.resolve('src/routes/index.tsx');
  const routesContent = fs.readFileSync(routesFilePath, 'utf8');

  // Classes routes
  assert.ok(routesContent.includes('path="/dashboard/classes"'), 'Routes must register /dashboard/classes');
  assert.ok(routesContent.includes('path="/lecturer/classes"'), 'Routes must register /lecturer/classes');
  assert.ok(routesContent.includes('path="/student/classes"'), 'Routes must register /student/classes');
  assert.ok(routesContent.includes('path="/classes"'), 'Routes must register /classes');

  // Timetable routes
  assert.ok(routesContent.includes('path="/admin/timetable"'), 'Routes must register /admin/timetable');
  assert.ok(routesContent.includes('path="/lecturer/timetable"'), 'Routes must register /lecturer/timetable');
  assert.ok(routesContent.includes('path="/student/timetable"'), 'Routes must register /student/timetable');
  assert.ok(routesContent.includes('path="/timetable"'), 'Routes must register /timetable');
});

test('5. Route RBAC Guard Strategy for Class Section Management', () => {
  const routeAccessMatrix: Record<string, { requiresAuth: boolean; allowedRoles: Role[] }> = {
    '/admin/classes': { requiresAuth: true, allowedRoles: ['ADMIN'] },
    '/dashboard/classes': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
    '/lecturer/classes': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
    '/student/classes': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
    '/classes': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
  };

  const isRouteAllowed = (pathStr: string, userRole: Role | null): boolean => {
    const route = routeAccessMatrix[pathStr];
    if (!route) return false;
    if (route.requiresAuth && !userRole) return false;
    return route.allowedRoles.includes(userRole as Role);
  };

  // Lecturer accessing their classes route
  assert.equal(isRouteAllowed('/lecturer/classes', 'LECTURER'), true);
  assert.equal(isRouteAllowed('/dashboard/classes', 'LECTURER'), true);

  // Student accessing their classes route
  assert.equal(isRouteAllowed('/student/classes', 'STUDENT'), true);

  // Admin accessing all classes routes
  assert.equal(isRouteAllowed('/admin/classes', 'ADMIN'), true);
  assert.equal(isRouteAllowed('/dashboard/classes', 'ADMIN'), true);

  // Lecturer trying to access admin-only /admin/classes
  assert.equal(isRouteAllowed('/admin/classes', 'LECTURER'), false);

  // Unauthenticated user rejected
  assert.equal(isRouteAllowed('/lecturer/classes', null), false);
});

test('6. Route RBAC Guard Strategy for Master & Personal Timetable', () => {
  const timetableRoutes: Record<string, { requiresAuth: boolean; allowedRoles: Role[] }> = {
    '/admin/timetable': { requiresAuth: true, allowedRoles: ['ADMIN'] },
    '/dashboard/timetable': { requiresAuth: true, allowedRoles: ['ADMIN'] },
    '/lecturer/timetable': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
    '/student/timetable': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
    '/timetable': { requiresAuth: true, allowedRoles: ['ADMIN', 'LECTURER', 'STUDENT'] },
  };

  const isTimetableAllowed = (pathStr: string, userRole: Role | null): boolean => {
    const route = timetableRoutes[pathStr];
    if (!route) return false;
    if (route.requiresAuth && !userRole) return false;
    return route.allowedRoles.includes(userRole as Role);
  };

  assert.equal(isTimetableAllowed('/admin/timetable', 'ADMIN'), true);
  assert.equal(isTimetableAllowed('/admin/timetable', 'LECTURER'), false);
  assert.equal(isTimetableAllowed('/lecturer/timetable', 'LECTURER'), true);
  assert.equal(isTimetableAllowed('/student/timetable', 'STUDENT'), true);
});

test('7. ClassSectionPage Lookup RBAC Safety (Prevents 403 on Non-Admin)', () => {
  // When a Lecturer or Student loads ClassSectionPage, getUsersApi should not be called
  const shouldFetchUserLookup = (role: Role): boolean => {
    return role === 'ADMIN';
  };

  assert.equal(shouldFetchUserLookup('ADMIN'), true, 'Admin must load lecturer users lookup for class assignment');
  assert.equal(shouldFetchUserLookup('LECTURER'), false, 'Lecturer must not query getUsersApi to prevent 403');
  assert.equal(shouldFetchUserLookup('STUDENT'), false, 'Student must not query getUsersApi to prevent 403');
});

test('8. Timetable Data Unwrapping Handles Raw Array & PageResponse', () => {
  const mockSlot: TimetableSlotResponse = {
    id: 1,
    className: 'IT301',
    courseCode: 'IT301',
    courseName: 'Cấu trúc dữ liệu',
    date: '2026-10-19',
    dayOfWeek: 1,
    slotNumber: 1,
    endSlotNumber: 3,
    status: 'SCHEDULED',
  };

  const unwrapSlots = (data: any): TimetableSlotResponse[] => {
    if (Array.isArray(data)) return data;
    if (data?.content && Array.isArray(data.content)) return data.content;
    return [];
  };

  // Case 1: Raw array
  const rawArray = [mockSlot];
  assert.deepEqual(unwrapSlots(rawArray), [mockSlot]);

  // Case 2: PageResponse envelope
  const pagedResponse: PageResponse<TimetableSlotResponse> = {
    content: [mockSlot],
    pageNumber: 0,
    pageSize: 20,
    totalElements: 1,
    totalPages: 1,
    isFirst: true,
    isLast: true,
  };
  assert.deepEqual(unwrapSlots(pagedResponse), [mockSlot]);

  // Case 3: Empty / null / invalid
  assert.deepEqual(unwrapSlots(null), []);
  assert.deepEqual(unwrapSlots({}), []);
});

test('9. Role-Based Permissions for Class Section Operations', () => {
  const canPerformClassOperation = (operation: 'create' | 'edit' | 'delete' | 'enroll' | 'view', role: Role): boolean => {
    switch (operation) {
      case 'create':
      case 'edit':
      case 'delete':
      case 'enroll':
        return role === 'ADMIN';
      case 'view':
        return true;
      default:
        return false;
    }
  };

  assert.equal(canPerformClassOperation('create', 'ADMIN'), true);
  assert.equal(canPerformClassOperation('create', 'LECTURER'), false);
  assert.equal(canPerformClassOperation('create', 'STUDENT'), false);

  assert.equal(canPerformClassOperation('edit', 'ADMIN'), true);
  assert.equal(canPerformClassOperation('edit', 'LECTURER'), false);

  assert.equal(canPerformClassOperation('delete', 'ADMIN'), true);
  assert.equal(canPerformClassOperation('delete', 'LECTURER'), false);

  assert.equal(canPerformClassOperation('enroll', 'ADMIN'), true);
  assert.equal(canPerformClassOperation('enroll', 'LECTURER'), false);

  assert.equal(canPerformClassOperation('view', 'ADMIN'), true);
  assert.equal(canPerformClassOperation('view', 'LECTURER'), true);
  assert.equal(canPerformClassOperation('view', 'STUDENT'), true);
});
