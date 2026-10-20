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
}
