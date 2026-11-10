package com.unicheck.service;

import com.unicheck.model.dto.*;
import com.unicheck.model.enums.AttendanceSessionStatus;
import com.unicheck.security.UserPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;

public interface AttendanceSessionService {

    Page<AttendanceSessionResponse> getSessions(
            UserPrincipal principal,
            Long semesterId,
            String className,
            Long lecturerId,
            LocalDate date,
            AttendanceSessionStatus status,
            String search,
            Pageable pageable
    );

    AttendanceSessionResponse getSessionById(UserPrincipal principal, Long id);

    AttendanceSessionResponse createSession(
            UserPrincipal principal,
            AttendanceSessionCreateRequest request,
            HttpServletRequest httpRequest
    );

    AttendanceSessionResponse openSession(
            UserPrincipal principal,
            Long id,
            AttendanceSessionOpenRequest openRequest,
            HttpServletRequest httpRequest
    );

    default AttendanceSessionResponse openSession(
            UserPrincipal principal,
            Long id,
            HttpServletRequest httpRequest
    ) {
        return openSession(principal, id, null, httpRequest);
    }

    AttendanceSessionResponse updateQrInterval(
            UserPrincipal principal,
            Long id,
            AttendanceSessionOpenRequest request,
            HttpServletRequest httpRequest
    );

    AttendanceSessionResponse closeSession(
            UserPrincipal principal,
            Long id,
            HttpServletRequest httpRequest
    );

    AttendanceSessionStatusResponse getSessionStatus(UserPrincipal principal, Long id);

    AttendanceSessionStatsResponse getStats(UserPrincipal principal, Long semesterId, LocalDate date);

    List<StudentAttendanceResponse> getRecentCheckIns(UserPrincipal principal, Long sessionId, int limit);

    AttendanceConfigDto getConfig(String key);

    AttendanceConfigDto updateConfig(
            String key,
            AttendanceConfigDto dto,
            UserPrincipal principal,
            HttpServletRequest httpRequest
    );

    /**
     * Điểm danh sinh viên bằng phương thức sinh trắc học Face-ID kết hợp đối soát QR & Wi-Fi
     */
    StudentAttendanceResponse checkInStudent(
            UserPrincipal principal,
            AttendanceCheckInRequest request,
            HttpServletRequest httpRequest
    );

    /**
     * Lấy toàn bộ danh sách sinh viên ghi danh trong lớp của phiên điểm danh kèm trạng thái điểm danh và recheck
     */
    List<SessionStudentAttendanceDto> getSessionStudents(UserPrincipal principal, Long sessionId);

    /**
     * Giảng viên điều chỉnh thủ công trạng thái điểm danh của sinh viên (PRESENT, LATE, ABSENT) kèm lý do
     */
    StudentAttendanceResponse adjustStudentAttendance(
            UserPrincipal principal,
            Long sessionId,
            Long studentId,
            AttendanceManualAdjustRequest request,
            HttpServletRequest httpRequest
    );

    /**
     * Giảng viên gửi yêu cầu một sinh viên thực hiện điểm danh lại (RECHECK)
     */
    AttendanceRecheckResponse createRecheckRequest(
            UserPrincipal principal,
            Long sessionId,
            Long studentId,
            AttendanceRecheckCreateRequest request,
            HttpServletRequest httpRequest
    );

    /**
     * Lấy toàn bộ lịch sử điều chỉnh điểm danh và tái xác thực của phiên
     */
    List<AttendanceHistoryRecordDto> getSessionAdjustmentHistory(UserPrincipal principal, Long sessionId);

    /**
     * Sinh viên lấy danh sách các yêu cầu điểm danh lại đang chờ thực hiện (PENDING)
     */
    List<AttendanceRecheckResponse> getPendingRecheckRequestsForStudent(UserPrincipal principal);

    /**
     * Lấy chi tiết một yêu cầu điểm danh lại
     */
    AttendanceRecheckResponse getRecheckRequestDetails(UserPrincipal principal, Long requestId);
}
