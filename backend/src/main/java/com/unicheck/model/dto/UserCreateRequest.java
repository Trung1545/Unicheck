package com.unicheck.model.dto;

import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserCreateRequest {

    @NotBlank(message = "Tên đăng nhập không được để trống")
    @Size(min = 3, max = 50, message = "Tên đăng nhập phải từ 3 đến 50 ký tự")
    private String username;

    @NotBlank(message = "Họ và tên không được để trống")
    @Size(max = 150, message = "Họ và tên tối đa 150 ký tự")
    private String fullName;

    @NotBlank(message = "Email không được để trống")
    @Email(message = "Email không đúng định dạng")
    private String email;

    @Size(max = 50, message = "Mã định danh tối đa 50 ký tự")
    private String code;

    @NotNull(message = "Vai trò người dùng không được để trống")
    @Builder.Default
    private Role role = Role.STUDENT;

    @Builder.Default
    private UserStatus status = UserStatus.INACTIVE;

    private String phone;
    private LocalDate dob;
    private String sex;
    private String avatar;

    // Tùy chọn mật khẩu ban đầu (nếu không cung cấp thì mật khẩu mặc định hoặc chờ kích hoạt)
    private String password;

    // Student profile info
    private String studentCourse;
    private Long majorId;
    private Long specializationId;
    private Long subSpecializationId;

    // Lecturer profile info
    private String department;
    private String expertise;
    private String bio;
}
