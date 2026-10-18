package com.unicheck.model.dto;

import com.unicheck.model.enums.RoomStatus;
import com.unicheck.model.enums.RoomType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomCreateRequest {

    @NotBlank(message = "Mã phòng học không được để trống")
    @Size(max = 20, message = "Mã phòng học tối đa 20 ký tự")
    private String code;

    @NotBlank(message = "Tên phòng học không được để trống")
    @Size(max = 100, message = "Tên phòng học tối đa 100 ký tự")
    private String name;

    @NotNull(message = "Sức chứa phòng học không được để trống")
    @Min(value = 1, message = "Sức chứa phòng học tối thiểu là 1 người")
    private Integer capacity;

    @Size(max = 50, message = "Tên tòa nhà tối đa 50 ký tự")
    private String building;

    @Size(max = 500, message = "Mô tả tối đa 500 ký tự")
    private String description;

    private Integer floor;

    private Integer gridRow;

    private Integer gridCol;

    private Integer gridRowSpan;

    private Integer gridColSpan;

    @NotNull(message = "Loại phòng học không được để trống")
    @Builder.Default
    private RoomType type = RoomType.THEORY;

    @Builder.Default
    private RoomStatus status = RoomStatus.AVAILABLE;
}
