package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.CourseCreateRequest;
import com.unicheck.model.dto.CourseResponse;
import com.unicheck.model.dto.CourseSummaryDto;
import com.unicheck.model.dto.CourseUpdateRequest;
import com.unicheck.model.enums.CourseStatus;
import com.unicheck.service.CourseService;
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

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping({"/api/courses", "/api/v1/courses"})
@RequiredArgsConstructor
public class CourseController {

    private final CourseService courseService;

    /**
     * 1. Lấy danh sách học phần có phân trang, tìm kiếm, lọc theo tín chỉ và trạng thái
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<CourseResponse>>> getCourses(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer credits,
            @RequestParam(required = false) CourseStatus status,
            @PageableDefault(size = 20, sort = "code", direction = Sort.Direction.ASC) Pageable pageable) {
        Page<CourseResponse> page = courseService.getCourses(search, credits, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách học phần thành công"));
    }

    /**
     * 2. Lấy danh sách tóm tắt tất cả học phần phục vụ chọn môn tiên quyết
     */
    @GetMapping("/summaries")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<CourseSummaryDto>>> getCourseSummaries() {
        List<CourseSummaryDto> summaries = courseService.getAllCourseSummaries();
        return ResponseEntity.ok(ApiResponse.ok(summaries, "Lấy danh sách tóm tắt học phần thành công"));
    }

    /**
     * 3. Lấy thông tin chi tiết học phần theo ID
     */
    @GetMapping("/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<CourseResponse>> getCourseById(@PathVariable Long id) {
        CourseResponse response = courseService.getCourseById(id);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin học phần thành công"));
    }

    /**
     * 4. Kiểm tra tính khả dụng của mã học phần
     */
    @GetMapping("/check-code")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkCourseCode(
            @RequestParam String code) {
        boolean exists = courseService.existsByCode(code);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("available", !exists),
                exists ? "Mã học phần đã tồn tại" : "Mã học phần khả dụng"));
    }

    /**
     * 5. Tạo mới học phần (Yêu cầu quyền ADMIN)
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CourseResponse>> createCourse(
            @Valid @RequestBody CourseCreateRequest request,
            HttpServletRequest httpRequest) {
        CourseResponse response = courseService.createCourse(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Tạo mới học phần thành công"));
    }

    /**
     * 6. Cập nhật học phần theo ID (Yêu cầu quyền ADMIN)
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CourseResponse>> updateCourse(
            @PathVariable Long id,
            @Valid @RequestBody CourseUpdateRequest request,
            HttpServletRequest httpRequest) {
        CourseResponse response = courseService.updateCourse(id, request, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật học phần thành công"));
    }

    /**
     * 7. Xóa học phần theo ID (Yêu cầu quyền ADMIN, có kiểm tra toàn vẹn tiên quyết)
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteCourse(
            @PathVariable Long id,
            HttpServletRequest httpRequest) {
        courseService.deleteCourse(id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Xóa học phần thành công"));
    }
}
