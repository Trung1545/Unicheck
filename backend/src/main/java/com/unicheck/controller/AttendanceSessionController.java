package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.*;
import com.unicheck.model.enums.AttendanceSessionStatus;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.AttendanceSessionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping({"/api/attendance", "/api/v1/attendance"})
@RequiredArgsConstructor
public class AttendanceSessionController {

    private final AttendanceSessionService attendanceSessionService;

    /**
     * 1. Lấy danh sách phiên điểm danh có phân trang, tìm kiếm và lọc
     */
    @GetMapping("/sessions")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<PageResponse<AttendanceSessionResponse>>> getSessions(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) Long semesterId,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) Long lecturerId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) AttendanceSessionStatus status,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable
    ) {
        Page<AttendanceSessionResponse> page = attendanceSessionService.getSessions(
                principal, semesterId, className, lecturerId, date, status, search, pageable);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách phiên điểm danh thành công"));
    }

    /**
     * 2. Lấy thông tin chi tiết một phiên điểm danh theo ID
     */
    @GetMapping("/sessions/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<AttendanceSessionResponse>> getSessionById(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long id
    ) {
        AttendanceSessionResponse response = attendanceSessionService.getSessionById(principal, id);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin phiên điểm danh thành công"));
    }

    /**
     * 3. Khởi tạo phiên điểm danh gắn với ca học (Timetable Slot)
     */
    @PostMapping("/sessions")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<AttendanceSessionResponse>> createSession(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody AttendanceSessionCreateRequest request,
            HttpServletRequest httpRequest
    ) {
        AttendanceSessionResponse response = attendanceSessionService.createSession(principal, request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Tạo phiên điểm danh thành công"));
    }

    /**
     * 4. Mở phiên điểm danh (OPEN)
     */
    @PostMapping("/sessions/{id}/open")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<AttendanceSessionResponse>> openSession(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long id,
            HttpServletRequest httpRequest
    ) {
        AttendanceSessionResponse response = attendanceSessionService.openSession(principal, id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Mở phiên điểm danh thành công"));
    }

    /**
     * 5. Đóng phiên điểm danh (CLOSED)
     */
    @PostMapping("/sessions/{id}/close")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<AttendanceSessionResponse>> closeSession(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long id,
            HttpServletRequest httpRequest
    ) {
        AttendanceSessionResponse response = attendanceSessionService.closeSession(principal, id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Chốt sổ phiên điểm danh thành công"));
    }

    /**
     * 6. Theo dõi trạng thái phiên (Polling & TASK-06 Contract)
     */
    @GetMapping("/sessions/{id}/status")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<AttendanceSessionStatusResponse>> getSessionStatus(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long id
    ) {
        AttendanceSessionStatusResponse response = attendanceSessionService.getSessionStatus(principal, id);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy trạng thái phiên điểm danh thành công"));
    }

    /**
     * 7. Lấy thống kê KPI phiên điểm danh theo Stitch UI
     */
    @GetMapping("/sessions/stats")
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<AttendanceSessionStatsResponse>> getStats(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) Long semesterId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        AttendanceSessionStatsResponse response = attendanceSessionService.getStats(principal, semesterId, date);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thống kê phiên điểm danh thành công"));
    }

    /**
     * 8. Lấy danh sách điểm danh gần nhất phục vụ Live Activity Drawer
     */
    @GetMapping({"/sessions/{id}/recent-checkins", "/sessions/{id}/attendances"})
    @PreAuthorize("hasAnyRole('ADMIN', 'LECTURER')")
    public ResponseEntity<ApiResponse<List<StudentAttendanceResponse>>> getRecentCheckIns(
            @AuthenticationPrincipal UserPrincipal principal,
            @PathVariable Long id,
            @RequestParam(defaultValue = "10") int limit
    ) {
        List<StudentAttendanceResponse> list = attendanceSessionService.getRecentCheckIns(principal, id, limit);
        return ResponseEntity.ok(ApiResponse.ok(list, "Lấy dữ liệu điểm danh gần đây thành công"));
    }

    /**
     * 9. Lấy cấu hình cơ chế điểm danh
     */
    @GetMapping("/configs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<AttendanceConfigDto>> getConfig(
            @RequestParam(required = false, defaultValue = "DEFAULT") String key
    ) {
        AttendanceConfigDto config = attendanceSessionService.getConfig(key);
        return ResponseEntity.ok(ApiResponse.ok(config, "Lấy cấu hình cơ chế điểm danh thành công"));
    }

    /**
     * 10. Cập nhật cấu hình cơ chế điểm danh (ADMIN ONLY)
     */
    @PutMapping("/configs")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<AttendanceConfigDto>> updateConfig(
            @RequestParam(required = false, defaultValue = "DEFAULT") String key,
            @Valid @RequestBody AttendanceConfigDto dto,
            @AuthenticationPrincipal UserPrincipal principal,
            HttpServletRequest httpRequest
    ) {
        AttendanceConfigDto updated = attendanceSessionService.updateConfig(key, dto, principal, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Cập nhật cấu hình cơ chế điểm danh thành công"));
    }
}
