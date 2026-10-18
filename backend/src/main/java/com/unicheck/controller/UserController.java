package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.CsvImportResultResponse;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserResponse;
import com.unicheck.model.dto.UserStatusUpdateRequest;
import com.unicheck.model.dto.UserUpdateRequest;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import com.unicheck.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping({"/api/users", "/api/v1/users"})
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    /**
     * Chức năng 1: Tạo tài khoản người dùng mới (Yêu cầu quyền ADMIN).
     */
    @PostMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> createUser(@Valid @RequestBody UserCreateRequest request,
                                                               HttpServletRequest httpRequest) {
        UserResponse response = userService.createUser(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(response, "Tạo tài khoản người dùng thành công"));
    }

    /**
     * Chức năng 2a: Xem chi tiết tài khoản theo ID (Yêu cầu quyền ADMIN).
     */
    @GetMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> getUser(@PathVariable Long id) {
        UserResponse response = userService.getUser(id);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy thông tin người dùng thành công"));
    }

    /**
     * Chức năng 3: Cập nhật thông tin tài khoản người dùng theo ID (Yêu cầu quyền ADMIN, ghi audit log).
     */
    @PutMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> updateUser(@PathVariable Long id,
                                                                 @Valid @RequestBody UserUpdateRequest request,
                                                                 HttpServletRequest httpRequest) {
        UserResponse response = userService.updateUser(id, request, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật thông tin người dùng thành công"));
    }

    /**
     * Chức năng 4: Xóa tài khoản người dùng theo ID (Yêu cầu quyền ADMIN, ghi audit log).
     */
    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteUser(@PathVariable Long id, HttpServletRequest httpRequest) {
        userService.deleteUser(id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Xóa tài khoản người dùng thành công"));
    }

    /**
     * Chức năng 2b: Xem danh sách người dùng có phân trang, tìm kiếm, lọc vai trò & trạng thái.
     */
    @GetMapping
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> getAllUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Role role,
            @RequestParam(required = false) UserStatus status,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        PageResponse<UserResponse> response = userService.getAllUsers(search, role, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy danh sách người dùng thành công"));
    }

    /**
     * Chức năng 2c: Xem danh sách tài khoản đã kích hoạt (ACTIVE).
     */
    @GetMapping("/active")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> getActiveUsers(
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        PageResponse<UserResponse> response = userService.getActiveUsers(search, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy danh sách người dùng đã kích hoạt thành công"));
    }

    /**
     * Chức năng 2d: Xem danh sách tài khoản chưa kích hoạt (INACTIVE).
     */
    @GetMapping("/inactive")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<PageResponse<UserResponse>>> getInactiveUsers(
            @RequestParam(required = false) String search,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        PageResponse<UserResponse> response = userService.getInactiveUsers(search, pageable);
        return ResponseEntity.ok(ApiResponse.ok(response, "Lấy danh sách người dùng chưa kích hoạt thành công"));
    }

    /**
     * Chức năng 5: Cập nhật trạng thái người dùng (Khóa/Mở khóa tài khoản).
     */
    @PatchMapping("/{id}/status")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<UserResponse>> updateUserStatus(
            @PathVariable Long id,
            @Valid @RequestBody UserStatusUpdateRequest request,
            HttpServletRequest httpRequest) {
        UserResponse response = userService.updateUserStatus(id, request.getStatus(), httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Cập nhật trạng thái người dùng thành công"));
    }

    /**
     * Chức năng 6: Kiểm tra tính khả dụng của tên đăng nhập.
     */
    @GetMapping("/check-username")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Boolean>> checkUsername(@RequestParam String username) {
        boolean exists = userService.existsByUsername(username);
        return ResponseEntity.ok(ApiResponse.ok(exists, exists ? "Tên đăng nhập đã tồn tại" : "Tên đăng nhập khả dụng"));
    }

    /**
     * Chức năng 7: Nhập danh sách tài khoản từ tệp CSV/Excel.
     */
    @PostMapping(value = "/import-csv", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<CsvImportResultResponse>> importUsersCsv(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest httpRequest) {
        CsvImportResultResponse response = userService.importUsersCsv(file, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(response, "Xử lý tệp import hoàn tất"));
    }
}
