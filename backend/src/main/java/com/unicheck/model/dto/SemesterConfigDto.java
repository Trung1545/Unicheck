package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SemesterConfigDto {
    private Integer maxSlotPerDay;
    private Integer slotPerSubjectPerWeek;
    private Integer slotDuration;
    private Boolean isPublished;
}
