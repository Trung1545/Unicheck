package com.unicheck.model.dto;

import lombok.*;

import java.time.LocalDateTime;

/**
 * DTO phản hồi sau khi xác thực mã OTP thành công.
 * Trả về thông tin lớp học, phòng học, phiên điểm danh và token bảo mật
 * để Flutter Mobile tiếp tục chuyển tiếp qua bước kiểm tra 5 tiêu chí và FaceID.
 */
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OtpValidationResponse {

    private Boolean valid;
    private Long sessionId;
    private Long slotId;
    private String className;
    private String courseCode;
    private String courseName;
    private String roomName;
    private Long roomId;
    private String roomCode;
    private String qrToken;
    private Boolean wifiSimulationAllowed;
    private String simulatedSsid;
    private String simulatedBssid;
    private String verificationTicket;
    private LocalDateTime ticketExpiresAt;
    private LocalDateTime issuedAt;
    private LocalDateTime expiresAt;
    private String message;
    private String verificationMethod;
}
