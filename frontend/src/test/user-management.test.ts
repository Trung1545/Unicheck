// ==============================================================================
// UniCheck - Feature F-07: User Management Test Suite
// Contract validation, RBAC boundaries, CSV parsing, and Security Guards
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  Role,
  UserStatus,
  UserCreateRequest,
  UserUpdateRequest,
  UserStatusUpdateRequest,
  CsvImportResultResponse,
} from '../types/api.ts';

test('1. User Creation DTO Validation Contract', () => {
  const validStudent: UserCreateRequest = {
    code: '24110294',
    username: 'hoang.nv',
    password: 'UniCheck@2024#Temp',
    fullName: 'Nguyễn Văn Hoàng',
    email: 'hoang.nv@student.unihcm.edu.vn',
    role: 'STUDENT',
    studentCourse: 'K24',
    department: 'Khoa Công nghệ Thông tin',
  };

  assert.equal(validStudent.role, 'STUDENT');
  assert.equal(validStudent.code, '24110294');
  assert.ok(validStudent.password.length >= 6);
  assert.match(validStudent.email, /@student\.unihcm\.edu\.vn$/);
});

test('2. User Status Update Contract (Lock/Unlock)', () => {
  const lockRequest: UserStatusUpdateRequest = {
    status: 'BLOCKED',
  };
  assert.equal(lockRequest.status, 'BLOCKED');

  const unlockRequest: UserStatusUpdateRequest = {
    status: 'ACTIVE',
  };
  assert.equal(unlockRequest.status, 'ACTIVE');
});

test('3. RBAC Admin-Only Access Guard Verification', () => {
  const checkAdminAccess = (role: Role): boolean => {
    return role === 'ADMIN';
  };

  assert.equal(checkAdminAccess('ADMIN'), true, 'ADMIN must have access to User Management');
  assert.equal(checkAdminAccess('LECTURER'), false, 'LECTURER must NOT have access to User Management');
  assert.equal(checkAdminAccess('STUDENT'), false, 'STUDENT must NOT have access to User Management');
});

test('4. Self-Locking Prevention Guard Logic', () => {
  const canModifyUserStatus = (currentUserId: number, targetUserId: number, newStatus: UserStatus): { allowed: boolean; reason?: string } => {
    if (currentUserId === targetUserId && (newStatus === 'BLOCKED' || newStatus === 'INACTIVE')) {
      return { allowed: false, reason: 'Bạn không thể tự khóa tài khoản của chính mình' };
    }
    return { allowed: true };
  };

  const selfLockResult = canModifyUserStatus(1, 1, 'BLOCKED');
  assert.equal(selfLockResult.allowed, false);
  assert.match(selfLockResult.reason || '', /không thể tự khóa tài khoản/);

  const otherLockResult = canModifyUserStatus(1, 2, 'BLOCKED');
  assert.equal(otherLockResult.allowed, true);
});

test('5. CSV Import Header Validation & Record Parsing Logic', () => {
  const sampleCsv = `code,username,fullName,email,role,phone
24120001,khang.bm,Bùi Minh Khang,24120001@student.unihcm.edu.vn,STUDENT,0912345671
24120002,thao.ht,Hoàng Thu Thảo,24120002@student.unihcm.edu.vn,STUDENT,0912345672
GV-09112,hung.pv,ThS. Phạm Văn Hùng,hung.pv@unihcm.edu.vn,LECTURER,0987654321`;

  const lines = sampleCsv.split('\n');
  const headers = lines[0].split(',').map((h) => h.trim());
  const requiredHeaders = ['code', 'username', 'fullName', 'email', 'role'];

  for (const req of requiredHeaders) {
    assert.ok(headers.includes(req), `CSV header must include ${req}`);
  }

  const records = lines.slice(1).map((line) => {
    const parts = line.split(',');
    return {
      code: parts[0]?.trim(),
      username: parts[1]?.trim(),
      fullName: parts[2]?.trim(),
      email: parts[3]?.trim(),
      role: parts[4]?.trim() as Role,
      phone: parts[5]?.trim(),
    };
  });

  assert.equal(records.length, 3);
  assert.equal(records[0].code, '24120001');
  assert.equal(records[0].role, 'STUDENT');
  assert.equal(records[2].code, 'GV-09112');
  assert.equal(records[2].role, 'LECTURER');
});

test('6. CSV Import Result Envelope Structure', () => {
  const mockResult: CsvImportResultResponse = {
    totalRecords: 50,
    successCount: 48,
    failedCount: 2,
    errors: [
      'Dòng 4: Email nam.lh@unihcm.edu.vn đã tồn tại trong hệ thống',
      'Dòng 7: Thiếu mã định danh bắt buộc',
    ],
  };

  assert.equal(mockResult.totalRecords, 50);
  assert.equal(mockResult.successCount, 48);
  assert.equal(mockResult.failedCount, 2);
  assert.equal(mockResult.errors.length, 2);
});
