package com.unicheck.model.dto;

import com.unicheck.model.enums.ClassSectionStatus;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassSectionSummaryDto {

    private String className;
    private Long courseId;
    private String courseCode;
    private String courseName;
    private Long semesterId;
    private String semesterCode;
    private String semesterName;
    private Long lecturerId;
    private String lecturerName;
    private Integer currentEnrollment;
    private Integer maxStudents;
    private ClassSectionStatus status;
}
