package com.unicheck.model.dto;

import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableConflictCheckResponse {

    private boolean hasConflict;

    private String conflictType;

    private String conflictMessage;

    private Long conflictingSlotId;

    private String conflictingClassName;

    private String conflictingRoomCode;

    private String conflictingLecturerName;
}
