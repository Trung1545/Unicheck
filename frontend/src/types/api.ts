// ==============================================================================
// UniCheck - Core TypeScript Type Definitions & API Contracts
// Source of Truth: Spring Boot Backend Models & docs/api/auth_api_contract.md
// ==============================================================================

/**
 * Phân quyền tài khoản trong hệ thống
 */
export type Role = 'ADMIN' | 'LECTURER' | 'STUDENT';

/**
 * Trạng thái tài khoản người dùng
 */
export type UserStatus = 'ACTIVE' | 'INACTIVE' | 'BLOCKED' | 'PENDING';

/**
 * Trạng thái dữ liệu khuôn mặt phục vụ điểm danh AI
 */
export type FaceDataStatus =
  | 'NOT_REGISTERED'
  | 'REGISTERED'
  | 'ACTIVE'
  | 'INACTIVE'
  | 'REJECTED'
  | 'PENDING'
  | 'BLOCKED';

/**
 * Cấu trúc Envelope chuẩn cho toàn bộ phản hồi từ UniCheck API
 */
export interface ApiResponse<T = any> {
  success: boolean;
  data: T;
  message: string;
  errorCode: string | null;
}

/**
 * Cấu trúc Envelope phân trang chuẩn từ Spring Data Page
 */
export interface PageResponse<T> {
  content: T[];
  pageNumber: number;
  pageSize: number;
  totalElements: number;
  totalPages: number;
  isFirst: boolean;
  isLast: boolean;
}

/**
 * Hợp đồng Đăng nhập phẳng (Flat Login Response Contract)
 * Lưu ý: Tuyệt đối không parse dạng data.user.id hay data.tokens.accessToken
 */
export interface LoginResponse {
  token: string;              // JWT Access Token (15 phút)
  refreshToken: string;       // Refresh Token (7 ngày)
  tokenType: string;          // Mặc định "Bearer"
  expiresIn: number;          // Thời hạn tính bằng giây (900s = 15m)
  userId: number;             // ID người dùng
  code: string;               // MSSV / MSG / MSNV
  username: string;           // Tên đăng nhập
  fullName: string;           // Họ và tên hiển thị
  email: string;              // Email tài khoản
  role: Role;                 // Phân quyền (ADMIN | LECTURER | STUDENT)
  isPasswordChanged: boolean; // Trạng thái đã đổi mật khẩu lần đầu
}

/**
 * Hợp đồng phản hồi khi làm mới mã xác thực (Refresh Token Rotation)
 */
export interface TokenRefreshResponse {
  token: string;        // Access Token mới
  refreshToken: string; // Refresh Token xoay vòng mới
  tokenType: string;    // "Bearer"
  expiresIn: number;    // 900 giây
}

/**
 * Hồ sơ chi tiết của người dùng đang đăng nhập (GET /api/v1/auth/me)
 */
export interface UserProfileResponse {
  id: number;
  code: string;
  username: string;
  fullName: string;
  email: string;
  phone?: string | null;
  dob?: string | null;
  sex?: string | null;
  role: Role;
  status: UserStatus;
  faceDataStatus: FaceDataStatus;
  avatar?: string | null;
  isPasswordChanged: boolean;
  createdAt: string;
  updatedAt?: string | null;

  // Dành riêng cho Sinh viên
  studentCourse?: string | null;
  gpa?: number | null;
  majorId?: number | null;
  specializationId?: number | null;
  subSpecializationId?: number | null;

  // Dành riêng cho Giảng viên
  department?: string | null;
  expertise?: string | null;
  bio?: string | null;

  // Danh mục quyền hạn chi tiết
  permissions: string[];
}

/**
 * Alias cho người dùng hiện tại trong Auth Store
 */
export interface CurrentUser {
  id: number;
  code: string;
  username: string;
  fullName: string;
  email: string;
  role: Role;
  status?: UserStatus;
  faceDataStatus?: FaceDataStatus;
  avatar?: string | null;
  isPasswordChanged?: boolean;
  permissions?: string[];
  [key: string]: any;
}

// Backward-compatible alias for existing imports
export type User = CurrentUser;
export type UserResponse = UserProfileResponse;

// ==============================================================================
// Request DTOs
// ==============================================================================

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RefreshTokenRequest {
  refreshToken: string;
}

export interface UpdateProfileRequest {
  fullName?: string | null;
  phone?: string | null;
  dob?: string | null;
  sex?: string | null;
  avatar?: string | null;
}

export interface ChangePasswordRequest {
  oldPassword: string;
  newPassword: string;
}

export interface ForgotPasswordRequest {
  email: string;
}

export interface ResetPasswordRequest {
  email: string;
  otp: string;
  newPassword: string;
}

export interface UserCreateRequest {
  code: string;
  username: string;
  password: string;
  fullName: string;
  email: string;
  phone?: string | null;
  dob?: string | null;
  sex?: string | null;
  role: Role;
  studentCourse?: string | null;
  majorId?: number | null;
  specializationId?: number | null;
  subSpecializationId?: number | null;
  department?: string | null;
  expertise?: string | null;
  bio?: string | null;
}

export interface UserUpdateRequest {
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  dob?: string | null;
  sex?: string | null;
  status?: UserStatus | null;
  studentCourse?: string | null;
  majorId?: number | null;
  specializationId?: number | null;
  subSpecializationId?: number | null;
  department?: string | null;
  expertise?: string | null;
  bio?: string | null;
}

export interface UserStatusUpdateRequest {
  status: UserStatus;
}

export interface CsvImportResultResponse {
  totalRecords: number;
  successCount: number;
  failedCount: number;
  errors: string[];
}

export interface UserQueryParams {
  search?: string;
  role?: Role | 'all';
  status?: UserStatus | 'all';
  page?: number;
  size?: number;
  sort?: string;
}

// ==============================================================================
// TASK-02A: Academic Catalog & Semester Types
// ==============================================================================

export type CourseStatus = 'ACTIVE' | 'INACTIVE' | 'DRAFT';

export type SemesterStatus = 'ACTIVE' | 'UPCOMING' | 'CLOSED' | 'ARCHIVED';

export interface CourseSummaryDto {
  id: number;
  code: string;
  name: string;
  credits: number;
}

export interface CourseResponse {
  id: number;
  code: string;
  name: string;
  description?: string | null;
  credits: number;
  numberOfSlots: number;
  status: CourseStatus;
  isCalculatedInGpa: boolean;
  prerequisites: CourseSummaryDto[];
  createdAt: string;
  updatedAt: string;
}

export interface CourseCreateRequest {
  code: string;
  name: string;
  description?: string | null;
  credits: number;
  numberOfSlots: number;
  status?: CourseStatus;
  isCalculatedInGpa?: boolean;
  prerequisiteIds?: number[];
}

export interface CourseUpdateRequest {
  name: string;
  description?: string | null;
  credits: number;
  numberOfSlots: number;
  status?: CourseStatus;
  isCalculatedInGpa?: boolean;
  prerequisiteIds?: number[];
}

export interface CourseQueryParams {
  search?: string;
  credits?: number;
  status?: CourseStatus | 'all';
  page?: number;
  size?: number;
  sort?: string;
}

export interface SemesterConfigDto {
  maxSlotPerDay: number;
  slotPerSubjectPerWeek: number;
  slotDuration: number;
  isPublished: boolean;
}

export interface SemesterResponse {
  id: number;
  code: string;
  name: string;
  startDate: string;
  endDate: string;
  status: SemesterStatus;
  description?: string | null;
  config?: SemesterConfigDto | null;
  totalWeeks?: number;
  createdAt: string;
  updatedAt: string;
}

export interface SemesterCreateRequest {
  code: string;
  name: string;
  startDate: string;
  endDate: string;
  status?: SemesterStatus;
  description?: string | null;
  maxSlotPerDay?: number;
  slotPerSubjectPerWeek?: number;
  slotDuration?: number;
  isPublished?: boolean;
}

export interface SemesterUpdateRequest {
  name: string;
  startDate: string;
  endDate: string;
  status?: SemesterStatus;
  description?: string | null;
  maxSlotPerDay?: number;
  slotPerSubjectPerWeek?: number;
  slotDuration?: number;
  isPublished?: boolean;
}

export interface SemesterQueryParams {
  search?: string;
  status?: SemesterStatus | 'all';
  page?: number;
  size?: number;
  sort?: string;
}


// ==============================================================================
// TASK-02B: Class Sections & Enrollment Management API Types
// ==============================================================================

export type ClassSectionStatus = 'OPEN' | 'ACTIVE' | 'CLOSED' | 'CANCELLED';
export type EnrollmentStatus = 'ENROLLED' | 'DROPPED' | 'CANCELLED';

export interface ClassSectionResponse {
  className: string;
  courseId: number;
  courseCode: string;
  courseName: string;
  credits: number;
  semesterId: number;
  semesterCode: string;
  semesterName: string;
  lecturerId?: number | null;
  lecturerCode?: string | null;
  lecturerName?: string | null;
  lecturerEmail?: string | null;
  numberOfSlots: number;
  maxStudents: number;
  currentEnrollment: number;
  status: ClassSectionStatus;
  gradesSubmitted: boolean;
  gradesSubmittedAt?: string | null;
  gradesPublished: boolean;
  gradesPublishedAt?: string | null;
  resitGradesPublished: boolean;
  resitGradesPublishedAt?: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface ClassSectionSummaryDto {
  className: string;
  courseId: number;
  courseCode: string;
  courseName: string;
  semesterId: number;
  semesterCode: string;
  semesterName: string;
  lecturerId?: number | null;
  lecturerName?: string | null;
  currentEnrollment: number;
  maxStudents: number;
  status: ClassSectionStatus;
}

export interface ClassSectionCreateRequest {
  className: string;
  courseId: number;
  semesterId: number;
  lecturerId?: number | null;
  maxStudents: number;
  numberOfSlots?: number;
  status?: ClassSectionStatus;
}

export interface ClassSectionUpdateRequest {
  lecturerId?: number | null;
  maxStudents: number;
  numberOfSlots?: number;
  status: ClassSectionStatus;
}

export interface ClassSectionQueryParams {
  search?: string;
  semesterId?: number;
  courseId?: number;
  lecturerId?: number;
  status?: ClassSectionStatus | 'all';
  page?: number;
  size?: number;
  sort?: string;
}

export interface ClassSectionStatsResponse {
  totalClasses: number;
  activeClasses: number;
  fullCapacityClasses: number;
  underCapacityClasses: number;
}

export interface EnrollmentResponse {
  id: number;
  className: string;
  courseId: number;
  courseCode: string;
  courseName: string;
  semesterId: number;
  semesterCode: string;
  studentId: number;
  studentCode: string;
  studentName: string;
  studentEmail: string;
  studentClass?: string | null;
  avatar?: string | null;
  faceDataStatus: FaceDataStatus;
  status: EnrollmentStatus;
  createdAt: string;
  updatedAt: string;
}

export interface EnrollmentCreateRequest {
  className: string;
  studentId: number;
}

export interface EnrollmentQueryParams {
  className?: string;
  studentId?: number;
  status?: EnrollmentStatus | 'all';
  search?: string;
  page?: number;
  size?: number;
  sort?: string;
}

// ==============================================================================
// Phân Hệ Cơ Sở Vật Chất & Hạ Tầng Wi-Fi AP (TASK-02C - F-13)
// ==============================================================================

export type RoomType = 'THEORY' | 'LAB' | 'AUDITORIUM' | 'MEETING' | 'OTHER';

export type RoomStatus = 'AVAILABLE' | 'OCCUPIED' | 'MAINTENANCE';

export type WifiApStatus = 'ACTIVE' | 'INACTIVE' | 'MAINTENANCE';

export interface RoomWifiAccessPointResponse {
  id: number;
  roomId: number;
  roomCode: string;
  roomName: string;
  wifiAccessPointId: number;
  ssid: string;
  bssid: string;
  apName?: string | null;
  location?: string | null;
  apStatus?: WifiApStatus;
  signalStrength?: number | null;
  isPrimary: boolean;
  positionNote?: string | null;
  createdAt: string;
  updatedAt?: string | null;
}

export interface RoomResponse {
  id: number;
  code: string;
  name: string;
  capacity: number;
  building?: string | null;
  description?: string | null;
  floor?: number | null;
  gridRow?: number | null;
  gridCol?: number | null;
  gridRowSpan?: number | null;
  gridColSpan?: number | null;
  type: RoomType;
  status: RoomStatus;
  wifiAccessPoints: RoomWifiAccessPointResponse[];
  assignedWifiCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface RoomDetailResponse extends RoomResponse {
  kioskName?: string | null;
  kioskStatus?: string | null;
}

export interface RoomCreateRequest {
  code: string;
  name: string;
  capacity: number;
  building?: string;
  description?: string;
  floor?: number;
  gridRow?: number;
  gridCol?: number;
  gridRowSpan?: number;
  gridColSpan?: number;
  type: RoomType;
  status?: RoomStatus;
}

export interface RoomUpdateRequest {
  code?: string;
  name: string;
  capacity: number;
  building?: string;
  description?: string;
  floor?: number;
  gridRow?: number;
  gridCol?: number;
  gridRowSpan?: number;
  gridColSpan?: number;
  type: RoomType;
  status: RoomStatus;
}

export interface RoomQueryParams {
  search?: string;
  building?: string;
  type?: RoomType | '';
  status?: RoomStatus | '';
  page?: number;
  size?: number;
  sort?: string;
}

export interface WifiAccessPointResponse {
  id: number;
  ssid: string;
  bssid: string;
  name?: string | null;
  location?: string | null;
  status: WifiApStatus;
  assignedRoomsCount: number;
  createdAt: string;
  updatedAt: string;
}

export interface WifiAccessPointCreateRequest {
  ssid: string;
  bssid: string;
  name?: string;
  location?: string;
  status?: WifiApStatus;
}

export interface WifiAccessPointUpdateRequest {
  ssid: string;
  bssid: string;
  name?: string;
  location?: string;
  status: WifiApStatus;
}

export interface WifiAccessPointQueryParams {
  search?: string;
  status?: WifiApStatus | '';
  page?: number;
  size?: number;
  sort?: string;
}

export interface AssignWifiApRequest {
  wifiAccessPointId?: number;
  ssid?: string;
  bssid?: string;
  apName?: string;
  location?: string;
  signalStrength?: number;
  isPrimary?: boolean;
  positionNote?: string;
}

export interface FacilityStatsResponse {
  totalRooms: number;
  availableRooms: number;
  occupiedRooms: number;
  maintenanceRooms: number;
  readinessRate: number;
  totalCapacity: number;
  activeStudentsCount: number;
  activeWifiAps: number;
  totalWifiAps: number;
  averageRssiDbm: number;
  onlineKiosks: number;
  totalKiosks: number;
  averageFaceLatencyMs: number;
}

// =============================================================================
// Timetable & Scheduling Types (TASK-02D - F-16)
// =============================================================================

export type TimetableSlotStatus = 'SCHEDULED' | 'COMPLETED' | 'CANCELLED' | 'RESCHEDULED';

export interface TimetableSlotResponse {
  id: number;
  className: string;
  courseCode?: string | null;
  courseName?: string | null;
  courseCategory?: string | null;
  semesterId?: number | null;
  semesterCode?: string | null;
  semesterName?: string | null;
  lecturerId?: number | null;
  lecturerCode?: string | null;
  lecturerName?: string | null;
  roomId?: number | null;
  roomCode?: string | null;
  roomName?: string | null;
  building?: string | null;
  roomCapacity?: number | null;
  attendanceMethod?: string | null;
  slotTypeId?: number | null;
  slotTypeName?: string | null;
  startTime?: string | null;
  endTime?: string | null;
  duration?: string | null;
  date: string;
  dayOfWeek: number;
  slotNumber: number;
  endSlotNumber?: number | null;
  periodDisplay?: string | null;
  currentEnrollment?: number | null;
  maxStudents?: number | null;
  status: TimetableSlotStatus;
  note?: string | null;
  hasAttendanceSession?: boolean;
  hasConflict?: boolean;
  conflictType?: string | null;
  conflictMessage?: string | null;
  createdAt?: string;
  updatedAt?: string;
}

export interface TimetableSlotCreateRequest {
  className: string;
  roomId?: number | null;
  slotTypeId?: number | null;
  date: string;
  slotNumber: number;
  endSlotNumber?: number | null;
  note?: string | null;
  recurring?: boolean;
  recurringUntil?: string | null;
}

export interface TimetableSlotUpdateRequest {
  roomId?: number | null;
  slotTypeId?: number | null;
  date?: string;
  slotNumber?: number;
  endSlotNumber?: number | null;
  status?: TimetableSlotStatus;
  note?: string | null;
}

export interface TimetableSlotQueryParams {
  startDate?: string;
  endDate?: string;
  date?: string;
  semesterId?: number;
  className?: string;
  lecturerId?: number;
  roomId?: number;
  status?: TimetableSlotStatus | '';
  paged?: boolean;
  page?: number;
  size?: number;
  sort?: string;
}

export interface TimetableConflictCheckRequest {
  excludeSlotId?: number | null;
  className?: string;
  lecturerId?: number | null;
  roomId?: number | null;
  date: string;
  slotNumber: number;
  endSlotNumber?: number | null;
}

export interface TimetableConflictCheckResponse {
  hasConflict: boolean;
  conflictType: string;
  conflictMessage: string;
  conflictingSlotId?: number | null;
  conflictingClassName?: string | null;
  conflictingRoomCode?: string | null;
  conflictingLecturerName?: string | null;
}

export interface SlotTypeResponse {
  id: number;
  name: string;
  slotIndex: number;
  startTime: string;
  endTime: string;
  description?: string | null;
  semesterId?: number | null;
  duration: string;
}

export interface AvailableRoomsQueryParams {
  date: string;
  slotNumber: number;
  endSlotNumber?: number | null;
  className?: string;
  recurring?: boolean;
  recurringUntil?: string;
  semesterId?: number;
  excludeSlotId?: number | null;
}

export interface TimetableStatsResponse {
  totalSlotsWeek: number;
  roomUtilizationRate: number;
  aiEquippedRoomsRatio: string;
  activeConflictsCount: number;
}

// ==============================================================================
// Face-ID Biometric Enrollment Types (F-17 & Stitch a17db05b39144990b49bee366c1e3b43)
// ==============================================================================
export interface FaceSampleDto {
  step: string;
  imageBase64: string;
}

export interface FaceRegistrationRequest {
  imageBase64: string;
  samples?: FaceSampleDto[];
  isReEnrollment?: boolean;
}

export interface FaceEnrollmentResponse {
  success: boolean;
  status: FaceDataStatus;
  registeredAt: string;
  version: string;
  modelName: string;
  embeddingDimension: number;
  tokenHash: string;
  message: string;
  studentName: string;
  studentCode: string;
}

export interface FaceStatusResponse {
  userId: number;
  studentCode: string;
  fullName: string;
  faceDataStatus: FaceDataStatus;
  isRegistered: boolean;
  registeredAt?: string | null;
  version: string;
  attempts?: number;
  blockedUntil?: string | null;
  tokenHash?: string | null;
}

// ==============================================================================
// Attendance Session Management Types (TASK-05)
// ==============================================================================
export * from './attendance';



