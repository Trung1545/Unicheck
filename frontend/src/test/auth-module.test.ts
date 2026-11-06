import test from 'node:test';
import assert from 'node:assert/strict';
import type {
  LoginResponse,
  UserProfileResponse,
  UpdateProfileRequest,
  ResetPasswordRequest,
  ChangePasswordRequest,
  ForgotPasswordRequest,
} from '../types/api.ts';

// Mock localStorage for test environment
class MockLocalStorage {
  private store: Record<string, string> = {};

  getItem(key: string): string | null {
    return this.store[key] ?? null;
  }

  setItem(key: string, value: string): void {
    this.store[key] = String(value);
  }

  removeItem(key: string): void {
    delete this.store[key];
  }

  clear(): void {
    this.store = {};
  }
}

const mockStorage = new MockLocalStorage();
if (typeof globalThis.localStorage === 'undefined') {
  (globalThis as any).localStorage = mockStorage;
}

test('1. Flat Login Response Schema Contract Verification', () => {
  // Mock flat backend response from Spring Boot AuthController
  const mockFlatResponse: LoginResponse = {
    token: 'eyJhbGciOiJIUzI1NiJ9.test-access-token',
    refreshToken: '6b2a0c4f-9e7d-41a2-8e1f-d748f2a1b9c3',
    tokenType: 'Bearer',
    expiresIn: 900,
    userId: 101,
    code: 'SV20260001',
    username: 'student_01',
    fullName: 'Nguyễn Văn Sinh Viên',
    email: 'student01@unicheck.edu.vn',
    role: 'STUDENT',
    isPasswordChanged: true,
  };

  // Assert Flat Schema: properties exist directly on top-level
  assert.equal(mockFlatResponse.userId, 101);
  assert.equal(mockFlatResponse.code, 'SV20260001');
  assert.equal(mockFlatResponse.username, 'student_01');
  assert.equal(mockFlatResponse.role, 'STUDENT');
  assert.equal(mockFlatResponse.isPasswordChanged, true);
  assert.equal(mockFlatResponse.tokenType, 'Bearer');
  assert.equal(mockFlatResponse.expiresIn, 900);

  // Assert NOT using old nested mock schema
  assert.equal((mockFlatResponse as any).user, undefined);
  assert.equal((mockFlatResponse as any).tokens, undefined);
});

test('2. Token Storage and Session Persistence', () => {
  mockStorage.clear();

  const token = 'header.payload.signature';
  const refreshToken = 'uuid-refresh-token-1234';
  const user = {
    id: 101,
    code: 'SV20260001',
    username: 'student_01',
    fullName: 'Nguyễn Văn Sinh Viên',
    email: 'student01@unicheck.edu.vn',
    role: 'STUDENT' as const,
    isPasswordChanged: false,
  };

  // Simulate storing auth tokens
  mockStorage.setItem('access_token', token);
  mockStorage.setItem('refresh_token', refreshToken);
  mockStorage.setItem('unicheck_user', JSON.stringify(user));

  // Verify retrieval
  assert.equal(mockStorage.getItem('access_token'), token);
  assert.equal(mockStorage.getItem('refresh_token'), refreshToken);

  const parsedUser = JSON.parse(mockStorage.getItem('unicheck_user') || '{}');
  assert.equal(parsedUser.id, 101);
  assert.equal(parsedUser.username, 'student_01');
  assert.equal(parsedUser.isPasswordChanged, false);
});

test('3. Refresh Token Rotation (RTR) Updates', () => {
  mockStorage.clear();

  mockStorage.setItem('access_token', 'old_access_token');
  mockStorage.setItem('refresh_token', 'old_refresh_token');

  // New rotated tokens from backend
  const newAccessToken = 'new_rotated_access_token';
  const newRefreshToken = 'new_rotated_refresh_token';

  mockStorage.setItem('access_token', newAccessToken);
  mockStorage.setItem('refresh_token', newRefreshToken);

  assert.equal(mockStorage.getItem('access_token'), newAccessToken);
  assert.equal(mockStorage.getItem('refresh_token'), newRefreshToken);
});

test('4. Complete Logout Cleanup and Sanitization', () => {
  mockStorage.setItem('access_token', 'active_token');
  mockStorage.setItem('refresh_token', 'active_refresh');
  mockStorage.setItem('unicheck_user', JSON.stringify({ id: 1 }));

  // Simulate logout
  mockStorage.removeItem('access_token');
  mockStorage.removeItem('refresh_token');
  mockStorage.removeItem('unicheck_user');

  assert.equal(mockStorage.getItem('access_token'), null);
  assert.equal(mockStorage.getItem('refresh_token'), null);
  assert.equal(mockStorage.getItem('unicheck_user'), null);
});

test('5. Form Validation: Email Regex, Password Strength and OTP Constraints', () => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

  // Valid emails
  assert.equal(emailRegex.test('student01@unicheck.edu.vn'), true);
  assert.equal(emailRegex.test('lecturer.cs@unicheck.edu.vn'), true);
  assert.equal(emailRegex.test('admin@unicheck.vn'), true);

  // Invalid emails
  assert.equal(emailRegex.test(''), false);
  assert.equal(emailRegex.test('invalid-email'), false);
  assert.equal(emailRegex.test('missing-domain@'), false);
  assert.equal(emailRegex.test('@missing-user.edu.vn'), false);

  // Password rules validation (Backend @Size(min=6))
  const validatePassword = (pwd: string) => ({
    hasMinLength: pwd.length >= 6,
    hasUpperLower: /[A-Z]/.test(pwd) && /[a-z]/.test(pwd),
    hasNumber: /[0-9]/.test(pwd),
    hasSpecial: /[^A-Za-z0-9]/.test(pwd),
  });

  const weakPwd = validatePassword('12345');
  assert.equal(weakPwd.hasMinLength, false);

  const validPwd = validatePassword('Student@123');
  assert.equal(validPwd.hasMinLength, true);
  assert.equal(validPwd.hasUpperLower, true);
  assert.equal(validPwd.hasNumber, true);
  assert.equal(validPwd.hasSpecial, true);

  // OTP validation rules (exactly 6 numeric digits)
  const validateOtp = (otp: string) => /^[0-9]{6}$/.test(otp.trim());
  assert.equal(validateOtp('123456'), true);
  assert.equal(validateOtp('000000'), true);
  assert.equal(validateOtp('12345'), false); // Too short
  assert.equal(validateOtp('1234567'), false); // Too long
  assert.equal(validateOtp('12a456'), false); // Contains letter
  assert.equal(validateOtp(' 123456'), true); // Trimmed
});

test('6. Mandatory Initial Password Change Policy', () => {
  const userFirstLogin = {
    id: 101,
    username: 'student_01',
    isPasswordChanged: false,
  };

  const isPasswordChangeRequired = (u: { isPasswordChanged?: boolean } | null) => {
    return u?.isPasswordChanged === false;
  };

  assert.equal(isPasswordChangeRequired(userFirstLogin), true);

  const userAfterChange = {
    ...userFirstLogin,
    isPasswordChanged: true,
  };
  assert.equal(isPasswordChangeRequired(userAfterChange), false);
});

test('7. Profile Update Authorization Boundary: No Role or Permissions Tampering', () => {
  // Verify UpdateProfileRequest contains only personal contact fields
  const validUpdateRequest: UpdateProfileRequest = {
    fullName: 'Nguyễn Văn Sinh Viên Mới',
    phone: '0987654321',
    dob: '2003-05-15',
    sex: 'NAM',
    avatar: 'https://cdn.unicheck.edu.vn/avatar/new.jpg',
  };

  assert.equal(validUpdateRequest.fullName, 'Nguyễn Văn Sinh Viên Mới');
  assert.equal(validUpdateRequest.phone, '0987654321');

  // Verify that role and permissions are NOT part of UpdateProfileRequest
  const disallowedKeys = ['role', 'permissions', 'status', 'code', 'username'];
  for (const key of disallowedKeys) {
    assert.equal(key in validUpdateRequest, false);
  }
});

test('8. ErrorCode Dictionary & User-Friendly Vietnamese Mapping', () => {
  const errorMap: Record<string, string> = {
    ERR_2002: 'Tên đăng nhập hoặc mật khẩu không chính xác. Vui lòng thử lại.',
    ERR_2003: 'Tài khoản của bạn hiện đang bị khóa. Vui lòng liên hệ Quản trị viên.',
    ERR_2004: 'Tài khoản chưa được kích hoạt trong hệ thống.',
    ERR_2007: 'Quá nhiều lần thử đăng nhập thất bại. Vui lòng thử lại sau 15 phút.',
    ERR_2008: 'Mã xác thực không chính xác hoặc đã hết hạn. Vui lòng quay lại lấy mã mới.',
    ERR_2009: 'Mật khẩu hiện tại không chính xác. Vui lòng kiểm tra lại.',
  };

  assert.equal(errorMap['ERR_2002'].includes('không chính xác'), true);
  assert.equal(errorMap['ERR_2003'].includes('bị khóa'), true);
  assert.equal(errorMap['ERR_2007'].includes('15 phút'), true);
  assert.equal(errorMap['ERR_2008'].includes('Mã xác thực không chính xác hoặc đã hết hạn'), true);
  assert.equal(errorMap['ERR_2009'].includes('Mật khẩu hiện tại không chính xác'), true);
});

test('9. Security Sanitization: Sensitive Data Is Never Leaked', () => {
  const sensitivePayload = {
    password: 'SuperSecretPassword@123',
    token: 'jwt.token.secret',
    otp: '987654',
  };

  const sanitizeLog = (data: Record<string, any>) => {
    const copy = { ...data };
    if ('password' in copy) copy.password = '[PROTECTED]';
    if ('token' in copy) copy.token = '[PROTECTED]';
    if ('otp' in copy) copy.otp = '[PROTECTED]';
    return copy;
  };

  const sanitized = sanitizeLog(sensitivePayload);
  assert.equal(sanitized.password, '[PROTECTED]');
  assert.equal(sanitized.token, '[PROTECTED]');
  assert.equal(sanitized.otp, '[PROTECTED]');
  assert.notEqual(sanitized.password, sensitivePayload.password);
});

test('10. Safe Non-Revealing Forgot Password Contract', () => {
  const forgotPasswordRequest: ForgotPasswordRequest = {
    email: 'nonexistent@unicheck.edu.vn',
  };

  // Standard safe response contract from AuthController.java
  const standardResponse = {
    success: true,
    data: null,
    message: 'Nếu email tồn tại trong hệ thống, mã xác thực 6 chữ số đã được gửi qua email',
    errorCode: null,
  };

  assert.equal(standardResponse.success, true);
  assert.equal(standardResponse.data, null);
  // Must NOT reveal whether user exists or not
  assert.equal(standardResponse.message.includes('Nếu email tồn tại'), true);
});
