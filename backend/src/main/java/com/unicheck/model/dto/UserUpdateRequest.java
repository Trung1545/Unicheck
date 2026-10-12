package com.unicheck.model.dto;

import com.unicheck.model.enums.Role;
import jakarta.validation.constraints.Email;
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
public class UserUpdateRequest {

    @Size(max = 150, message = "Họ và tên tối đa 150 ký tự")
    private String fullName;

    @Email(message = "Email không đúng định dạng")
    private String email;

    @Size(max = 50, message = "Mã định danh tối đa 50 ký tự")
    private String code;

    private String phone;
    private LocalDate dob;
    private String sex;
    private String avatar;
    private Role role;

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
