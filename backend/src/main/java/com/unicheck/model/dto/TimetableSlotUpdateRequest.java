package com.unicheck.model.dto;

import com.unicheck.model.enums.TimetableSlotStatus;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableSlotUpdateRequest {

    private Long roomId;

    private Long slotTypeId;

    private LocalDate date;

    @Min(value = 1, message = "Tiết học phải từ 1 đến 12")
    @Max(value = 12, message = "Tiết học phải từ 1 đến 12")
    private Integer slotNumber;

    @Min(value = 1, message = "Tiết kết thúc phải từ 1 đến 12")
    @Max(value = 12, message = "Tiết kết thúc phải từ 1 đến 12")
    private Integer endSlotNumber;

    private TimetableSlotStatus status;

    @Size(max = 500, message = "Ghi chú tối đa 500 ký tự")
    private String note;
}
