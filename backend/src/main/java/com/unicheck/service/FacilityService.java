package com.unicheck.service;

import com.unicheck.model.dto.*;
import com.unicheck.model.enums.RoomStatus;
import com.unicheck.model.enums.RoomType;
import com.unicheck.model.enums.WifiApStatus;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface FacilityService {

    // === Classrooms (Rooms) Management ===
    Page<RoomResponse> getRooms(String search, String building, RoomType type, RoomStatus status, Pageable pageable);

    RoomDetailResponse getRoomById(Long id);

    RoomResponse createRoom(RoomCreateRequest request, HttpServletRequest httpRequest);

    RoomResponse updateRoom(Long id, RoomUpdateRequest request, HttpServletRequest httpRequest);

    void deleteRoom(Long id, HttpServletRequest httpRequest);

    boolean existsByCode(String code);

    List<String> getBuildings();

    FacilityStatsResponse getFacilityStats();

    // === Wi-Fi Access Points Management ===
    Page<WifiAccessPointResponse> getWifiAccessPoints(String search, WifiApStatus status, Pageable pageable);

    WifiAccessPointResponse getWifiAccessPointById(Long id);

    WifiAccessPointResponse createWifiAccessPoint(WifiAccessPointCreateRequest request, HttpServletRequest httpRequest);

    WifiAccessPointResponse updateWifiAccessPoint(Long id, WifiAccessPointUpdateRequest request, HttpServletRequest httpRequest);

    void deleteWifiAccessPoint(Long id, HttpServletRequest httpRequest);

    boolean existsByBssid(String bssid);

    // === Room - Wi-Fi AP Association Management ===
    List<RoomWifiAccessPointResponse> getRoomWifiAccessPoints(Long roomId);

    RoomWifiAccessPointResponse assignWifiApToRoom(Long roomId, AssignWifiApRequest request, HttpServletRequest httpRequest);

    void unassignWifiApFromRoom(Long roomId, Long accessPointId, HttpServletRequest httpRequest);
}
