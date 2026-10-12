package com.unicheck.model.dto;

import com.unicheck.model.enums.FaceDataStatus;
import com.unicheck.model.enums.Role;
import com.unicheck.model.enums.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserProfileResponse {

    private Long id;
    private String code;
    private String username;
    private String fullName;
    private String email;
    private LocalDate dob;
    private String phone;
    private String sex;
    private Role role;
    private UserStatus status;
    private FaceDataStatus faceDataStatus;
    private String avatar;
    private Boolean isPasswordChanged;
    private LocalDateTime createdAt;

    // Student specific info
    private String studentCourse;
    private Double gpa;
    private Long majorId;
    private Long specializationId;
    private Long subSpecializationId;

    // Lecturer specific info
    private String department;
    private String expertise;
    private String bio;

    // Permissions list
    private List<String> permissions;
}
