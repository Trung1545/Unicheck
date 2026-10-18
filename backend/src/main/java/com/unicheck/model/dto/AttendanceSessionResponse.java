package com.unicheck.model.dto;

import com.unicheck.model.enums.AttendanceSessionStatus;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AttendanceSessionResponse {

    private Long id;
    private Long timetableSlotId;
    private String className;
    private String courseCode;
    private String courseName;
    private Long semesterId;
    private String semesterName;
    private Long lecturerId;
    private String lecturerName;
    private String lecturerCode;
    private Long roomId;
    private String roomCode;
    private String roomNumber;
    private String building;
    private LocalDate date;
    private Integer slotNumber;
    private String slotTypeName;
    private LocalTime startTime;
    private LocalTime endTime;
    private AttendanceSessionStatus status;
    private LocalDateTime openedAt;
    private LocalDateTime closedAt;
    private LocalDateTime createdAt;
    private Integer totalEnrolledStudents;
    private Integer totalAttendedStudents;
    private Double attendancePercentage;
    private String note;
    private Boolean canOpen;
    private Boolean canClose;
}
