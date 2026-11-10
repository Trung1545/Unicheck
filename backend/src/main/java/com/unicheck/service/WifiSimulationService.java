package com.unicheck.service;

import com.unicheck.model.entity.AttendanceSession;

/**
 * Dịch vụ quản lý và xác thực chế độ Wi-Fi mô phỏng (DEMO_WIFI_SIMULATION)
 * Chỉ cho phép hoạt động trên môi trường dev/test cô lập cho các lớp học demo/test được phê duyệt.
 * Tuyệt đối cấm kích hoạt trên môi trường Production.
 */
public interface WifiSimulationService {

    /**
     * Kiểm tra xem môi trường hiện tại có được phép chạy DEMO_WIFI_SIMULATION hay không.
     * Trả về false nếu active profile là prod hoặc production.
     */
    boolean isWifiSimulationEnabledInEnvironment();

    /**
     * Xác nhận phiên điểm danh cụ thể có đủ điều kiện sử dụng Wi-Fi mô phỏng hay không.
     * Backend kiểm tra lớp học phần nằm trong whitelist allowed-class-name, không tin client.
     */
    boolean isWifiSimulationAllowedForSession(AttendanceSession session);

    /**
     * Kiểm tra xem thông tin Wi-Fi BSSID/SSID sinh viên gửi lên có khớp với AP mô phỏng đã đăng ký không.
     */
    boolean isSimulatedWifiMatch(String studentBssid, String studentSsid);

    /**
     * Kiểm tra đối soát Wi-Fi mô phỏng gắn với phòng học của phiên điểm danh.
     */
    boolean isSimulatedWifiMatchForSession(AttendanceSession session, String studentBssid, String studentSsid);

    String getSimulatedSsid();

    String getSimulatedBssid();

    String getSimulatedSsidForSession(AttendanceSession session);

    String getSimulatedBssidForSession(AttendanceSession session);

    String getAllowedClassName();
}

