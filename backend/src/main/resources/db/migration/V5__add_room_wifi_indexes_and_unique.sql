-- ==============================================================================
-- UniCheck - Flyway Migration V5: Additional Indexes & Constraints for TASK-02C
-- Facilities, Classrooms, Wi-Fi Access Points and Mapping
-- ==============================================================================

-- 1. Unique constraint to prevent duplicate assignment of the same Wi-Fi AP to the same Room
CREATE UNIQUE INDEX IF NOT EXISTS idx_room_wifi_room_ap_unique 
    ON room_wifi_access_points(room_id, wifi_access_point_id);

-- 2. Performance indexes for rooms
CREATE INDEX IF NOT EXISTS idx_rooms_building_status 
    ON rooms(building, status);

CREATE INDEX IF NOT EXISTS idx_rooms_type 
    ON rooms(type);

-- 3. Performance indexes for wifi_access_points
CREATE INDEX IF NOT EXISTS idx_wifi_ap_status 
    ON wifi_access_points(status);

CREATE INDEX IF NOT EXISTS idx_wifi_ap_ssid 
    ON wifi_access_points(ssid);

-- 4. Performance indexes for room_wifi_access_points
CREATE INDEX IF NOT EXISTS idx_room_wifi_room_id 
    ON room_wifi_access_points(room_id);

CREATE INDEX IF NOT EXISTS idx_room_wifi_ap_id 
    ON room_wifi_access_points(wifi_access_point_id);
