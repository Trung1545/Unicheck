package com.unicheck.model.dto;

import com.unicheck.model.enums.CourseStatus;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseResponse {

    private Long id;
    private String code;
    private String name;
    private String description;
    private Integer credits;
    private Integer numberOfSlots;
    private CourseStatus status;
    private Boolean isCalculatedInGpa;
    private List<CourseSummaryDto> prerequisites;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
