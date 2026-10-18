package com.unicheck.model.dto;

import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StudentAttendanceResponse {

    private Long id;
    private Long studentId;
    private String studentCode;
    private String studentName;
    private String status;
    private String method;
    private LocalDateTime checkInTime;
    private Double faceConfidence;
    private String note;
}
