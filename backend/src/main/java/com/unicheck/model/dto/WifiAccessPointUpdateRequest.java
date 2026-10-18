package com.unicheck.model.dto;

import com.unicheck.model.enums.WifiApStatus;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.*;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WifiAccessPointUpdateRequest {

    @NotBlank(message = "Tên SSID không được để trống")
    @Size(max = 100, message = "SSID tối đa 100 ký tự")
    private String ssid;

    @NotBlank(message = "Địa chỉ MAC/BSSID không được để trống")
    @Pattern(regexp = "^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$", message = "Địa chỉ BSSID/MAC không đúng định dạng chuẩn XX:XX:XX:XX:XX:XX")
    private String bssid;

    @Size(max = 100, message = "Tên thiết bị AP tối đa 100 ký tự")
    private String name;

    @Size(max = 200, message = "Vị trí lắp đặt tối đa 200 ký tự")
    private String location;

    @NotNull(message = "Trạng thái thiết bị không được để trống")
    private WifiApStatus status;
}
