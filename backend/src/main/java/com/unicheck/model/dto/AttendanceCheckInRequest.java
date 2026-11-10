package com.unicheck.model.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * DTO yêu cầu điểm danh sinh viên gửi từ Flutter Mobile.
 * Hỗ trợ xác thực sinh trắc học khuôn mặt và đối soát đa lớp (QR, OTP, Wi-Fi, Liveness).
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
     * ID yêu cầu điểm danh lại (nếu đây là lượt tái xác thực)
     */
    private Long recheckRequestId;

    /**
     * ID lịch học / ca học trên thời khóa biểu (tùy chọn nếu sessionId được cung cấp)
     */
    private Long slotId;

    /**
     * Chuỗi token mã QR quét được tại phòng học
     */
    private String qrToken;

    /**
     * Mã OTP 6 chữ số điểm danh (nếu sinh viên chọn nhập OTP)
     */
    private String otpCode;

    /**
     * Phiếu xác thực điểm danh (Verification Ticket) được cấp khi quét QR/nhập OTP hợp lệ ban đầu
     */
    private String verificationTicket;

    /**
     * Phương thức xác thực: "FACE_QR" hoặc "FACE_OTP"
     */
    private String verificationMethod;

    /**
     * Địa chỉ MAC / BSSID của Access Point Wi-Fi thiết bị đang kết nối
     */
    private String wifiBssid;

    /**
     * Tên mạng SSID của Wi-Fi
     */
    private String wifiSsid;

    /**
     * Cường độ tín hiệu Wi-Fi RSSI (dBm)
     */
    private Integer wifiRssi;

    /**
     * Tọa độ GPS vĩ độ
     */
    private Double latitude;

    /**
     * Tọa độ GPS kinh độ
     */
    private Double longitude;

    /**
     * Dữ liệu ảnh khuôn mặt Base64 (Data URI hoặc raw base64 JPEG)
     */
    @JsonProperty("faceSampleBase64")
    private String faceSampleBase64;

    @JsonProperty("faceImageBase64")
    private String faceImageBase64;

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

    private String deviceInfo;

    public String getFaceSampleBase64() {
        if (faceSampleBase64 != null && !faceSampleBase64.isBlank()) {
            return faceSampleBase64;
        }
        return faceImageBase64;
    }

    public String getFaceImageBase64() {
        if (faceImageBase64 != null && !faceImageBase64.isBlank()) {
            return faceImageBase64;
        }
        return faceSampleBase64;
    }

    public String getEffectiveFaceImage() {
        return getFaceSampleBase64();
    }
}
