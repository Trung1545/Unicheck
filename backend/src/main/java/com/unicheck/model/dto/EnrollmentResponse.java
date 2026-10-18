package com.unicheck.model.dto;

import com.unicheck.model.enums.EnrollmentStatus;
import com.unicheck.model.enums.FaceDataStatus;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class EnrollmentResponse {

    private Long id;
    private String className;
    private Long courseId;
    private String courseCode;
    private String courseName;
    private Long semesterId;
    private String semesterCode;

    private Long studentId;
    private String studentCode;
    private String studentName;
    private String studentEmail;
    private String studentClass;
    private String avatar;
    private FaceDataStatus faceDataStatus;

    private EnrollmentStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
