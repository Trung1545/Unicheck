package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.*;
import com.unicheck.model.enums.ClassSectionStatus;
import com.unicheck.service.ClassSectionService;
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

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping({"/api/classes", "/api/v1/classes"})
@RequiredArgsConstructor
public class ClassSectionController {

    private final ClassSectionService classSectionService;
    private final EnrollmentService enrollmentService;

    /**
     * 1. Lấy danh sách lớp học phần có phân trang, tìm kiếm và lọc
     */
    @GetMapping
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<ClassSectionResponse>>> getClassSections(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Long semesterId,
            @RequestParam(required = false) Long courseId,
            @RequestParam(required = false) Long lecturerId,
            @RequestParam(required = false) ClassSectionStatus status,
            @PageableDefault(size = 20, sort = "className", direction = Sort.Direction.ASC) Pageable pageable) {

        Page<ClassSectionResponse> page = classSectionService.getClassSections(
                search, semesterId, courseId, lecturerId, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách lớp học phần thành công"));
    }

    /**
     * 2. Lấy danh sách tóm tắt lớp học phần phục vụ dropdown selection
     */
    @GetMapping("/summaries")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<ClassSectionSummaryDto>>> getClassSummaries(
            @RequestParam(required = false) Long semesterId) {
        List<ClassSectionSummaryDto> summaries = classSectionService.getClassSummaries(semesterId);
        return ResponseEntity.ok(ApiResponse.ok(summaries, "Lấy danh sách tóm tắt lớp học phần thành công"));
    }

    /**
     * 3. Lấy thống kê bento metrics cho lớp học phần
     */
    @GetMapping("/stats")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ClassSectionStatsResponse>> getStats(
            @RequestParam(required = false) Long semesterId) {
        ClassSectionStatsResponse stats = classSectionService.getStats(semesterId);
        return ResponseEntity.ok(ApiResponse.ok(stats, "Lấy thống kê lớp học phần thành công"));
    }

    /**
     * 4. Kiểm tra tính khả dụng của mã lớp học phần
     */
    @GetMapping("/check-name")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkClassName(
            @RequestParam String className) {
        boolean exists = classSectionService.existsByClassName(className);
        return ResponseEntity.ok(ApiResponse.ok(Map.of("available", !exists),
                exists ? "Mã lớp học phần đã tồn tại" : "Mã lớp học phần khả dụng"));
    }

    /**
     * 5. Lấy thông tin chi tiết một lớp học phần theo className
     */
    @GetMapping("/{className}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<ClassSectionResponse>> getClassSectionByClassName(
            @PathVariable String className) {
        ClassSectionResponse response = classSectionService.getClassSectionByClassName(className);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin lớp học phần thành công"));
    }

    /**
     * 6. Tạo mới lớp học phần (Yêu cầu quyền ADMIN)
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ClassSectionResponse>> createClassSection(
            @Valid @RequestBody ClassSectionCreateRequest request,
            HttpServletRequest httpRequest) {
        ClassSectionResponse response = classSectionService.createClassSection(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Tạo mới lớp học phần thành công"));
    }

    /**
     * 7. Cập nhật thông tin lớp học phần (Yêu cầu quyền ADMIN)
     */
    @PutMapping("/{className}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<ClassSectionResponse>> updateClassSection(
            @PathVariable String className,
            @Valid @RequestBody ClassSectionUpdateRequest request,
            HttpServletRequest httpRequest) {
        ClassSectionResponse response = classSectionService.updateClassSection(className, request, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật lớp học phần thành công"));
    }

    /**
     * 8. Xóa lớp học phần (Yêu cầu quyền ADMIN)
     */
    @DeleteMapping("/{className}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteClassSection(
            @PathVariable String className,
            HttpServletRequest httpRequest) {
        classSectionService.deleteClassSection(className, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Xóa lớp học phần thành công"));
    }

    /**
     * 9. Lấy danh sách sinh viên ghi danh trong lớp học phần
     */
    @GetMapping("/{className}/students")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<EnrollmentResponse>>> getStudentsByClass(
            @PathVariable String className) {
        List<EnrollmentResponse> students = enrollmentService.getStudentsByClass(className);
        return ResponseEntity.ok(ApiResponse.ok(students, "Lấy danh sách sinh viên trong lớp thành công"));
    }

    /**
     * 10. Ghi danh sinh viên vào lớp học phần qua route lồng nhau
     */
    @PostMapping("/{className}/students")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<EnrollmentResponse>> addStudentToClass(
            @PathVariable String className,
            @RequestBody Map<String, Long> payload,
            HttpServletRequest httpRequest) {
        Long studentId = payload.get("studentId");
        EnrollmentCreateRequest request = EnrollmentCreateRequest.builder()
                .className(className)
                .studentId(studentId)
                .build();
        EnrollmentResponse response = enrollmentService.createEnrollment(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Ghi danh sinh viên vào lớp thành công"));
    }
}
