package com.unicheck.model.dto;

import com.unicheck.model.entity.Room;
import com.unicheck.model.enums.RoomStatus;
import com.unicheck.model.enums.RoomType;
import lombok.*;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class RoomResponse {

    private Long id;
    private String code;
    private String name;
    private Integer capacity;
    private String building;
    private String description;
    private Integer floor;
    private Integer gridRow;
    private Integer gridCol;
    private Integer gridRowSpan;
    private Integer gridColSpan;
    private RoomType type;
    private RoomStatus status;
    private List<RoomWifiAccessPointResponse> wifiAccessPoints;
    private Integer assignedWifiCount;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;

    public static RoomResponse fromEntity(Room room) {
        if (room == null) return null;
        List<RoomWifiAccessPointResponse> aps = room.getRoomWifiAccessPoints() != null
                ? room.getRoomWifiAccessPoints().stream()
                .map(RoomWifiAccessPointResponse::fromEntity)
                .collect(Collectors.toList())
                : Collections.emptyList();

        return RoomResponse.builder()
                .id(room.getId())
                .code(room.getCode())
                .name(room.getName())
                .capacity(room.getCapacity())
                .building(room.getBuilding())
                .description(room.getDescription())
                .floor(room.getFloor())
                .gridRow(room.getGridRow())
                .gridCol(room.getGridCol())
                .gridRowSpan(room.getGridRowSpan())
                .gridColSpan(room.getGridColSpan())
                .type(room.getType())
                .status(room.getStatus())
                .wifiAccessPoints(aps)
                .assignedWifiCount(aps.size())
                .createdAt(room.getCreatedAt())
                .updatedAt(room.getUpdatedAt())
                .build();
    }
}
