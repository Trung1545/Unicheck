package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.EnrollmentCreateRequest;
import com.unicheck.model.dto.EnrollmentResponse;
import com.unicheck.model.enums.EnrollmentStatus;
import com.unicheck.service.EnrollmentService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping({"/api/enrollments", "/api/v1/enrollments"})
@RequiredArgsConstructor
public class EnrollmentController {

    private final EnrollmentService enrollmentService;

    /**
     * 1. Lấy danh sách ghi danh có phân trang, lọc theo lớp, sinh viên, trạng thái, tìm kiếm
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<EnrollmentResponse>>> getEnrollments(
            @RequestParam(required = false) String className,
            @RequestParam(required = false) Long studentId,
            @RequestParam(required = false) EnrollmentStatus status,
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {

        Page<EnrollmentResponse> page = enrollmentService.getEnrollments(className, studentId, status, search, pageable);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách ghi danh thành công"));
    }

    /**
     * 2. Lấy chi tiết bản ghi ghi danh theo ID
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<EnrollmentResponse>> getEnrollmentById(@PathVariable Long id) {
        EnrollmentResponse response = enrollmentService.getEnrollmentById(id);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin ghi danh thành công"));
    }

    /**
     * 3. Ghi danh sinh viên vào lớp học phần (Yêu cầu quyền ADMIN)
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<EnrollmentResponse>> createEnrollment(
            @Valid @RequestBody EnrollmentCreateRequest request,
            HttpServletRequest httpRequest) {
        EnrollmentResponse response = enrollmentService.createEnrollment(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Ghi danh sinh viên vào lớp học phần thành công"));
    }

    /**
     * 4. Hủy ghi danh sinh viên khỏi lớp học phần (Yêu cầu quyền ADMIN)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteEnrollment(
            @PathVariable Long id,
            HttpServletRequest httpRequest) {
        enrollmentService.deleteEnrollment(id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Hủy ghi danh sinh viên thành công"));
    }
}
