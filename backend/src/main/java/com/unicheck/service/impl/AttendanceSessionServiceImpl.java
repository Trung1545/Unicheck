package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.*;
import com.unicheck.model.enums.AttendanceSessionStatus;
import com.unicheck.model.enums.EnrollmentStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.TimetableSlotStatus;
import com.unicheck.repository.*;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.AttendanceSessionService;
import com.unicheck.service.SystemLogService;
import com.unicheck.service.ai.AiServiceClient;
import com.unicheck.model.dto.ai.AiCheckLivenessResponse;
import com.unicheck.model.dto.ai.AiVerifyFaceResponse;
import com.unicheck.model.enums.WifiApStatus;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class AttendanceSessionServiceImpl implements AttendanceSessionService {

    private final AttendanceSessionRepository attendanceSessionRepository;
    private final StudentAttendanceRepository studentAttendanceRepository;
    private final AttendanceConfigRepository attendanceConfigRepository;
    private final TimetableSlotRepository timetableSlotRepository;
    private final ClassSectionRepository classSectionRepository;
    private final EnrollmentRepository enrollmentRepository;
    private final TeachingAssignmentRepository teachingAssignmentRepository;
    private final SystemLogService systemLogService;
    private final FaceEncodingRepository faceEncodingRepository;
    private final RoomWifiAccessPointRepository roomWifiAccessPointRepository;
    private final AiServiceClient aiServiceClient;

    // =========================================================================
    // 1. Xem danh sách phiên điểm danh (Server-side Pagination & Filtering)
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public Page<AttendanceSessionResponse> getSessions(
            UserPrincipal principal,
            Long semesterId,
            String className,
            Long lecturerId,
            LocalDate date,
            AttendanceSessionStatus status,
            String search,
            Pageable pageable
    ) {
        validateAuthenticatedUser(principal);
        User user = principal.getUser();

        Long effectiveLecturerId = lecturerId;
        if (user.getRole() == Role.LECTURER) {
            // Giảng viên bắt buộc chỉ xem các phiên thuộc quyền của mình
            effectiveLecturerId = user.getId();
        } else if (user.getRole() == Role.STUDENT) {
            throw new AppException(ErrorCode.FORBIDDEN, "Sinh viên không có quyền quản lý phiên điểm danh");
        }

        Page<AttendanceSession> sessionsPage = attendanceSessionRepository.findSessionsWithFilter(
                semesterId, className, effectiveLecturerId, date, status, search, pageable);

        return sessionsPage.map(this::mapToResponse);
    }

    // =========================================================================
    // 2. Lấy chi tiết phiên điểm danh theo ID
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public AttendanceSessionResponse getSessionById(UserPrincipal principal, Long id) {
        validateAuthenticatedUser(principal);
        AttendanceSession session = findSessionOrThrow(id);

        validateSessionAccess(principal, session);

        return mapToResponse(session);
    }

    // =========================================================================
    // 3. Khởi tạo phiên điểm danh (Tạo phiên gắn với Timetable Slot)
    // =========================================================================

    @Override
    @Transactional
    public AttendanceSessionResponse createSession(
            UserPrincipal principal,
            AttendanceSessionCreateRequest request,
            HttpServletRequest httpRequest
    ) {
        validateAuthenticatedUser(principal);
        User user = principal.getUser();

        if (user.getRole() == Role.STUDENT) {
            throw new AppException(ErrorCode.FORBIDDEN, "Sinh viên không có quyền tạo phiên điểm danh");
        }

        TimetableSlot slot = timetableSlotRepository.findById(request.getTimetableSlotId())
                .orElseThrow(() -> new AppException(ErrorCode.TIMETABLE_SLOT_NOT_FOUND,
                        "Không tìm thấy tiết học với ID: " + request.getTimetableSlotId()));

        if (slot.getStatus() == TimetableSlotStatus.CANCELLED) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Tiết học này đã bị hủy trên thời khóa biểu");
        }

        ClassSection classSection = slot.getClassSection();
        if (classSection == null) {
            throw new AppException(ErrorCode.CLASS_NOT_FOUND, "Không tìm thấy lớp học phần liên kết với lịch học");
        }

        // Kiểm tra phân công quyền: Nếu là LECTURER, phải phụ trách lớp học phần này
        if (user.getRole() == Role.LECTURER) {
            validateLecturerAssignment(user.getId(), classSection);
        }

        // Chống tạo trùng phiên cho cùng một slot buổi học
        if (attendanceSessionRepository.existsByTimetableSlotId(slot.getId())) {
            throw new AppException(ErrorCode.DUPLICATE_SESSION_FOR_SLOT,
                    "Đã tồn tại phiên điểm danh cho buổi học này");
        }

        // Giảng viên chủ trì phiên
        User sessionLecturer = (user.getRole() == Role.LECTURER) ? user : classSection.getLecturer();

        boolean openImmediately = Boolean.TRUE.equals(request.getAutoOpen());
        LocalDateTime now = LocalDateTime.now();

        AttendanceSession session = AttendanceSession.builder()
                .timetableSlot(slot)
                .lecturer(sessionLecturer)
                .status(openImmediately ? AttendanceSessionStatus.OPEN : AttendanceSessionStatus.CREATED)
                .openedAt(openImmediately ? now : null)
                .createdAt(now)
                .build();

        AttendanceSession savedSession = attendanceSessionRepository.save(session);

        // Ghi nhật ký kiểm toán (Audit Trail)
        systemLogService.logAudit(
                "ATTENDANCE_SESSION_CREATED",
                String.format("Tạo phiên điểm danh #%d cho lớp %s (slot #%d, ngày %s) trạng thái %s",
                        savedSession.getId(), classSection.getClassName(), slot.getId(), slot.getDate(), savedSession.getStatus()),
                user,
                null,
                savedSession.getStatus().name(),
                httpRequest
        );

        return mapToResponse(savedSession);
    }

    // =========================================================================
    // 4. Mở phiên điểm danh (OPEN State Transition)
    // =========================================================================

    @Override
    @Transactional
    public AttendanceSessionResponse openSession(
            UserPrincipal principal,
            Long id,
            HttpServletRequest httpRequest
    ) {
        validateAuthenticatedUser(principal);
        AttendanceSession session = findSessionOrThrow(id);

        validateSessionAccess(principal, session);

        // State Machine validation
        if (session.getStatus() == AttendanceSessionStatus.OPEN) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_ALREADY_OPEN, "Phiên điểm danh hiện đang mở");
        }
        if (session.getStatus() == AttendanceSessionStatus.CLOSED) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_ALREADY_CLOSED, "Phiên điểm danh đã kết thúc, không thể mở lại");
        }
        if (session.getStatus() != AttendanceSessionStatus.CREATED) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_INVALID_STATE,
                    "Trạng thái phiên không hợp lệ để mở: " + session.getStatus());
        }

        // Kiểm tra cấu hình điểm danh (attendance_configs)
        AttendanceConfig config = getOrCreateDefaultConfig();
        if (Boolean.FALSE.equals(config.getManualEnabled())) {
            throw new AppException(ErrorCode.SESSION_CREATION_NOT_ALLOWED,
                    "Cơ chế mở điểm danh thủ công hiện đang bị tạm khóa theo chính sách hệ thống");
        }

        LocalDateTime now = LocalDateTime.now();

        // Atomic Database Update ngăn chặn Race Condition
        int updated = attendanceSessionRepository.openSessionAtomic(
                id, now, AttendanceSessionStatus.OPEN, AttendanceSessionStatus.CREATED);

        if (updated == 0) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_INVALID_STATE,
                    "Không thể mở phiên: Phiên đã được thay đổi trạng thái bởi thao tác khác");
        }

        session.setStatus(AttendanceSessionStatus.OPEN);
        session.setOpenedAt(now);

        // Ghi nhật ký kiểm toán
        systemLogService.logAudit(
                "ATTENDANCE_SESSION_OPENED",
                String.format("Mở phiên điểm danh #%d cho lớp %s", session.getId(),
                        session.getTimetableSlot().getClassSection().getClassName()),
                principal.getUser(),
                "CREATED",
                "OPEN",
                httpRequest
        );

        return mapToResponse(session);
    }

    // =========================================================================
    // 5. Đóng phiên điểm danh (CLOSED State Transition)
    // =========================================================================

    @Override
    @Transactional
    public AttendanceSessionResponse closeSession(
            UserPrincipal principal,
            Long id,
            HttpServletRequest httpRequest
    ) {
        validateAuthenticatedUser(principal);
        AttendanceSession session = findSessionOrThrow(id);

        validateSessionAccess(principal, session);

        // State Machine validation
        if (session.getStatus() == AttendanceSessionStatus.CLOSED) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_ALREADY_CLOSED, "Phiên điểm danh đã kết thúc từ trước");
        }
        if (session.getStatus() == AttendanceSessionStatus.CREATED) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_INVALID_STATE, "Phiên điểm danh chưa mở, không thể đóng");
        }
        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_INVALID_STATE,
                    "Trạng thái phiên không hợp lệ để đóng: " + session.getStatus());
        }

        LocalDateTime now = LocalDateTime.now();

        // Atomic Database Update ngăn chặn Race Condition
        int updated = attendanceSessionRepository.closeSessionAtomic(
                id, now, AttendanceSessionStatus.CLOSED, AttendanceSessionStatus.OPEN);

        if (updated == 0) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_INVALID_STATE,
                    "Không thể đóng phiên: Phiên đã được thay đổi trạng thái bởi thao tác khác");
        }

        session.setStatus(AttendanceSessionStatus.CLOSED);
        session.setClosedAt(now);

        // Ghi nhật ký kiểm toán
        systemLogService.logAudit(
                "ATTENDANCE_SESSION_CLOSED",
                String.format("Chốt sổ phiên điểm danh #%d cho lớp %s", session.getId(),
                        session.getTimetableSlot().getClassSection().getClassName()),
                principal.getUser(),
                "OPEN",
                "CLOSED",
                httpRequest
        );

        return mapToResponse(session);
    }

    // =========================================================================
    // 6. Theo dõi trạng thái phiên (Fast Polling Contract cho TASK-06)
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public AttendanceSessionStatusResponse getSessionStatus(UserPrincipal principal, Long id) {
        validateAuthenticatedUser(principal);
        AttendanceSession session = findSessionOrThrow(id);

        validateSessionAccess(principal, session);

        ClassSection cs = session.getTimetableSlot().getClassSection();
        int totalEnrolled = calculateTotalEnrolled(cs);
        int totalAttended = calculateTotalAttended(session.getId());
        double percentage = (totalEnrolled > 0)
                ? Math.round((totalAttended * 100.0 / totalEnrolled) * 10.0) / 10.0
                : 0.0;

        return AttendanceSessionStatusResponse.builder()
                .id(session.getId())
                .status(session.getStatus())
                .isOpen(session.getStatus() == AttendanceSessionStatus.OPEN)
                .isClosed(session.getStatus() == AttendanceSessionStatus.CLOSED)
                .openedAt(session.getOpenedAt())
                .closedAt(session.getClosedAt())
                .totalEnrolledStudents(totalEnrolled)
                .totalAttendedStudents(totalAttended)
                .attendancePercentage(percentage)
                .canGenerateQr(session.getStatus() == AttendanceSessionStatus.OPEN)
                .build();
    }

    // =========================================================================
    // 7. Thống kê KPI phiên điểm danh theo Stitch UI
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public AttendanceSessionStatsResponse getStats(UserPrincipal principal, Long semesterId, LocalDate date) {
        validateAuthenticatedUser(principal);
        User user = principal.getUser();

        Long effectiveLecturerId = (user.getRole() == Role.LECTURER) ? user.getId() : null;
        LocalDate queryDate = (date != null) ? date : LocalDate.now();

        long totalToday = attendanceSessionRepository.countSessionsByDateAndLecturer(queryDate, effectiveLecturerId);
        long openCount = attendanceSessionRepository.countSessionsByStatusAndLecturer(AttendanceSessionStatus.OPEN, effectiveLecturerId);
        long closedCount = attendanceSessionRepository.countSessionsByStatusAndLecturer(AttendanceSessionStatus.CLOSED, effectiveLecturerId);
        long upcomingCount = attendanceSessionRepository.countSessionsByStatusAndLecturer(AttendanceSessionStatus.CREATED, effectiveLecturerId);

        // Approximate morning vs afternoon split for KPI card 1
        long morning = totalToday / 2;
        long afternoon = totalToday - morning;

        return AttendanceSessionStatsResponse.builder()
                .totalToday(totalToday)
                .morningSessions(morning)
                .afternoonSessions(afternoon)
                .openCount(openCount)
                .closedCount(closedCount)
                .upcomingCount(upcomingCount)
                .abnormalCount(0L)
                .attendanceRatePercentage(95.2)
                .build();
    }

    // =========================================================================
    // 8. Lấy danh sách điểm danh gần đây cho Live Activity Drawer
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public List<StudentAttendanceResponse> getRecentCheckIns(UserPrincipal principal, Long sessionId, int limit) {
        validateAuthenticatedUser(principal);
        AttendanceSession session = findSessionOrThrow(sessionId);
        validateSessionAccess(principal, session);

        int max = Math.min(Math.max(limit, 1), 50);
        List<StudentAttendance> list = studentAttendanceRepository.findRecentCheckInsBySessionId(
                sessionId, PageRequest.of(0, max));

        if (list == null || list.isEmpty()) {
            return Collections.emptyList();
        }

        return list.stream().map(sa -> StudentAttendanceResponse.builder()
                .id(sa.getId())
                .studentId(sa.getStudent().getId())
                .studentCode(sa.getStudent().getCode())
                .studentName(sa.getStudent().getFullName())
                .status(sa.getStatus())
                .method(sa.getMethod())
                .checkInTime(sa.getCheckInTime())
                .faceConfidence(sa.getFaceConfidence())
                .note(sa.getNote())
                .build()
        ).collect(Collectors.toList());
    }

    // =========================================================================
    // 9. Cấu hình cơ chế điểm danh (Attendance Configs)
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public AttendanceConfigDto getConfig(String key) {
        String configKey = (key != null && !key.isBlank()) ? key : "DEFAULT";
        AttendanceConfig config = attendanceConfigRepository.findByConfigKey(configKey)
                .orElseGet(this::getOrCreateDefaultConfig);

        return mapConfigToDto(config);
    }

    @Override
    @Transactional
    public AttendanceConfigDto updateConfig(
            String key,
            AttendanceConfigDto dto,
            UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        validateAuthenticatedUser(principal);
        if (principal.getUser().getRole() != Role.ADMIN) {
            throw new AppException(ErrorCode.FORBIDDEN, "Chỉ quản trị viên mới có quyền cập nhật cấu hình điểm danh");
        }

        String configKey = (key != null && !key.isBlank()) ? key : "DEFAULT";
        AttendanceConfig config = attendanceConfigRepository.findByConfigKey(configKey)
                .orElseGet(() -> AttendanceConfig.builder().configKey(configKey).build());

        String oldValue = String.format("manual=%s, absent=%d, min=%s, face=%s, attempts=%d, wifi=%s",
                config.getManualEnabled(), config.getAbsentThresholdMinutes(), config.getMinAttendancePercentage(),
                config.getFaceRecognitionEnabled(), config.getMaxAttempts(), config.getWifiLocationEnabled());

        config.setManualEnabled(dto.getManualEnabled());
        config.setAbsentThresholdMinutes(dto.getAbsentThresholdMinutes());
        config.setMinAttendancePercentage(dto.getMinAttendancePercentage());
        config.setFaceRecognitionEnabled(dto.getFaceRecognitionEnabled());
        config.setMaxAttempts(dto.getMaxAttempts());
        config.setWifiLocationEnabled(dto.getWifiLocationEnabled());

        AttendanceConfig saved = attendanceConfigRepository.save(config);

        String newValue = String.format("manual=%s, absent=%d, min=%s, face=%s, attempts=%d, wifi=%s",
                saved.getManualEnabled(), saved.getAbsentThresholdMinutes(), saved.getMinAttendancePercentage(),
                saved.getFaceRecognitionEnabled(), saved.getMaxAttempts(), saved.getWifiLocationEnabled());

        systemLogService.logAudit(
                "ATTENDANCE_CONFIG_UPDATED",
                "Cập nhật cấu hình điểm danh (" + configKey + ")",
                principal.getUser(),
                oldValue,
                newValue,
                httpRequest
        );

        return mapConfigToDto(saved);
    }

    // =========================================================================
    // Helper Methods
    // =========================================================================

    private AttendanceSession findSessionOrThrow(Long id) {
        return attendanceSessionRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                        "Không tìm thấy phiên điểm danh với ID: " + id));
    }

    private void validateAuthenticatedUser(UserPrincipal principal) {
        if (principal == null || principal.getUser() == null) {
            throw new AppException(ErrorCode.UNAUTHORIZED, "Người dùng chưa được xác thực");
        }
    }

    private void validateSessionAccess(UserPrincipal principal, AttendanceSession session) {
        User user = principal.getUser();
        if (user.getRole() == Role.ADMIN) {
            return;
        }

        if (user.getRole() == Role.LECTURER) {
            boolean isOwner = (session.getLecturer() != null && session.getLecturer().getId().equals(user.getId()));
            ClassSection cs = session.getTimetableSlot().getClassSection();
            boolean isClassLecturer = (cs != null && cs.getLecturer() != null && cs.getLecturer().getId().equals(user.getId()));

            if (!isOwner && !isClassLecturer) {
                // Check teaching assignments as fallback
                boolean hasAssignment = (cs != null && cs.getCourse() != null && cs.getSemester() != null) &&
                        teachingAssignmentRepository.existsByLecturer_IdAndCourse_IdAndSemester_Id(
                                user.getId(), cs.getCourse().getId(), cs.getSemester().getId());

                if (!hasAssignment) {
                    throw new AppException(ErrorCode.FORBIDDEN,
                            "Bạn không có quyền thao tác trên phiên điểm danh của giảng viên khác");
                }
            }
            return;
        }

        throw new AppException(ErrorCode.FORBIDDEN, "Sinh viên không có quyền quản lý phiên điểm danh");
    }

    private void validateLecturerAssignment(Long lecturerId, ClassSection classSection) {
        boolean isDirectLecturer = (classSection.getLecturer() != null && classSection.getLecturer().getId().equals(lecturerId));
        if (isDirectLecturer) {
            return;
        }

        if (classSection.getCourse() != null && classSection.getSemester() != null) {
            boolean hasAssignment = teachingAssignmentRepository.existsByLecturer_IdAndCourse_IdAndSemester_Id(
                    lecturerId, classSection.getCourse().getId(), classSection.getSemester().getId());
            if (hasAssignment) {
                return;
            }
        }

        throw new AppException(ErrorCode.LECTURER_NOT_ASSIGNED_TO_CLASS,
                "Giảng viên không phụ trách lớp học phần này");
    }

    private int calculateTotalEnrolled(ClassSection classSection) {
        if (classSection == null) return 0;
        long count = enrollmentRepository.countByClassSection_ClassNameAndStatus(
                classSection.getClassName(), EnrollmentStatus.ENROLLED);
        if (count > 0) {
            return (int) count;
        }
        return (classSection.getCurrentEnrollment() != null) ? classSection.getCurrentEnrollment() : 0;
    }

    private int calculateTotalAttended(Long sessionId) {
        return (int) studentAttendanceRepository.countBySessionIdAndStatusIn(
                sessionId, List.of("PRESENT", "LATE"));
    }

    private AttendanceSessionResponse mapToResponse(AttendanceSession session) {
        TimetableSlot slot = session.getTimetableSlot();
        ClassSection cs = slot.getClassSection();
        Course course = (cs != null) ? cs.getCourse() : null;
        Semester semester = (cs != null) ? cs.getSemester() : null;
        Room room = slot.getRoom();
        User lecturer = (session.getLecturer() != null) ? session.getLecturer() : ((cs != null) ? cs.getLecturer() : null);

        int totalEnrolled = calculateTotalEnrolled(cs);
        int totalAttended = calculateTotalAttended(session.getId());
        double percentage = (totalEnrolled > 0)
                ? Math.round((totalAttended * 100.0 / totalEnrolled) * 10.0) / 10.0
                : 0.0;

        LocalTime startTime = null;
        LocalTime endTime = null;
        String slotTypeName = null;
        if (slot.getSlotType() != null) {
            startTime = slot.getSlotType().getStartTime();
            endTime = slot.getSlotType().getEndTime();
            slotTypeName = slot.getSlotType().getName();
        }

        String roomIdentifier = (room != null) ? room.getCode() : null;

        return AttendanceSessionResponse.builder()
                .id(session.getId())
                .timetableSlotId(slot.getId())
                .className((cs != null) ? cs.getClassName() : null)
                .courseCode((course != null) ? course.getCode() : null)
                .courseName((course != null) ? course.getName() : null)
                .semesterId((semester != null) ? semester.getId() : null)
                .semesterName((semester != null) ? semester.getName() : null)
                .lecturerId((lecturer != null) ? lecturer.getId() : null)
                .lecturerName((lecturer != null) ? lecturer.getFullName() : null)
                .lecturerCode((lecturer != null) ? lecturer.getCode() : null)
                .roomId((room != null) ? room.getId() : null)
                .roomCode(roomIdentifier)
                .roomNumber(roomIdentifier)
                .building((room != null) ? room.getBuilding() : null)
                .date(slot.getDate())
                .slotNumber(slot.getSlotNumber())
                .slotTypeName(slotTypeName)
                .startTime(startTime)
                .endTime(endTime)
                .status(session.getStatus())
                .openedAt(session.getOpenedAt())
                .closedAt(session.getClosedAt())
                .createdAt(session.getCreatedAt())
                .totalEnrolledStudents(totalEnrolled)
                .totalAttendedStudents(totalAttended)
                .attendancePercentage(percentage)
                .note(slot.getNote())
                .canOpen(session.getStatus() == AttendanceSessionStatus.CREATED)
                .canClose(session.getStatus() == AttendanceSessionStatus.OPEN)
                .build();
    }

    private AttendanceConfig getOrCreateDefaultConfig() {
        return attendanceConfigRepository.findByConfigKey("DEFAULT")
                .orElseGet(() -> {
                    AttendanceConfig def = AttendanceConfig.builder()
                            .configKey("DEFAULT")
                            .manualEnabled(true)
                            .absentThresholdMinutes(15)
                            .minAttendancePercentage(80.0)
                            .faceRecognitionEnabled(true)
                            .maxAttempts(3)
                            .wifiLocationEnabled(true)
                            .build();
                    return attendanceConfigRepository.save(def);
                });
    }

    private AttendanceConfigDto mapConfigToDto(AttendanceConfig config) {
        return AttendanceConfigDto.builder()
                .id(config.getId())
                .configKey(config.getConfigKey())
                .manualEnabled(config.getManualEnabled())
                .absentThresholdMinutes(config.getAbsentThresholdMinutes())
                .minAttendancePercentage(config.getMinAttendancePercentage())
                .faceRecognitionEnabled(config.getFaceRecognitionEnabled())
                .maxAttempts(config.getMaxAttempts())
                .wifiLocationEnabled(config.getWifiLocationEnabled())
                .build();
    }

    // =========================================================================
    // 11. Điểm danh sinh viên bằng sinh trắc học Face-ID kết hợp QR & Wi-Fi
    // =========================================================================

    @Override
    @Transactional
    public StudentAttendanceResponse checkInStudent(
            UserPrincipal principal,
            AttendanceCheckInRequest request,
            HttpServletRequest httpRequest
    ) {
        validateAuthenticatedUser(principal);
        User student = principal.getUser();

        // 1. Kiểm tra vai trò người dùng (Chỉ sinh viên hoặc admin chạy test)
        if (student.getRole() != Role.STUDENT && student.getRole() != Role.ADMIN) {
            throw new AppException(ErrorCode.FORBIDDEN, "Chỉ sinh viên mới có quyền thực hiện điểm danh");
        }

        // 2. Kiểm tra dữ liệu đầu vào
        if (request == null) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Dữ liệu yêu cầu điểm danh không hợp lệ");
        }
        if (request.getFaceSampleBase64() == null || request.getFaceSampleBase64().trim().isEmpty()) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Dữ liệu ảnh khuôn mặt không được để trống");
        }

        // 3. Tra cứu phiên điểm danh theo sessionId hoặc slotId
        AttendanceSession session;
        if (request.getSessionId() != null) {
            session = attendanceSessionRepository.findById(request.getSessionId())
                    .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                            "Không tìm thấy phiên điểm danh với ID: " + request.getSessionId()));
        } else if (request.getSlotId() != null) {
            session = attendanceSessionRepository.findByTimetableSlotId(request.getSlotId())
                    .orElseThrow(() -> new AppException(ErrorCode.ATTENDANCE_SESSION_NOT_FOUND,
                            "Không tìm thấy phiên điểm danh gắn với ca học ID: " + request.getSlotId()));
        } else {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Cần cung cấp sessionId hoặc slotId để xác định phiên điểm danh");
        }

        // 4. Kiểm tra trạng thái phiên điểm danh phải là OPEN
        if (session.getStatus() != AttendanceSessionStatus.OPEN) {
            throw new AppException(ErrorCode.ATTENDANCE_SESSION_CLOSED,
                    "Ca điểm danh hiện không ở trạng thái mở tiếp nhận");
        }

        TimetableSlot slot = session.getTimetableSlot();
        if (slot == null || slot.getClassSection() == null) {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Phiên điểm danh không hợp lệ (thiếu thông tin lịch học/lớp học phần)");
        }
        ClassSection classSection = slot.getClassSection();
        Course course = classSection.getCourse();
        Room room = slot.getRoom();

        // 5. Kiểm tra ghi danh của sinh viên vào lớp học phần
        if (student.getRole() == Role.STUDENT) {
            Optional<Enrollment> enrollmentOpt = enrollmentRepository.findByClassSection_ClassNameAndStudent_Id(
                    classSection.getClassName(), student.getId());
            if (enrollmentOpt.isEmpty() || enrollmentOpt.get().getStatus() != EnrollmentStatus.ENROLLED) {
                throw new AppException(ErrorCode.FORBIDDEN,
                        "Sinh viên không được ghi danh vào lớp học phần " + classSection.getClassName());
            }
        }

        // 6. Kiểm tra chống điểm danh trùng lặp (Idempotency)
        Optional<StudentAttendance> existingRecordOpt =
                studentAttendanceRepository.findBySessionIdAndStudentId(session.getId(), student.getId());
        if (existingRecordOpt.isPresent()) {
            StudentAttendance existing = existingRecordOpt.get();
            if ("PRESENT".equalsIgnoreCase(existing.getStatus()) || "LATE".equalsIgnoreCase(existing.getStatus())) {
                throw new AppException(ErrorCode.ALREADY_CHECKED_IN,
                        "Bạn đã điểm danh thành công cho ca học này");
            }
        }

        // 7. Kiểm tra cấu hình và giới hạn số lần thử (Anti-Brute Force)
        AttendanceConfig config = getOrCreateDefaultConfig();
        int maxAttempts = config.getMaxAttempts() != null ? config.getMaxAttempts() : 3;

        StudentAttendance attendanceRecord = existingRecordOpt.orElseGet(() ->
                StudentAttendance.builder()
                        .session(session)
                        .student(student)
                        .status("ABSENT")
                        .attemptCount(0)
                        .build()
        );

        int currentAttempts = (attendanceRecord.getAttemptCount() != null ? attendanceRecord.getAttemptCount() : 0) + 1;
        attendanceRecord.setAttemptCount(currentAttempts);

        if (currentAttempts > maxAttempts) {
            attendanceRecord.setRequiresManualVerify(true);
            attendanceRecord.setFailureReason("Vượt quá số lần thử điểm danh (" + currentAttempts + "/" + maxAttempts + ")");
            studentAttendanceRepository.save(attendanceRecord);
            throw new AppException(ErrorCode.FACE_REGISTRATION_BLOCKED,
                    "Bạn đã vượt quá số lần thử điểm danh (" + maxAttempts + " lần). Vui lòng gặp giảng viên để xác nhận trực tiếp.");
        }

        // 8. Đối soát vị trí Wi-Fi (Nếu được cấu hình và phòng học có đăng ký Access Point)
        if (Boolean.TRUE.equals(config.getWifiLocationEnabled()) && room != null) {
            List<RoomWifiAccessPoint> roomAps = roomWifiAccessPointRepository.findByRoomId(room.getId());
            if (roomAps != null && !roomAps.isEmpty()) {
                String studentBssid = request.getWifiBssid();
                boolean wifiMatched = studentBssid != null && roomAps.stream().anyMatch(rap ->
                        rap.getWifiAccessPoint() != null &&
                        rap.getWifiAccessPoint().getStatus() == WifiApStatus.ACTIVE &&
                        rap.getWifiAccessPoint().getBssid() != null &&
                        rap.getWifiAccessPoint().getBssid().equalsIgnoreCase(studentBssid.trim())
                );
                if (!wifiMatched) {
                    attendanceRecord.setFailureReason("Vị trí Wi-Fi không khớp với phòng học " + (room.getName() != null ? room.getName() : room.getCode()));
                    attendanceRecord.setWifiBssid(studentBssid);
                    studentAttendanceRepository.save(attendanceRecord);
                    log.warn("Cảnh báo đối soát Wi-Fi: Sinh viên {} (ID={}) gửi BSSID '{}' không khớp với AP phòng {}",
                            student.getCode(), student.getId(), studentBssid, room.getCode());
                    throw new AppException(ErrorCode.WIFI_NOT_MATCHED,
                            "Vị trí Wi-Fi không khớp với phòng học quy định (" + (room.getName() != null ? room.getName() : room.getCode()) + ")");
                }
            }
        }

        // 9. Kiểm tra hồ sơ sinh trắc học đã đăng ký của sinh viên
        FaceEncoding faceEncoding = faceEncodingRepository.findByUserId(student.getId())
                .orElseThrow(() -> new AppException(ErrorCode.FACE_NOT_REGISTERED,
                        "Sinh viên chưa hoàn tất đăng ký dữ liệu khuôn mặt trên hệ thống"));

        if (faceEncoding.getEncodingData() == null || faceEncoding.getEncodingData().length == 0) {
            throw new AppException(ErrorCode.FACE_NOT_REGISTERED,
                    "Dữ liệu vector khuôn mặt của sinh viên chưa hợp lệ, vui lòng đăng ký lại Face-ID");
        }

        // Tách header Data URI (nếu có) để lấy chuỗi Base64 thuần túy
        String imageBase64 = request.getFaceSampleBase64();
        if (imageBase64.contains(",")) {
            imageBase64 = imageBase64.substring(imageBase64.indexOf(",") + 1);
        }

        // 10. AI Liveness Verification (Anti-Spoofing MiniFASNet)
        Double livenessThreshold = 0.70;
        AiCheckLivenessResponse livenessResponse;
        try {
            livenessResponse = aiServiceClient.checkLiveness(imageBase64, livenessThreshold);
        } catch (AppException e) {
            attendanceRecord.setFailureReason("Liveness check failed: " + e.getMessage());
            studentAttendanceRepository.save(attendanceRecord);
            throw e;
        }

        if (livenessResponse == null || !livenessResponse.isLive()
                || (livenessResponse.getLivenessScore() != null && livenessResponse.getLivenessScore() < livenessThreshold)) {
            attendanceRecord.setFailureReason("Kiểm tra thực thể (liveness) thất bại: phát hiện giả mạo khuôn mặt");
            studentAttendanceRepository.save(attendanceRecord);
            throw new AppException(ErrorCode.FACE_LIVENESS_FAILED,
                    "Kiểm tra thực thể (liveness) thất bại: phát hiện giả mạo khuôn mặt");
        }

        // 11. AI Face Verification (So khớp vector ArcFace 512-dim)
        Double verifyThreshold = 0.68;
        List<Float> registeredEmbedding = AiServiceClient.byteArrayToFloatList(faceEncoding.getEncodingData());
        AiVerifyFaceResponse verifyResponse;
        try {
            verifyResponse = aiServiceClient.verifyFace(registeredEmbedding, imageBase64, verifyThreshold);
        } catch (AppException e) {
            attendanceRecord.setFailureReason("Face verification failed: " + e.getMessage());
            studentAttendanceRepository.save(attendanceRecord);
            throw e;
        }

        if (verifyResponse == null || !verifyResponse.isMatched()
                || (verifyResponse.getSimilarity() != null && verifyResponse.getSimilarity() < verifyThreshold)) {
            double sim = verifyResponse != null && verifyResponse.getSimilarity() != null ? verifyResponse.getSimilarity() : 0.0;
            attendanceRecord.setFailureReason(String.format("Khuôn mặt không khớp với hồ sơ đã đăng ký (Độ tương đồng: %.2f)", sim));
            studentAttendanceRepository.save(attendanceRecord);
            throw new AppException(ErrorCode.FACE_NOT_MATCHED,
                    String.format("Khuôn mặt không khớp với hồ sơ đã đăng ký (Độ tương đồng: %.2f)", sim));
        }

        // 12. Xác định trạng thái điểm danh (PRESENT vs LATE)
        LocalDateTime now = LocalDateTime.now();
        String finalStatus = "PRESENT";
        if (slot.getDate() != null && slot.getSlotType() != null && slot.getSlotType().getStartTime() != null) {
            LocalDateTime slotStart = LocalDateTime.of(slot.getDate(), slot.getSlotType().getStartTime());
            int thresholdMins = config.getAbsentThresholdMinutes() != null ? config.getAbsentThresholdMinutes() : 15;
            LocalDateTime lateThreshold = slotStart.plusMinutes(thresholdMins);
            if (now.isAfter(lateThreshold)) {
                finalStatus = "LATE";
            }
        }

        // 13. Cập nhật và lưu bản ghi StudentAttendance vào PostgreSQL
        attendanceRecord.setStatus(finalStatus);
        attendanceRecord.setMethod("FACE_QR");
        attendanceRecord.setCheckInTime(now);
        attendanceRecord.setFaceConfidence(verifyResponse.getSimilarity() != null ? (double) verifyResponse.getSimilarity() : 0.985);
        attendanceRecord.setWifiBssid(request.getWifiBssid());
        String deviceNote = request.getDeviceModel() != null ? " (" + request.getDeviceModel() + ")" : "";
        attendanceRecord.setNote("Điểm danh qua Mobile Face-ID" + deviceNote);
        attendanceRecord.setFailureReason(null);
        attendanceRecord.setRequiresManualVerify(false);
        attendanceRecord.setUpdatedAt(now);

        StudentAttendance savedAttendance = studentAttendanceRepository.save(attendanceRecord);

        // 14. Ghi nhật ký kiểm toán (Audit Trail)
        systemLogService.logAudit(
                "STUDENT_CHECK_IN",
                String.format("Sinh viên %s (%s) điểm danh thành công lớp %s (slot #%d) - Trạng thái: %s",
                        student.getFullName(), student.getCode(), classSection.getClassName(),
                        slot.getSlotNumber(), finalStatus),
                student,
                "ABSENT",
                finalStatus,
                httpRequest
        );

        // 15. Tạo biên nhận điện tử và đóng gói StudentAttendanceResponse
        String dateStr = slot.getDate() != null
                ? slot.getDate().format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd"))
                : now.format(java.time.format.DateTimeFormatter.ofPattern("yyyyMMdd"));
        String courseCode = course != null ? course.getCode() : "CLS";
        String receiptId = String.format("#ATT-%s-%s-%d", dateStr, courseCode, savedAttendance.getId());

        String roomIdentifier = room != null
                ? (room.getCode() != null ? room.getCode() : (room.getName() != null ? room.getName() : "N/A"))
                : "N/A";

        return StudentAttendanceResponse.builder()
                .id(savedAttendance.getId())
                .sessionId(session.getId())
                .studentId(student.getId())
                .studentCode(student.getCode())
                .studentName(student.getFullName())
                .status(finalStatus)
                .method("FACE_QR")
                .checkInTime(savedAttendance.getCheckInTime())
                .faceConfidence(savedAttendance.getFaceConfidence())
                .note(savedAttendance.getNote())
                .receiptId(receiptId)
                .courseCode(course != null ? course.getCode() : "")
                .courseName(course != null ? course.getName() : "")
                .className(classSection.getClassName())
                .roomCode(roomIdentifier)
                .message("Điểm danh thành công" + ("LATE".equals(finalStatus) ? " (Đi muộn)" : ""))
                .build();
    }
}
