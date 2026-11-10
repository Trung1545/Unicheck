package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.*;
import com.unicheck.model.enums.TimetableSlotStatus;
import com.unicheck.security.UserPrincipal;
import com.unicheck.service.TimetableService;
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
import java.util.Map;

@RestController
@RequestMapping({"/api/timetable", "/api/v1/timetable"})
@RequiredArgsConstructor
public class TimetableController {

    private final TimetableService timetableService;

    /**
     * 1. Lấy danh sách lịch học theo ngày/tuần, hỗ trợ cả dạng mảng danh sách lẫn phân trang
     */
    @GetMapping("/slots")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<?>> getTimetableSlots(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) Long semesterId,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) Long lecturerId,
            @RequestParam(required = false) Long roomId,
            @RequestParam(required = false) TimetableSlotStatus status,
            @RequestParam(required = false) Boolean paged,
            @PageableDefault(size = 20, sort = "date", direction = Sort.Direction.ASC) Pageable pageable
    ) {
        LocalDate start = (date != null) ? date : startDate;
        LocalDate end = (date != null) ? date : endDate;

        if (Boolean.TRUE.equals(paged)) {
            Page<TimetableSlotResponse> page = timetableService.getTimetableSlotsPaged(
                    start, end, semesterId, className, lecturerId, roomId, status, pageable);
            return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách thời khóa biểu thành công"));
        } else {
            List<TimetableSlotResponse> list = timetableService.getTimetableSlots(
                    start, end, semesterId, className, lecturerId, roomId, status);
            return ResponseEntity.ok(ApiResponse.ok(list, "Lấy danh sách thời khóa biểu thành công"));
        }
    }

    /**
     * 2. Lấy chi tiết một tiết học theo ID
     */
    @GetMapping("/slots/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TimetableSlotResponse>> getTimetableSlotById(@PathVariable Long id) {
        TimetableSlotResponse response = timetableService.getTimetableSlotById(id);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy chi tiết tiết học thành công"));
    }

    /**
     * 3. Tạo mới tiết học gắn với lớp học phần (ADMIN only)
     */
    @PostMapping("/slots")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<TimetableSlotResponse>> createTimetableSlot(
            @Valid @RequestBody TimetableSlotCreateRequest request
    ) {
        TimetableSlotResponse response = timetableService.createTimetableSlot(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Tạo tiết học trên thời khóa biểu thành công"));
    }

    /**
     * 4. Cập nhật tiết học (ADMIN only)
     */
    @PutMapping("/slots/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<TimetableSlotResponse>> updateTimetableSlot(
            @PathVariable Long id,
            @Valid @RequestBody TimetableSlotUpdateRequest request
    ) {
        TimetableSlotResponse response = timetableService.updateTimetableSlot(id, request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật tiết học thành công"));
    }

    /**
     * 5. Hủy hoặc xóa tiết học (ADMIN only)
     */
    @DeleteMapping("/slots/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> deleteTimetableSlot(@PathVariable Long id) {
        timetableService.deleteTimetableSlot(id);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("id", id, "deleted", true),
                "Xóa tiết học khỏi thời khóa biểu thành công"
        ));
    }

    /**
     * 6. Lấy thời khóa biểu cá nhân của người dùng hiện tại (/me)
     */
    @GetMapping("/me")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<TimetableSlotResponse>>> getMyTimetable(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate
    ) {
        List<TimetableSlotResponse> list = timetableService.getMyTimetable(principal, startDate, endDate);
        return ResponseEntity.ok(ApiResponse.ok(list, "Lấy thời khóa biểu cá nhân thành công"));
    }

    /**
     * 7. Kiểm tra xung đột thời gian thực (Pre-flight Conflict Validation)
     */
    @PostMapping("/conflicts/check")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TimetableConflictCheckResponse>> checkConflict(
            @Valid @RequestBody TimetableConflictCheckRequest request
    ) {
        TimetableConflictCheckResponse response = timetableService.checkConflict(request);
        return ResponseEntity.ok(ApiResponse.ok(response, "Kiểm tra xung đột lịch hoàn tất"));
    }

    /**
     * 7b. Lấy danh sách phòng học khả dụng theo khoảng thời gian thực (Real-time Available Rooms)
     */
    @GetMapping("/available-rooms")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<RoomResponse>>> getAvailableRooms(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam Integer slotNumber,
            @RequestParam(required = false) Integer endSlotNumber,
            @RequestParam(required = false) String className,
            @RequestParam(required = false) Boolean recurring,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate recurringUntil,
            @RequestParam(required = false) Long semesterId,
            @RequestParam(required = false) Long excludeSlotId
    ) {
        List<RoomResponse> rooms = timetableService.getAvailableRooms(
                date, slotNumber, endSlotNumber, className, recurring, recurringUntil, semesterId, excludeSlotId);
        return ResponseEntity.ok(ApiResponse.ok(rooms, "Lấy danh sách phòng học khả dụng thành công"));
    }

    /**
     * 8. Lấy danh mục ca học / loại tiết (Slot Types)
     */
    @GetMapping("/slot-types")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<SlotTypeResponse>>> getSlotTypes(
            @RequestParam(required = false) Long semesterId
    ) {
        List<SlotTypeResponse> list = timetableService.getSlotTypes(semesterId);
        return ResponseEntity.ok(ApiResponse.ok(list, "Lấy danh mục ca học thành công"));
    }

    /**
     * 9. Lấy thống kê KPI thời khóa biểu theo Stitch UI
     */
    @GetMapping("/stats")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<TimetableStatsResponse>> getTimetableStats(
            @RequestParam(required = false) Long semesterId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStartDate
    ) {
        TimetableStatsResponse stats = timetableService.getTimetableStats(semesterId, weekStartDate);
        return ResponseEntity.ok(ApiResponse.ok(stats, "Lấy thống kê thời khóa biểu thành công"));
    }

    /**
     * 10. Công bố thời khóa biểu (ADMIN only)
     */
    @PostMapping("/publish")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Object>>> publishTimetable(
            @RequestParam Long semesterId
    ) {
        timetableService.publishTimetable(semesterId);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("semesterId", semesterId, "published", true),
                "Thời khóa biểu đã được công bố chính thức đến sinh viên và giảng viên"
        ));
    }
}
