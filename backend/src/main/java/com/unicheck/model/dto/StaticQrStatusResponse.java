package com.unicheck.model.dto;

import com.unicheck.model.enums.AttendanceSessionStatus;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StaticQrStatusResponse {

    private boolean allowed;
    private String reason;
    private String className;
    private Long sessionId;
    private AttendanceSessionStatus sessionStatus;
}
