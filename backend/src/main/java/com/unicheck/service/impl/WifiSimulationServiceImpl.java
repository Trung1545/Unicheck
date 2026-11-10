package com.unicheck.service.impl;

import com.unicheck.model.entity.AttendanceSession;
import com.unicheck.model.entity.RoomWifiAccessPoint;
import com.unicheck.model.enums.WifiApStatus;
import com.unicheck.repository.RoomWifiAccessPointRepository;
import com.unicheck.service.WifiSimulationService;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Service;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * Triển khai kiểm tra và xác thực chế độ Wi-Fi mô phỏng cho môi trường DEMO/TEST.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class WifiSimulationServiceImpl implements WifiSimulationService {

    private final Environment environment;
    private final RoomWifiAccessPointRepository roomWifiAccessPointRepository;

    @Value("${unicheck.testing.wifi-simulation.enabled:false}")
    private boolean simulationEnabled;

    @Getter
    @Value("${unicheck.testing.wifi-simulation.allowed-class-name:SE1801-PRJ301,UNICHECK-E2E-01}")
    private String allowedClassName;

    @Getter
    @Value("${unicheck.testing.wifi-simulation.simulated-ssid:AndroidWifi}")
    private String simulatedSsid;

    @Getter
    @Value("${unicheck.testing.wifi-simulation.simulated-bssid:02:00:00:00:00:00}")
    private String simulatedBssid;

    @Override
    public boolean isWifiSimulationEnabledInEnvironment() {
        if (!simulationEnabled) {
            return false;
        }

        String[] activeProfiles = environment.getActiveProfiles();
        if (activeProfiles == null || activeProfiles.length == 0) {
            activeProfiles = environment.getDefaultProfiles();
        }

        // STRICT SECURITY RULE: Production environment is STRICTLY prohibited
        for (String profile : activeProfiles) {
            if ("prod".equalsIgnoreCase(profile) || "production".equalsIgnoreCase(profile)) {
                log.error("SECURITY ALERT: DEMO_WIFI_SIMULATION attempted on production profile: {}", profile);
                return false;
            }
        }

        // Profile must be in dedicated test/dev whitelist or default non-production
        return Arrays.stream(activeProfiles)
                .anyMatch(p -> p.equalsIgnoreCase("test") ||
                               p.equalsIgnoreCase("dev") ||
                               p.equalsIgnoreCase("development") ||
                               p.equalsIgnoreCase("demo") ||
                               p.equalsIgnoreCase("local") ||
                               p.equalsIgnoreCase("default"));
    }

    @Override
    public boolean isWifiSimulationAllowedForSession(AttendanceSession session) {
        if (!isWifiSimulationEnabledInEnvironment()) {
            return false;
        }

        if (session == null || session.getTimetableSlot() == null
                || session.getTimetableSlot().getClassSection() == null) {
            return false;
        }

        String className = session.getTimetableSlot().getClassSection().getClassName();
        if (className == null || className.isBlank()) {
            return false;
        }

        return isClassInAllowedList(className);
    }

    @Override
    public String getSimulatedSsidForSession(AttendanceSession session) {
        // Gắn với AP mô phỏng của phòng học nếu phòng có Access Point đăng ký
        RoomWifiAccessPoint ap = getSimulatedApForRoom(session);
        if (ap != null && ap.getWifiAccessPoint() != null && ap.getWifiAccessPoint().getSsid() != null) {
            return ap.getWifiAccessPoint().getSsid();
        }
        return getSimulatedSsid();
    }

    @Override
    public String getSimulatedBssidForSession(AttendanceSession session) {
        // Gắn với AP mô phỏng của phòng học nếu phòng có Access Point đăng ký
        RoomWifiAccessPoint ap = getSimulatedApForRoom(session);
        if (ap != null && ap.getWifiAccessPoint() != null && ap.getWifiAccessPoint().getBssid() != null) {
            return ap.getWifiAccessPoint().getBssid();
        }
        return getSimulatedBssid();
    }

    private RoomWifiAccessPoint getSimulatedApForRoom(AttendanceSession session) {
        if (session == null || session.getTimetableSlot() == null || session.getTimetableSlot().getRoom() == null) {
            return null;
        }
        Long roomId = session.getTimetableSlot().getRoom().getId();
        if (roomId == null) return null;

        List<RoomWifiAccessPoint> aps = roomWifiAccessPointRepository.findByRoomId(roomId);
        if (aps == null || aps.isEmpty()) return null;

        // Ưu tiên AP mô phỏng AndroidWifi/02:00:00:00:00:00 nếu phòng đã gắn
        Optional<RoomWifiAccessPoint> emulatorAp = aps.stream()
                .filter(a -> a.getWifiAccessPoint() != null &&
                        a.getWifiAccessPoint().getStatus() == WifiApStatus.ACTIVE &&
                        ("02:00:00:00:00:00".equalsIgnoreCase(a.getWifiAccessPoint().getBssid()) ||
                         (a.getWifiAccessPoint().getSsid() != null && a.getWifiAccessPoint().getSsid().toLowerCase().contains("androidwifi"))))
                .findFirst();

        if (emulatorAp.isPresent()) {
            return emulatorAp.get();
        }

        return null;
    }

    @Override
    public boolean isSimulatedWifiMatchForSession(AttendanceSession session, String studentBssid, String studentSsid) {
        if (!isWifiSimulationAllowedForSession(session)) {
            return false;
        }

        // 1. Kiểm tra đối soát với AP của phòng học
        if (session != null && session.getTimetableSlot() != null && session.getTimetableSlot().getRoom() != null) {
            Long roomId = session.getTimetableSlot().getRoom().getId();
            if (roomId != null) {
                List<RoomWifiAccessPoint> aps = roomWifiAccessPointRepository.findByRoomId(roomId);
                if (aps != null && !aps.isEmpty()) {
                    boolean roomApMatched = aps.stream().anyMatch(rap -> {
                        if (rap.getWifiAccessPoint() == null || rap.getWifiAccessPoint().getStatus() != WifiApStatus.ACTIVE) {
                            return false;
                        }
                        String bssid = rap.getWifiAccessPoint().getBssid();
                        String ssid = rap.getWifiAccessPoint().getSsid();
                        if (studentBssid != null && bssid != null && studentBssid.trim().equalsIgnoreCase(bssid.trim())) {
                            return true;
                        }
                        if (studentSsid != null && ssid != null && studentSsid.trim().equalsIgnoreCase(ssid.trim())) {
                            return true;
                        }
                        return false;
                    });
                    if (roomApMatched) {
                        return true;
                    }
                }
            }
        }

        // 2. Đối soát với chữ ký giả lập Android Emulator tiêu chuẩn
        return isSimulatedWifiMatch(studentBssid, studentSsid);
    }

    @Override
    public boolean isSimulatedWifiMatch(String studentBssid, String studentSsid) {
        if (studentBssid != null && !studentBssid.isBlank()) {
            String cleanBssid = studentBssid.trim().toLowerCase();
            if (cleanBssid.equalsIgnoreCase(simulatedBssid)
                    || cleanBssid.equalsIgnoreCase("02:00:00:00:00:00")
                    || cleanBssid.equalsIgnoreCase("DEMO_WIFI_SIMULATION")) {
                return true;
            }
        }

        if (studentSsid != null && !studentSsid.isBlank()) {
            String cleanSsid = studentSsid.trim().toLowerCase();
            if (cleanSsid.equalsIgnoreCase(simulatedSsid)
                    || cleanSsid.contains("androidwifi")
                    || cleanSsid.contains("mô phỏng")
                    || cleanSsid.contains("mo phong")
                    || cleanSsid.contains("simulation")
                    || cleanSsid.contains("demo")) {
                return true;
            }
        }

        return false;
    }

    private boolean isClassInAllowedList(String className) {
        if (allowedClassName == null || allowedClassName.isBlank()) {
            return true; // Trong môi trường dev/demo, nếu không cấu hình whitelist cụ thể thì cho phép tất cả các lớp demo
        }
        String trimmed = allowedClassName.trim();
        if ("*".equals(trimmed) || "all".equalsIgnoreCase(trimmed)) {
            return true;
        }
        String[] parts = trimmed.split(",");
        for (String part : parts) {
            String p = part.trim();
            if ("*".equals(p) || "all".equalsIgnoreCase(p)) {
                return true;
            }
            if (p.equalsIgnoreCase(className.trim())) {
                return true;
            }
            if (p.endsWith("*") && className.trim().toLowerCase().startsWith(p.substring(0, p.length() - 1).toLowerCase())) {
                return true;
            }
        }
        return false;
    }
}
