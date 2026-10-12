package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserResponse;
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
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

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
}
