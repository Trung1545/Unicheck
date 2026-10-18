package com.unicheck.model.dto;

import com.unicheck.model.enums.ClassSectionStatus;
import lombok.*;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassSectionResponse {

    private String className;

    private Long courseId;
    private String courseCode;
    private String courseName;
    private Integer credits;

    private Long semesterId;
    private String semesterCode;
    private String semesterName;

    private Long lecturerId;
    private String lecturerCode;
    private String lecturerName;
    private String lecturerEmail;

    private Integer numberOfSlots;
    private Integer maxStudents;
    private Integer currentEnrollment;
    private ClassSectionStatus status;

    private Boolean gradesSubmitted;
    private LocalDateTime gradesSubmittedAt;

    private Boolean gradesPublished;
    private LocalDateTime gradesPublishedAt;

    private Boolean resitGradesPublished;
    private LocalDateTime resitGradesPublishedAt;

    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
