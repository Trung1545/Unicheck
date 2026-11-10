package com.unicheck.model.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SessionStudentAttendanceDto {

    private Long studentId;
    private String studentCode;
    private String fullName;
    private String email;
    private Long attendanceId;
    private String status; // PRESENT, LATE, ABSENT, NOT_CHECKED_IN
    private LocalDateTime checkInTime;
    private String method; // FACE_QR, MANUAL, CARD, etc.
    private Double faceConfidence;
    private String note;
    private String recheckStatus; // PENDING, COMPLETED, EXPIRED, NONE
    private Long recheckRequestId;
    private String recheckReason;
    private LocalDateTime recheckExpiresAt;
}
