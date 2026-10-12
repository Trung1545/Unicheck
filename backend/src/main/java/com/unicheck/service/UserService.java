package com.unicheck.service;

import com.unicheck.model.dto.UserCreateRequest;
import com.unicheck.model.dto.UserResponse;
import jakarta.servlet.http.HttpServletRequest;

public interface UserService {

    /**
     * Chức năng 1: Tạo tài khoản người dùng mới (ghi audit log).
     */
    UserResponse createUser(UserCreateRequest request, HttpServletRequest httpRequest);
}
