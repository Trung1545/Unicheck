package com.unicheck.controller;

import com.unicheck.common.dto.ApiResponse;
import com.unicheck.common.dto.PageResponse;
import com.unicheck.model.dto.*;
import com.unicheck.model.enums.RoomStatus;
import com.unicheck.model.enums.RoomType;
import com.unicheck.model.enums.WifiApStatus;
import com.unicheck.service.FacilityService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping({"/api/facilities", "/api/v1/facilities"})
@RequiredArgsConstructor
public class FacilityController {

    private final FacilityService facilityService;

    // =========================================================================
    // 1. Rooms Endpoints
    // =========================================================================

    /**
     * Lấy danh sách phòng học có phân trang, tìm kiếm và lọc
     */
    @GetMapping("/rooms")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<RoomResponse>>> getRooms(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String building,
            @RequestParam(required = false) RoomType type,
            @RequestParam(required = false) RoomStatus status,
            @PageableDefault(size = 10, sort = "code", direction = Sort.Direction.ASC) Pageable pageable) {

        Page<RoomResponse> page = facilityService.getRooms(search, building, type, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách phòng học thành công"));
    }

    /**
     * Lấy chỉ số thống kê cơ sở vật chất (KPI cards)
     */
    @GetMapping("/rooms/stats")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<FacilityStatsResponse>> getFacilityStats() {
        FacilityStatsResponse stats = facilityService.getFacilityStats();
        return ResponseEntity.ok(ApiResponse.ok(stats, "Lấy thống kê cơ sở vật chất thành công"));
    }

    /**
     * Lấy danh sách tên tòa nhà phục vụ bộ lọc
     */
    @GetMapping("/rooms/buildings")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<String>>> getBuildings() {
        List<String> buildings = facilityService.getBuildings();
        return ResponseEntity.ok(ApiResponse.ok(buildings, "Lấy danh sách tòa nhà thành công"));
    }

    /**
     * Kiểm tra tính khả dụng của mã phòng học
     */
    @GetMapping("/rooms/check-code")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkRoomCode(
            @RequestParam String code) {
        boolean exists = facilityService.existsByCode(code);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("available", !exists),
                exists ? "Mã phòng học đã tồn tại" : "Mã phòng học khả dụng"
        ));
    }

    /**
     * Lấy chi tiết phòng học theo ID
     */
    @GetMapping("/rooms/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<RoomDetailResponse>> getRoomById(
            @PathVariable Long id) {
        RoomDetailResponse room = facilityService.getRoomById(id);
        return ResponseEntity.ok(ApiResponse.ok(room, "Lấy chi tiết phòng học thành công"));
    }

    /**
     * Tạo mới phòng học
     */
    @PostMapping("/rooms")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<RoomResponse>> createRoom(
            @Valid @RequestBody RoomCreateRequest request,
            HttpServletRequest httpRequest) {
        RoomResponse created = facilityService.createRoom(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Tạo phòng học mới thành công"));
    }

    /**
     * Cập nhật thông tin phòng học
     */
    @PutMapping("/rooms/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<RoomResponse>> updateRoom(
            @PathVariable Long id,
            @Valid @RequestBody RoomUpdateRequest request,
            HttpServletRequest httpRequest) {
        RoomResponse updated = facilityService.updateRoom(id, request, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Cập nhật thông tin phòng học thành công"));
    }

    /**
     * Xóa phòng học
     */
    @DeleteMapping("/rooms/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteRoom(
            @PathVariable Long id,
            HttpServletRequest httpRequest) {
        facilityService.deleteRoom(id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Xóa phòng học thành công"));
    }

    // =========================================================================
    // 2. Wi-Fi Access Points Endpoints
    // =========================================================================

    /**
     * Lấy danh sách Wi-Fi AP có phân trang, tìm kiếm và lọc
     */
    @GetMapping("/wifi-ap")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<PageResponse<WifiAccessPointResponse>>> getWifiAccessPoints(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) WifiApStatus status,
            @PageableDefault(size = 20, sort = "bssid", direction = Sort.Direction.ASC) Pageable pageable) {

        Page<WifiAccessPointResponse> page = facilityService.getWifiAccessPoints(search, status, pageable);
        return ResponseEntity.ok(ApiResponse.ok(PageResponse.of(page), "Lấy danh sách Wi-Fi AP thành công"));
    }

    /**
     * Kiểm tra tính khả dụng của địa chỉ BSSID/MAC
     */
    @GetMapping("/wifi-ap/check-bssid")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Map<String, Boolean>>> checkBssid(
            @RequestParam String bssid) {
        boolean exists = facilityService.existsByBssid(bssid);
        return ResponseEntity.ok(ApiResponse.ok(
                Map.of("available", !exists),
                exists ? "Địa chỉ BSSID đã tồn tại" : "Địa chỉ BSSID khả dụng"
        ));
    }

    /**
     * Lấy chi tiết Wi-Fi AP theo ID
     */
    @GetMapping("/wifi-ap/{id}")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<WifiAccessPointResponse>> getWifiAccessPointById(
            @PathVariable Long id) {
        WifiAccessPointResponse ap = facilityService.getWifiAccessPointById(id);
        return ResponseEntity.ok(ApiResponse.ok(ap, "Lấy thông tin Wi-Fi AP thành công"));
    }

    /**
     * Tạo mới Wi-Fi AP
     */
    @PostMapping("/wifi-ap")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<WifiAccessPointResponse>> createWifiAccessPoint(
            @Valid @RequestBody WifiAccessPointCreateRequest request,
            HttpServletRequest httpRequest) {
        WifiAccessPointResponse created = facilityService.createWifiAccessPoint(request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(created, "Thêm mới Wi-Fi Access Point thành công"));
    }

    /**
     * Cập nhật Wi-Fi AP
     */
    @PutMapping("/wifi-ap/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<WifiAccessPointResponse>> updateWifiAccessPoint(
            @PathVariable Long id,
            @Valid @RequestBody WifiAccessPointUpdateRequest request,
            HttpServletRequest httpRequest) {
        WifiAccessPointResponse updated = facilityService.updateWifiAccessPoint(id, request, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(updated, "Cập nhật Wi-Fi Access Point thành công"));
    }

    /**
     * Xóa Wi-Fi AP
     */
    @DeleteMapping("/wifi-ap/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> deleteWifiAccessPoint(
            @PathVariable Long id,
            HttpServletRequest httpRequest) {
        facilityService.deleteWifiAccessPoint(id, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Xóa Wi-Fi Access Point thành công"));
    }

    // =========================================================================
    // 3. Room - Wi-Fi AP Association Endpoints
    // =========================================================================

    /**
     * Lấy danh sách Wi-Fi AP được gán cho một phòng học cụ thể
     */
    @GetMapping("/rooms/{id}/wifi-ap")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<List<RoomWifiAccessPointResponse>>> getRoomWifiAccessPoints(
            @PathVariable Long id) {
        List<RoomWifiAccessPointResponse> aps = facilityService.getRoomWifiAccessPoints(id);
        return ResponseEntity.ok(ApiResponse.ok(aps, "Lấy danh sách Wi-Fi AP của phòng thành công"));
    }

    /**
     * Gán Wi-Fi AP vào phòng học
     */
    @PostMapping("/rooms/{id}/wifi-ap")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<RoomWifiAccessPointResponse>> assignWifiApToRoom(
            @PathVariable Long id,
            @Valid @RequestBody AssignWifiApRequest request,
            HttpServletRequest httpRequest) {
        RoomWifiAccessPointResponse mapped = facilityService.assignWifiApToRoom(id, request, httpRequest);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(mapped, "Gán Wi-Fi Access Point vào phòng thành công"));
    }

    /**
     * Hủy liên kết Wi-Fi AP khỏi phòng học
     */
    @DeleteMapping("/rooms/{id}/wifi-ap/{accessPointId}")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse<Void>> unassignWifiApFromRoom(
            @PathVariable Long id,
            @PathVariable Long accessPointId,
            HttpServletRequest httpRequest) {
        facilityService.unassignWifiApFromRoom(id, accessPointId, httpRequest);
        return ResponseEntity.ok(ApiResponse.ok(null, "Hủy gán Wi-Fi Access Point khỏi phòng thành công"));
    }
}
