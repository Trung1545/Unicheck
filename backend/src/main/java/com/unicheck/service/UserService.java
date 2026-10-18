package com.unicheck.service;

import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserResponse;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Pageable;

public interface UserService {

    /**
     * Chức năng 1: Tạo tài khoản người dùng mới (ghi audit log).
     */
    UserResponse createUser(UserCreateRequest request, HttpServletRequest httpRequest);

    /**
     * Chức năng 2a: Xem chi tiết tài khoản người dùng theo ID.
     */
    UserResponse getUser(Long id);

    /**
     * Chức năng 2b: Xem danh sách người dùng có phân trang, tìm kiếm và lọc theo vai trò, trạng thái.
     */
    PageResponse<UserResponse> getAllUsers(String search, Role role, UserStatus status, Pageable pageable);

    /**
     * Chức năng 2c: Xem danh sách tài khoản đã kích hoạt (ACTIVE).
     */
    PageResponse<UserResponse> getActiveUsers(String search, Pageable pageable);

    /**
     * Chức năng 2d: Xem danh sách tài khoản chưa kích hoạt (INACTIVE).
     */
    PageResponse<UserResponse> getInactiveUsers(String search, Pageable pageable);

    /**
     * Chức năng 3: Cập nhật thông tin tài khoản người dùng (ghi audit log).
     */
    UserResponse updateUser(Long id, com.unicheck.model.dto.UserUpdateRequest request, HttpServletRequest httpRequest);

    /**
     * Chức năng 4: Xóa tài khoản người dùng theo ID (ghi audit log).
     */
    void deleteUser(Long id, HttpServletRequest httpRequest);

    /**
     * Chức năng 5: Cập nhật trạng thái tài khoản (ACTIVE / BLOCKED / INACTIVE).
     */
    UserResponse updateUserStatus(Long id, UserStatus status, HttpServletRequest httpRequest);

    /**
     * Chức năng 6: Kiểm tra tên đăng nhập đã tồn tại hay chưa.
     */
    boolean existsByUsername(String username);

    /**
     * Chức năng 7: Nhập danh sách tài khoản từ file CSV/Excel.
     */
    com.unicheck.model.dto.CsvImportResultResponse importUsersCsv(org.springframework.web.multipart.MultipartFile file, HttpServletRequest httpRequest);
}
