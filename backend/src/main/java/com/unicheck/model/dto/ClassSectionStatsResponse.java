package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ClassSectionStatsResponse {
    private long totalClasses;
    private long activeClasses;
    private long fullCapacityClasses;
    private long underCapacityClasses;
}
