// ==============================================================================
// UniCheck - Attendance Session Management Type Definitions (TASK-05)
// Supporting Stitch Screen 4f83098c7b904d4389563c28f54e1c48 & 300c3071598340e5981a9a5f5097f909
// ==============================================================================

export type AttendanceSessionStatus = 'CREATED' | 'OPEN' | 'CLOSED' | 'CANCELLED';

export interface AttendanceSessionResponse {
  id: number;
  timetableSlotId: number;
  classSectionId?: number | null;
  className: string;
  courseCode: string;
  courseName: string;
  lecturerId: number;
  lecturerName: string;
  lecturerCode: string;
  roomCode: string;
  roomName: string;
  building: string;
  date: string;
  dayOfWeek: number;
  slotNumber: number;
  slotName: string;
  startTime: string;
  endTime: string;
  status: AttendanceSessionStatus;
  openedAt?: string | null;
  closedAt?: string | null;
  createdAt: string;
  updatedAt?: string | null;
  totalEnrolledStudents: number;
  totalAttendedStudents: number;
  attendancePercentage: number;
  canOpen: boolean;
  canClose: boolean;
  qrRotationIntervalSeconds?: number;
}

export interface AttendanceSessionStatusResponse {
  id: number;
  status: AttendanceSessionStatus;
  openedAt?: string | null;
  closedAt?: string | null;
  isOpen: boolean;
  isClosed: boolean;
  canGenerateQr: boolean;
  totalEnrolledStudents: number;
  totalAttendedStudents: number;
  attendancePercentage: number;
}

export interface AttendanceSessionStatsResponse {
  totalSessionsToday?: number;
  totalToday?: number;
  morningSessions?: number;
  afternoonSessions?: number;
  activeOpenSessions?: number;
  openCount?: number;
  completedSessions?: number;
  closedCount?: number;
  onTimeRate?: number;
  attendanceRatePercentage?: number;
  abnormalSessions?: number;
  abnormalCount?: number;
  upcomingCount?: number;
}

export interface AttendanceConfigDto {
  id?: number | null;
  configKey: string;
  qrRotationIntervalSeconds: number;
  ticketTtlSeconds: number;
  faceThresholdPercent: number;
  livenessEnabled: boolean;
  kioskScanMode: string;
  absentThresholdMinutes: number;
  lateThresholdMinutes: number;
  minAttendancePercentage: number;
  manualEnabled: boolean;
  faceRecognitionEnabled: boolean;
  qrCodeEnabled: boolean;
  wifiLocationEnabled: boolean;
  allowedIpSubnet?: string | null;
  maxAttempts: number;
  updatedAt?: string | null;
}

export interface AttendanceSessionCreateRequest {
  timetableSlotId: number;
  autoOpen?: boolean;
  qrRotationIntervalSeconds?: number;
}

export interface AttendanceSessionOpenRequest {
  qrRotationIntervalSeconds?: number;
}

export interface AttendanceSessionQueryParams {
  search?: string;
  semesterId?: number;
  className?: string;
  lecturerId?: number;
  date?: string;
  status?: AttendanceSessionStatus | 'ALL';
  page?: number;
  size?: number;
  sort?: string;
}

export interface StudentAttendanceResponse {
  id: number;
  sessionId: number;
  studentId: number;
  studentCode: string;
  studentName: string;
  status: string;
  method: string;
  checkInTime?: string | null;
  faceConfidence?: number | null;
  deviceInfo?: string | null;
  verifiedByKiosk?: string | null;
}

// TASK-06 Dynamic QR Types
export interface QrTokenResponse {
  sessionId: number;
  qrToken: string;
  otpCode?: string;
  issuedAt: string;
  expiresAt: string;
  rotationExpiresAt: string;
  rotationIntervalSeconds: number;
  remainingSeconds: number;
  status: AttendanceSessionStatus;
  mode?: 'DYNAMIC_QR' | 'STATIC_TEST_QR';
}

export interface StaticQrStatusResponse {
  allowed: boolean;
  reason?: string;
  className?: string;
  sessionId?: number;
  sessionStatus?: AttendanceSessionStatus;
}

export interface QrValidationRequest {
  qrToken: string;
  sessionId: number;
}

export interface QrValidationResponse {
  valid: boolean;
  sessionId: number;
  className: string;
  roomName: string;
  issuedAt: string;
  expiresAt: string;
  message: string;
}

export interface SessionStudentAttendanceDto {
  studentId: number;
  studentCode: string;
  fullName: string;
  email: string;
  attendanceId?: number | null;
  status: 'PRESENT' | 'LATE' | 'ABSENT' | 'NOT_CHECKED_IN' | string;
  checkInTime?: string | null;
  method?: string | null;
  faceConfidence?: number | null;
  note?: string | null;
  recheckStatus: 'NONE' | 'PENDING' | 'COMPLETED' | 'EXPIRED' | string;
  recheckRequestId?: number | null;
  recheckReason?: string | null;
  recheckExpiresAt?: string | null;
}

export interface AttendanceManualAdjustRequest {
  newStatus: 'PRESENT' | 'LATE' | 'ABSENT';
  reason: string;
}

export interface AttendanceRecheckCreateRequest {
  reason: string;
  expirationMinutes?: number;
}

export interface AttendanceRecheckResponse {
  requestId: number;
  sessionId?: number | null;
  studentId: number;
  studentCode: string;
  studentName: string;
  courseCode: string;
  courseName: string;
  className: string;
  roomCode: string;
  reason: string;
  status: string;
  requestedAt?: string | null;
  expiresAt?: string | null;
  completedAt?: string | null;
  requestedByName: string;
}

export interface AttendanceHistoryRecordDto {
  id: number;
  sessionId: number;
  studentId: number;
  studentCode: string;
  studentName: string;
  oldStatus: string;
  newStatus: string;
  reason: string;
  modifiedByName: string;
  modifiedAt: string;
  modificationType: string;
}
