package com.unicheck.model.dto;

import com.unicheck.model.enums.TimetableSlotStatus;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableSlotResponse {

    private Long id;

    private String className;

    private String courseCode;

    private String courseName;

    private String courseCategory;

    private Long semesterId;

    private String semesterCode;

    private String semesterName;

    private Long lecturerId;

    private String lecturerCode;

    private String lecturerName;

    private Long roomId;

    private String roomCode;

    private String roomName;

    private String building;

    private Integer roomCapacity;

    private String attendanceMethod;

    private Long slotTypeId;

    private String slotTypeName;

    private LocalTime startTime;

    private LocalTime endTime;

    private String duration;

    private LocalDate date;

    private Integer dayOfWeek;

    private Integer slotNumber;

    private Integer endSlotNumber;

    private String periodDisplay;

    private Integer currentEnrollment;

    private Integer maxStudents;

    private TimetableSlotStatus status;

    private String note;

    private Boolean hasAttendanceSession;

    private Boolean hasConflict;

    private String conflictType;

    private String conflictMessage;

    private LocalDateTime createdAt;

    private LocalDateTime updatedAt;
}
