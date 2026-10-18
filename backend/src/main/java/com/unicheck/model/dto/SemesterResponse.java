package com.unicheck.model.dto;

import com.unicheck.model.enums.SemesterStatus;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SemesterResponse {

    private Long id;
    private String code;
    private String name;
    private LocalDate startDate;
    private LocalDate endDate;
    private SemesterStatus status;
    private String description;
    private SemesterConfigDto config;
    private Long totalWeeks;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
