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
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
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

        Specification<AttendanceSession> spec = createSpecification(
                semesterId, className, effectiveLecturerId, date, status, search);
        Page<AttendanceSession> sessionsPage = attendanceSessionRepository.findAll(spec, pageable);

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

    private Specification<AttendanceSession> createSpecification(
            Long semesterId,
            String className,
            Long lecturerId,
            LocalDate date,
            AttendanceSessionStatus status,
            String search
    ) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            Join<AttendanceSession, TimetableSlot> ts = root.join("timetableSlot", JoinType.INNER);
            Join<TimetableSlot, ClassSection> cs = ts.join("classSection", JoinType.INNER);

            if (semesterId != null) {
                predicates.add(cb.equal(cs.get("semester").get("id"), semesterId));
            }
            if (StringUtils.hasText(className)) {
                predicates.add(cb.equal(cs.get("className"), className.trim()));
            }
            if (lecturerId != null) {
                Predicate sessionLecturer = cb.equal(root.get("lecturer").get("id"), lecturerId);
                Predicate classLecturer = cb.equal(cs.get("lecturer").get("id"), lecturerId);
                predicates.add(cb.or(sessionLecturer, classLecturer));
            }
            if (date != null) {
                predicates.add(cb.equal(ts.get("date"), date));
            }
            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }
            if (StringUtils.hasText(search)) {
                String pattern = "%" + search.trim().toLowerCase() + "%";
                Join<ClassSection, Course> c = cs.join("course", JoinType.LEFT);
                Join<TimetableSlot, Room> r = ts.join("room", JoinType.LEFT);
                Join<AttendanceSession, User> l = root.join("lecturer", JoinType.LEFT);

                predicates.add(cb.or(
                        cb.like(cb.lower(cs.get("className")), pattern),
                        cb.like(cb.lower(c.get("name")), pattern),
                        cb.like(cb.lower(c.get("code")), pattern),
                        cb.like(cb.lower(r.get("code")), pattern),
                        cb.like(cb.lower(l.get("fullName")), pattern)
                ));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}
