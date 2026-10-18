package com.unicheck.service.impl;

import com.unicheck.exception.AppException;
import com.unicheck.exception.ErrorCode;
import com.unicheck.model.dto.*;
import com.unicheck.model.entity.Room;
import com.unicheck.model.entity.RoomWifiAccessPoint;
import com.unicheck.model.entity.User;
import com.unicheck.model.entity.WifiAccessPoint;
import com.unicheck.model.enums.RoomStatus;
import com.unicheck.model.enums.RoomType;
import com.unicheck.model.enums.WifiApStatus;
import com.unicheck.repository.RoomRepository;
import com.unicheck.repository.RoomWifiAccessPointRepository;
import com.unicheck.repository.UserRepository;
import com.unicheck.repository.WifiAccessPointRepository;
import com.unicheck.service.FacilityService;
import com.unicheck.service.SystemLogService;
import jakarta.persistence.criteria.Predicate;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class FacilityServiceImpl implements FacilityService {

    private static final Pattern BSSID_PATTERN = Pattern.compile("^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$");

    private final RoomRepository roomRepository;
    private final WifiAccessPointRepository wifiAccessPointRepository;
    private final RoomWifiAccessPointRepository roomWifiAccessPointRepository;
    private final UserRepository userRepository;
    private final SystemLogService systemLogService;

    // =========================================================================
    // 1. Classrooms (Rooms) Management
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public Page<RoomResponse> getRooms(
            String search,
            String building,
            RoomType type,
            RoomStatus status,
            Pageable pageable) {

        Specification<Room> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(search)) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                Predicate codeMatch = cb.like(cb.lower(root.get("code")), searchPattern);
                Predicate nameMatch = cb.like(cb.lower(root.get("name")), searchPattern);
                Predicate buildingMatch = cb.like(cb.lower(root.get("building")), searchPattern);
                predicates.add(cb.or(codeMatch, nameMatch, buildingMatch));
            }

            if (StringUtils.hasText(building)) {
                predicates.add(cb.equal(cb.lower(root.get("building")), building.trim().toLowerCase()));
            }

            if (type != null) {
                predicates.add(cb.equal(root.get("type"), type));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Room> page = roomRepository.findAll(spec, pageable);
        return page.map(RoomResponse::fromEntity);
    }

    @Override
    @Transactional(readOnly = true)
    public RoomDetailResponse getRoomById(Long id) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_NOT_FOUND, "Không tìm thấy phòng học với ID: " + id));
        return RoomDetailResponse.fromEntity(room);
    }

    @Override
    @Transactional
    public RoomResponse createRoom(RoomCreateRequest request, HttpServletRequest httpRequest) {
        String cleanCode = request.getCode().trim();
        if (roomRepository.existsByCode(cleanCode)) {
            throw new AppException(ErrorCode.ROOM_ALREADY_EXISTS, "Mã phòng học '" + cleanCode + "' đã tồn tại trong hệ thống");
        }

        Room room = Room.builder()
                .code(cleanCode)
                .name(request.getName().trim())
                .capacity(request.getCapacity())
                .building(request.getBuilding() != null ? request.getBuilding().trim() : null)
                .description(request.getDescription())
                .floor(request.getFloor())
                .gridRow(request.getGridRow())
                .gridCol(request.getGridCol())
                .gridRowSpan(request.getGridRowSpan())
                .gridColSpan(request.getGridColSpan())
                .type(request.getType() != null ? request.getType() : RoomType.THEORY)
                .status(request.getStatus() != null ? request.getStatus() : RoomStatus.AVAILABLE)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        Room saved = roomRepository.save(room);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_ROOM_CREATE",
                "Tạo mới phòng học: " + saved.getCode() + " - " + saved.getName() + " (Sức chứa: " + saved.getCapacity() + ")",
                getCurrentAuthenticatedUser(),
                null,
                saved.getCode(),
                httpRequest
        );

        return RoomResponse.fromEntity(saved);
    }

    @Override
    @Transactional
    public RoomResponse updateRoom(Long id, RoomUpdateRequest request, HttpServletRequest httpRequest) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_NOT_FOUND, "Không tìm thấy phòng học với ID: " + id));

        String oldRoomInfo = room.getCode() + " - " + room.getName();

        if (StringUtils.hasText(request.getCode())) {
            String cleanCode = request.getCode().trim();
            if (!cleanCode.equalsIgnoreCase(room.getCode()) && roomRepository.existsByCodeAndIdNot(cleanCode, id)) {
                throw new AppException(ErrorCode.ROOM_ALREADY_EXISTS, "Mã phòng học '" + cleanCode + "' đã được sử dụng bởi phòng khác");
            }
            room.setCode(cleanCode);
        }

        room.setName(request.getName().trim());
        room.setCapacity(request.getCapacity());
        room.setBuilding(request.getBuilding() != null ? request.getBuilding().trim() : null);
        room.setDescription(request.getDescription());
        room.setFloor(request.getFloor());
        room.setGridRow(request.getGridRow());
        room.setGridCol(request.getGridCol());
        room.setGridRowSpan(request.getGridRowSpan());
        room.setGridColSpan(request.getGridColSpan());
        if (request.getType() != null) {
            room.setType(request.getType());
        }
        if (request.getStatus() != null) {
            room.setStatus(request.getStatus());
        }
        room.setUpdatedAt(LocalDateTime.now());

        Room updated = roomRepository.save(room);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_ROOM_UPDATE",
                "Cập nhật thông tin phòng học: " + updated.getCode() + " - " + updated.getName(),
                getCurrentAuthenticatedUser(),
                oldRoomInfo,
                updated.getCode() + " - " + updated.getName(),
                httpRequest
        );

        return RoomResponse.fromEntity(updated);
    }

    @Override
    @Transactional
    public void deleteRoom(Long id, HttpServletRequest httpRequest) {
        Room room = roomRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_NOT_FOUND, "Không tìm thấy phòng học với ID: " + id));

        // Integrity check: Check if the room is referenced by timetable_slots or schedule_requests
        long timetableCount = roomRepository.countTimetableSlotsByRoomId(id);
        if (timetableCount > 0) {
            throw new AppException(
                    ErrorCode.ROOM_IN_USE,
                    "Phòng học " + room.getCode() + " đang được xếp lịch trong thời khóa biểu (" + timetableCount + " ca học), không thể xóa!"
            );
        }

        long scheduleReqCount = roomRepository.countScheduleRequestsByRoomId(id);
        if (scheduleReqCount > 0) {
            throw new AppException(
                    ErrorCode.ROOM_IN_USE,
                    "Phòng học " + room.getCode() + " đang có yêu cầu đổi phòng/lịch học (" + scheduleReqCount + " đơn), không thể xóa!"
            );
        }

        String roomInfo = room.getCode() + " - " + room.getName();
        roomRepository.delete(room);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_ROOM_DELETE",
                "Xóa phòng học khỏi hệ thống: " + roomInfo,
                getCurrentAuthenticatedUser(),
                roomInfo,
                null,
                httpRequest
        );
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByCode(String code) {
        if (!StringUtils.hasText(code)) return false;
        return roomRepository.existsByCode(code.trim());
    }

    @Override
    @Transactional(readOnly = true)
    public List<String> getBuildings() {
        return roomRepository.findDistinctBuildings();
    }

    @Override
    @Transactional(readOnly = true)
    public FacilityStatsResponse getFacilityStats() {
        long totalRooms = roomRepository.count();
        long availableRooms = roomRepository.countByStatus(RoomStatus.AVAILABLE);
        long occupiedRooms = roomRepository.countByStatus(RoomStatus.OCCUPIED);
        long maintenanceRooms = roomRepository.countByStatus(RoomStatus.MAINTENANCE);
        long totalCapacity = roomRepository.sumTotalCapacity();

        double readinessRate = totalRooms > 0
                ? Math.round((availableRooms * 100.0 / totalRooms) * 10.0) / 10.0
                : 100.0;

        long activeWifiAps = wifiAccessPointRepository.countByStatus(WifiApStatus.ACTIVE);
        long totalWifiAps = wifiAccessPointRepository.count();

        // Online kiosks: 1 kiosk per operational room
        long onlineKiosks = availableRooms + occupiedRooms;
        long totalKiosks = totalRooms;

        return FacilityStatsResponse.builder()
                .totalRooms(totalRooms)
                .availableRooms(availableRooms)
                .occupiedRooms(occupiedRooms)
                .maintenanceRooms(maintenanceRooms)
                .readinessRate(readinessRate)
                .totalCapacity(totalCapacity)
                .activeStudentsCount(occupiedRooms * 45) // Estimated concurrent students in classes
                .activeWifiAps(activeWifiAps)
                .totalWifiAps(totalWifiAps)
                .averageRssiDbm(-62)
                .onlineKiosks(onlineKiosks)
                .totalKiosks(totalKiosks)
                .averageFaceLatencyMs(180)
                .build();
    }

    // =========================================================================
    // 2. Wi-Fi Access Points Management
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public Page<WifiAccessPointResponse> getWifiAccessPoints(
            String search,
            WifiApStatus status,
            Pageable pageable) {

        Specification<WifiAccessPoint> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (StringUtils.hasText(search)) {
                String searchPattern = "%" + search.trim().toLowerCase() + "%";
                Predicate ssidMatch = cb.like(cb.lower(root.get("ssid")), searchPattern);
                Predicate bssidMatch = cb.like(cb.lower(root.get("bssid")), searchPattern);
                Predicate nameMatch = cb.like(cb.lower(root.get("name")), searchPattern);
                Predicate locationMatch = cb.like(cb.lower(root.get("location")), searchPattern);
                predicates.add(cb.or(ssidMatch, bssidMatch, nameMatch, locationMatch));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<WifiAccessPoint> page = wifiAccessPointRepository.findAll(spec, pageable);
        return page.map(ap -> {
            long assignedRooms = roomWifiAccessPointRepository.countByWifiAccessPointId(ap.getId());
            return WifiAccessPointResponse.fromEntity(ap, assignedRooms);
        });
    }

    @Override
    @Transactional(readOnly = true)
    public WifiAccessPointResponse getWifiAccessPointById(Long id) {
        WifiAccessPoint ap = wifiAccessPointRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.WIFI_AP_NOT_FOUND, "Không tìm thấy Wi-Fi AP với ID: " + id));
        long assignedRooms = roomWifiAccessPointRepository.countByWifiAccessPointId(ap.getId());
        return WifiAccessPointResponse.fromEntity(ap, assignedRooms);
    }

    @Override
    @Transactional
    public WifiAccessPointResponse createWifiAccessPoint(WifiAccessPointCreateRequest request, HttpServletRequest httpRequest) {
        String normalizedBssid = normalizeAndValidateBssid(request.getBssid());

        if (wifiAccessPointRepository.existsByBssidIgnoreCase(normalizedBssid)) {
            throw new AppException(ErrorCode.WIFI_AP_ALREADY_EXISTS, "BSSID '" + normalizedBssid + "' đã tồn tại trong hệ thống");
        }

        WifiAccessPoint ap = WifiAccessPoint.builder()
                .ssid(request.getSsid().trim())
                .bssid(normalizedBssid)
                .name(request.getName() != null ? request.getName().trim() : null)
                .location(request.getLocation() != null ? request.getLocation().trim() : null)
                .status(request.getStatus() != null ? request.getStatus() : WifiApStatus.ACTIVE)
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        WifiAccessPoint saved = wifiAccessPointRepository.save(ap);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_WIFI_CREATE",
                "Tạo mới Wi-Fi AP: " + saved.getSsid() + " (" + saved.getBssid() + ")",
                getCurrentAuthenticatedUser(),
                null,
                saved.getBssid(),
                httpRequest
        );

        return WifiAccessPointResponse.fromEntity(saved, 0L);
    }

    @Override
    @Transactional
    public WifiAccessPointResponse updateWifiAccessPoint(Long id, WifiAccessPointUpdateRequest request, HttpServletRequest httpRequest) {
        WifiAccessPoint ap = wifiAccessPointRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.WIFI_AP_NOT_FOUND, "Không tìm thấy Wi-Fi AP với ID: " + id));

        String oldApInfo = ap.getSsid() + " (" + ap.getBssid() + ")";
        String normalizedBssid = normalizeAndValidateBssid(request.getBssid());

        if (!normalizedBssid.equalsIgnoreCase(ap.getBssid()) &&
                wifiAccessPointRepository.existsByBssidIgnoreCaseAndIdNot(normalizedBssid, id)) {
            throw new AppException(ErrorCode.WIFI_AP_ALREADY_EXISTS, "BSSID '" + normalizedBssid + "' đã được sử dụng bởi AP khác");
        }

        ap.setSsid(request.getSsid().trim());
        ap.setBssid(normalizedBssid);
        ap.setName(request.getName() != null ? request.getName().trim() : null);
        ap.setLocation(request.getLocation() != null ? request.getLocation().trim() : null);
        if (request.getStatus() != null) {
            ap.setStatus(request.getStatus());
        }
        ap.setUpdatedAt(LocalDateTime.now());

        WifiAccessPoint updated = wifiAccessPointRepository.save(ap);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_WIFI_UPDATE",
                "Cập nhật Wi-Fi AP: " + updated.getSsid() + " (" + updated.getBssid() + ")",
                getCurrentAuthenticatedUser(),
                oldApInfo,
                updated.getSsid() + " (" + updated.getBssid() + ")",
                httpRequest
        );

        long assignedRooms = roomWifiAccessPointRepository.countByWifiAccessPointId(updated.getId());
        return WifiAccessPointResponse.fromEntity(updated, assignedRooms);
    }

    @Override
    @Transactional
    public void deleteWifiAccessPoint(Long id, HttpServletRequest httpRequest) {
        WifiAccessPoint ap = wifiAccessPointRepository.findById(id)
                .orElseThrow(() -> new AppException(ErrorCode.WIFI_AP_NOT_FOUND, "Không tìm thấy Wi-Fi AP với ID: " + id));

        String apInfo = ap.getSsid() + " (" + ap.getBssid() + ")";
        wifiAccessPointRepository.delete(ap);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_WIFI_DELETE",
                "Xóa Wi-Fi AP khỏi hệ thống: " + apInfo,
                getCurrentAuthenticatedUser(),
                apInfo,
                null,
                httpRequest
        );
    }

    @Override
    @Transactional(readOnly = true)
    public boolean existsByBssid(String bssid) {
        if (!StringUtils.hasText(bssid)) return false;
        try {
            String normalized = normalizeAndValidateBssid(bssid);
            return wifiAccessPointRepository.existsByBssidIgnoreCase(normalized);
        } catch (Exception e) {
            return false;
        }
    }

    // =========================================================================
    // 3. Room - Wi-Fi AP Mapping Management
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public List<RoomWifiAccessPointResponse> getRoomWifiAccessPoints(Long roomId) {
        if (!roomRepository.existsById(roomId)) {
            throw new AppException(ErrorCode.ROOM_NOT_FOUND, "Không tìm thấy phòng học với ID: " + roomId);
        }
        List<RoomWifiAccessPoint> mappings = roomWifiAccessPointRepository.findByRoomId(roomId);
        return mappings.stream()
                .map(RoomWifiAccessPointResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional
    public RoomWifiAccessPointResponse assignWifiApToRoom(
            Long roomId,
            AssignWifiApRequest request,
            HttpServletRequest httpRequest) {

        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_NOT_FOUND, "Không tìm thấy phòng học với ID: " + roomId));

        WifiAccessPoint ap;

        if (request.getWifiAccessPointId() != null) {
            ap = wifiAccessPointRepository.findById(request.getWifiAccessPointId())
                    .orElseThrow(() -> new AppException(ErrorCode.WIFI_AP_NOT_FOUND, "Không tìm thấy Wi-Fi AP với ID: " + request.getWifiAccessPointId()));
        } else if (StringUtils.hasText(request.getBssid()) && StringUtils.hasText(request.getSsid())) {
            String normalizedBssid = normalizeAndValidateBssid(request.getBssid());
            ap = wifiAccessPointRepository.findByBssidIgnoreCase(normalizedBssid)
                    .orElseGet(() -> {
                        WifiAccessPoint newAp = WifiAccessPoint.builder()
                                .ssid(request.getSsid().trim())
                                .bssid(normalizedBssid)
                                .name(request.getApName() != null ? request.getApName().trim() : request.getSsid().trim())
                                .location(request.getLocation() != null ? request.getLocation().trim() : room.getName())
                                .status(WifiApStatus.ACTIVE)
                                .createdAt(LocalDateTime.now())
                                .updatedAt(LocalDateTime.now())
                                .build();
                        return wifiAccessPointRepository.save(newAp);
                    });
        } else {
            throw new AppException(ErrorCode.INVALID_REQUEST, "Cần cung cấp wifiAccessPointId hoặc thông tin SSID & BSSID hợp lệ");
        }

        // Prevent duplicate mapping
        if (roomWifiAccessPointRepository.existsByRoomIdAndWifiAccessPointId(roomId, ap.getId())) {
            throw new AppException(
                    ErrorCode.ROOM_WIFI_ALREADY_LINKED,
                    "Thiết bị Wi-Fi AP '" + ap.getSsid() + " (" + ap.getBssid() + ")' đã được gán vào phòng " + room.getCode()
            );
        }

        RoomWifiAccessPoint mapping = RoomWifiAccessPoint.builder()
                .room(room)
                .wifiAccessPoint(ap)
                .signalStrength(request.getSignalStrength() != null ? request.getSignalStrength() : -60)
                .isPrimary(Boolean.TRUE.equals(request.getIsPrimary()))
                .positionNote(request.getPositionNote())
                .createdAt(LocalDateTime.now())
                .updatedAt(LocalDateTime.now())
                .build();

        RoomWifiAccessPoint saved = roomWifiAccessPointRepository.save(mapping);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_ROOM_WIFI_ASSIGN",
                "Gán Wi-Fi AP: " + ap.getSsid() + " (" + ap.getBssid() + ") vào phòng " + room.getCode(),
                getCurrentAuthenticatedUser(),
                null,
                room.getCode() + " <-> " + ap.getBssid(),
                httpRequest
        );

        return RoomWifiAccessPointResponse.fromEntity(saved);
    }

    @Override
    @Transactional
    public void unassignWifiApFromRoom(Long roomId, Long accessPointId, HttpServletRequest httpRequest) {
        Room room = roomRepository.findById(roomId)
                .orElseThrow(() -> new AppException(ErrorCode.ROOM_NOT_FOUND, "Không tìm thấy phòng học với ID: " + roomId));

        RoomWifiAccessPoint mapping = roomWifiAccessPointRepository.findByRoomIdAndWifiAccessPointId(roomId, accessPointId)
                .orElseThrow(() -> new AppException(
                        ErrorCode.ROOM_WIFI_NOT_FOUND,
                        "Không tìm thấy liên kết giữa phòng " + room.getCode() + " và AP có ID: " + accessPointId
                ));

        String apInfo = mapping.getWifiAccessPoint().getSsid() + " (" + mapping.getWifiAccessPoint().getBssid() + ")";
        roomWifiAccessPointRepository.delete(mapping);

        // Audit Log
        systemLogService.logAudit(
                "FACILITY_ROOM_WIFI_UNASSIGN",
                "Gỡ liên kết Wi-Fi AP: " + apInfo + " khỏi phòng " + room.getCode(),
                getCurrentAuthenticatedUser(),
                room.getCode() + " <-> " + mapping.getWifiAccessPoint().getBssid(),
                null,
                httpRequest
        );
    }

    // =========================================================================
    // Private Helpers
    // =========================================================================

    private String normalizeAndValidateBssid(String bssid) {
        if (!StringUtils.hasText(bssid)) {
            throw new AppException(ErrorCode.INVALID_BSSID_FORMAT, "Địa chỉ BSSID/MAC không được để trống");
        }

        String cleaned = bssid.trim().toUpperCase().replace("-", ":");
        if (!BSSID_PATTERN.matcher(cleaned).matches()) {
            throw new AppException(
                    ErrorCode.INVALID_BSSID_FORMAT,
                    "Địa chỉ BSSID/MAC '" + bssid + "' không đúng định dạng chuẩn XX:XX:XX:XX:XX:XX"
            );
        }
        return cleaned;
    }

    private User getCurrentAuthenticatedUser() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.isAuthenticated() && !"anonymousUser".equals(authentication.getPrincipal())) {
                return userRepository.findByUsername(authentication.getName()).orElse(null);
            }
        } catch (Exception ignored) {}
        return null;
    }
}
