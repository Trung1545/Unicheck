package com.unicheck.model.dto;

import lombok.*;

import java.time.LocalTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SlotTypeResponse {

    private Long id;

    private String name;

    private Integer slotIndex;

    private LocalTime startTime;

    private LocalTime endTime;

    private String description;

    private Long semesterId;

    private String duration;
}
