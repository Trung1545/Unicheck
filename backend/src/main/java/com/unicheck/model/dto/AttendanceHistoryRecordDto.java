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
public class AttendanceHistoryRecordDto {

    private Long id;
    private Long sessionId;
    private Long studentId;
    private String studentCode;
    private String studentName;
    private String oldStatus;
    private String newStatus;
    private String reason;
    private String modifiedByName;
    private LocalDateTime modifiedAt;
    private String modificationType;
}
