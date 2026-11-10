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
public class AttendanceRecheckResponse {

    private Long requestId;
    private Long sessionId;
    private Long studentId;
    private String studentCode;
    private String studentName;
    private String courseCode;
    private String courseName;
    private String className;
    private String roomCode;
    private String reason;
    private String status;
    private LocalDateTime requestedAt;
    private LocalDateTime expiresAt;
    private LocalDateTime completedAt;
    private String requestedByName;
}
