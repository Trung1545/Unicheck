package com.unicheck.model.dto;

import com.unicheck.model.enums.AttendanceSessionStatus;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSessionStatusResponse {

    private Long id;
    private AttendanceSessionStatus status;
    private Boolean isOpen;
    private Boolean isClosed;
    private LocalDateTime openedAt;
    private LocalDateTime closedAt;
    private Integer totalEnrolledStudents;
    private Integer totalAttendedStudents;
    private Double attendancePercentage;
    private Boolean canGenerateQr;
}
