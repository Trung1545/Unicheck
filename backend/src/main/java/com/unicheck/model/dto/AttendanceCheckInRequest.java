package com.unicheck.model.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO yêu cầu điểm danh sinh viên gửi từ Flutter Mobile.
 * Hỗ trợ xác thực sinh trắc học khuôn mặt và đối soát đa lớp (QR, Wi-Fi, Liveness).
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceCheckInRequest {

    /**
     * ID phiên điểm danh (tùy chọn nếu slotId được cung cấp)
     */
    private Long sessionId;

    /**
     * ID lịch học / ca học trên thời khóa biểu (tùy chọn nếu sessionId được cung cấp)
     */
    private Long slotId;

    /**
     * Chuỗi token mã QR quét được tại phòng học
     */
    private String qrToken;

    /**
     * Địa chỉ MAC / BSSID của Access Point Wi-Fi thiết bị đang kết nối
     */
    private String wifiBssid;

    /**
     * Tên mạng SSID của Wi-Fi
     */
    private String wifiSsid;

    /**
     * Dữ liệu ảnh khuôn mặt Base64 (Data URI hoặc raw base64 JPEG)
     */
    @NotBlank(message = "Dữ liệu ảnh khuôn mặt không được để trống")
    private String faceSampleBase64;

    /**
     * Trạng thái kiểm tra thực thể do client tự khai báo (không tin cậy)
     */
    @Builder.Default
    private Boolean livenessPassed = false;

    /**
     * Danh sách các bước liveness đã thực hiện trên client
     */
    private List<String> livenessSteps;

    /**
     * Tên thiết bị di động của sinh viên
     */
    private String deviceModel;
}
