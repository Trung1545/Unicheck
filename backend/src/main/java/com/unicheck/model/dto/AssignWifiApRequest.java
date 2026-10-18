package com.unicheck.model.dto;

import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class AssignWifiApRequest {

    /**
     * ID của Wi-Fi Access Point đã có sẵn trong danh mục.
     * Nếu không truyền wifiAccessPointId, hệ thống sẽ sử dụng ssid và bssid để tìm hoặc tạo mới.
     */
    private Long wifiAccessPointId;

    private String ssid;

    private String bssid;

    private String apName;

    private String location;

    private Integer signalStrength;

    @Builder.Default
    private Boolean isPrimary = false;

    @Size(max = 200, message = "Ghi chú vị trí tối đa 200 ký tự")
    private String positionNote;
}
