// ==============================================================================
// UniCheck - Feature F-13: Facilities & Wi-Fi AP Management Tests
// Contract validation, BSSID Normalization, Geofence Bounds, and RBAC matrix
// ==============================================================================

import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  RoomType,
  RoomStatus,
  WifiApStatus,
  RoomCreateRequest,
  RoomUpdateRequest,
  RoomResponse,
  WifiAccessPointCreateRequest,
  WifiAccessPointUpdateRequest,
  WifiAccessPointResponse,
  AssignWifiApRequest,
  RoomWifiAccessPointResponse,
  FacilityStatsResponse,
  Role,
} from '../types/api.ts';

// BSSID regex matcher: XX:XX:XX:XX:XX:XX or XX-XX-XX-XX-XX-XX
const BSSID_REGEX = /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/;

test('1. RoomCreateRequest Contract & Capacity Constraints', () => {
  const validRequest: RoomCreateRequest = {
    code: 'C3-102',
    name: 'Hội trường C3-102',
    capacity: 150,
    building: 'Giảng đường C',
    floor: 1,
    type: 'AUDITORIUM',
    status: 'AVAILABLE',
    description: 'Hội trường đa năng âm thanh vòm',
  };

  assert.equal(validRequest.code, 'C3-102');
  assert.equal(validRequest.name, 'Hội trường C3-102');
  assert.equal(validRequest.capacity, 150);
  assert.equal(validRequest.building, 'Giảng đường C');
  assert.equal(validRequest.type, 'AUDITORIUM');
  assert.equal(validRequest.status, 'AVAILABLE');
});

test('2. Room Code & Capacity Validation Rules', () => {
  const validateRoom = (req: Partial<RoomCreateRequest>): { valid: boolean; error?: string } => {
    if (!req.code || req.code.trim().length === 0) {
      return { valid: false, error: 'Mã phòng học không được để trống' };
    }
    if (req.code.length > 20) {
      return { valid: false, error: 'Mã phòng học tối đa 20 ký tự' };
    }
    if (!req.name || req.name.trim().length === 0) {
      return { valid: false, error: 'Tên phòng học không được để trống' };
    }
    if (!req.capacity || req.capacity <= 0) {
      return { valid: false, error: 'Sức chứa phòng học phải lớn hơn 0' };
    }
    return { valid: true };
  };

  assert.equal(validateRoom({ code: '', name: 'Phòng A', capacity: 60 }).valid, false);
  assert.equal(validateRoom({ code: 'TOOLONG_ROOM_CODE_EXCEEDING_LIMIT', name: 'Phòng A', capacity: 60 }).valid, false);
  assert.equal(validateRoom({ code: 'A1-101', name: '', capacity: 60 }).valid, false);
  assert.equal(validateRoom({ code: 'A1-101', name: 'Phòng A1-101', capacity: 0 }).valid, false);
  assert.equal(validateRoom({ code: 'A1-101', name: 'Phòng A1-101', capacity: 70 }).valid, true);
});

test('3. WifiAccessPointCreateRequest Contract & BSSID Pattern Validation', () => {
  const validAp: WifiAccessPointCreateRequest = {
    ssid: 'UniCheck_Hall_C3_Front',
    bssid: '00:1A:2B:3C:4D:5E',
    name: 'AP C3 Front',
    location: 'Bục giảng chính',
    status: 'ACTIVE',
  };

  assert.equal(validAp.ssid, 'UniCheck_Hall_C3_Front');
  assert.equal(BSSID_REGEX.test(validAp.bssid), true);
  assert.equal(validAp.status, 'ACTIVE');

  // Invalid BSSIDs
  assert.equal(BSSID_REGEX.test('INVALID_MAC'), false);
  assert.equal(BSSID_REGEX.test('00:1A:2B:3C:4D'), false); // Thiếu 1 byte
  assert.equal(BSSID_REGEX.test('00:1A:2B:3C:4D:5E:6F'), false); // Thừa byte
  assert.equal(BSSID_REGEX.test('GG:1A:2B:3C:4D:5E'), false); // Chứa ký tự ngoài Hex
});

test('4. BSSID Normalization Function Contract', () => {
  const normalizeBssid = (rawBssid: string): string => {
    const cleaned = rawBssid.trim().toUpperCase().replace(/-/g, ':');
    if (!BSSID_REGEX.test(cleaned)) {
      throw new Error('Định dạng BSSID không hợp lệ');
    }
    return cleaned;
  };

  assert.equal(normalizeBssid('00-1a-2b-3c-4d-5e'), '00:1A:2B:3C:4D:5E');
  assert.equal(normalizeBssid('88:e0:f3:11:09:a1'), '88:E0:F3:11:09:A1');
  assert.throws(() => normalizeBssid('invalid_mac'));
});

test('5. Room - Wi-Fi AP Association & Priority Guard', () => {
  const mapping: RoomWifiAccessPointResponse = {
    id: 1,
    roomId: 10,
    roomCode: 'C3-102',
    roomName: 'Hội trường C3-102',
    wifiAccessPointId: 20,
    ssid: 'UniCheck_Hall_C3_Front',
    bssid: '00:1A:2B:3C:4D:5E',
    signalStrength: -61,
    isPrimary: true,
    positionNote: 'Bục giảng chính & Màn hình LED',
    createdAt: '2026-10-16T14:30:00Z',
  };

  assert.equal(mapping.roomCode, 'C3-102');
  assert.equal(mapping.isPrimary, true);
  assert.equal(mapping.signalStrength, -61);
  assert.ok(mapping.signalStrength! >= -90 && mapping.signalStrength! <= -30);
});

test('6. Geofencing Wi-Fi Parameters Validation Contract', () => {
  const validateGeofence = (radius: number, minRssi: number): boolean => {
    const isRadiusValid = radius >= 5 && radius <= 30;
    const isRssiValid = minRssi >= -90 && minRssi <= -40;
    return isRadiusValid && isRssiValid;
  };

  assert.equal(validateGeofence(12, -75), true); // Chuẩn Stitch
  assert.equal(validateGeofence(4, -75), false); // Bán kính quá hẹp < 5m
  assert.equal(validateGeofence(35, -75), false); // Bán kính quá rộng > 30m
  assert.equal(validateGeofence(15, -95), false); // RSSI quá yếu
  assert.equal(validateGeofence(15, -30), false); // RSSI quá nhạy
});

test('7. Delete Guard Logic for Rooms in Use', () => {
  const canDeleteRoom = (timetableCount: number, requestCount: number): { canDelete: boolean; reason?: string } => {
    if (timetableCount > 0) {
      return { canDelete: false, reason: `Phòng đang có ${timetableCount} ca học trong thời khóa biểu` };
    }
    if (requestCount > 0) {
      return { canDelete: false, reason: `Phòng đang có ${requestCount} yêu cầu đổi lịch học` };
    }
    return { canDelete: true };
  };

  assert.equal(canDeleteRoom(0, 0).canDelete, true);
  assert.equal(canDeleteRoom(3, 0).canDelete, false);
  assert.equal(canDeleteRoom(0, 1).canDelete, false);
});

test('8. RBAC Matrix for Facilities & Wi-Fi Management', () => {
  const checkPermission = (role: Role, action: 'READ' | 'WRITE'): boolean => {
    if (role === 'ADMIN') return true;
    if (action === 'READ' && (role === 'LECTURER' || role === 'STUDENT')) return true;
    return false;
  };

  assert.equal(checkPermission('ADMIN', 'READ'), true);
  assert.equal(checkPermission('ADMIN', 'WRITE'), true);
  assert.equal(checkPermission('LECTURER', 'READ'), true);
  assert.equal(checkPermission('LECTURER', 'WRITE'), false);
  assert.equal(checkPermission('STUDENT', 'READ'), true);
  assert.equal(checkPermission('STUDENT', 'WRITE'), false);
});
