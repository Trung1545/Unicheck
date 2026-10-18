package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CourseSummaryDto {
    private Long id;
    private String code;
    private String name;
    private Integer credits;
}
