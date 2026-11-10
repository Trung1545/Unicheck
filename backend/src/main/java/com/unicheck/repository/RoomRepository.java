package com.unicheck.repository;

import com.unicheck.model.entity.Room;
import com.unicheck.model.enums.RoomStatus;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoomRepository extends JpaRepository<Room, Long>, JpaSpecificationExecutor<Room> {

    Optional<Room> findByCode(String code);

    boolean existsByCode(String code);

    boolean existsByCodeAndIdNot(String code, Long id);

    @Query("SELECT DISTINCT r.building FROM Room r WHERE r.building IS NOT NULL AND TRIM(r.building) != '' ORDER BY r.building ASC")
    List<String> findDistinctBuildings();

    long countByStatus(RoomStatus status);

    @Query("SELECT COALESCE(SUM(r.capacity), 0) FROM Room r")
    long sumTotalCapacity();

    @Query(value = "SELECT COUNT(*) FROM timetable_slots WHERE room_id = :roomId", nativeQuery = true)
    long countTimetableSlotsByRoomId(@Param("roomId") Long roomId);

    @Query(value = "SELECT COUNT(*) FROM schedule_requests WHERE requested_room_id = :roomId", nativeQuery = true)
    long countScheduleRequestsByRoomId(@Param("roomId") Long roomId);

    @Query(value = "SELECT COUNT(DISTINCT room_id) FROM room_wifi_access_points", nativeQuery = true)
    long countRoomsWithWifi();

    /**
     * Pessimistic write lock for preventing race condition / concurrent room booking collisions.
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT r FROM Room r WHERE r.id = :id")
    Optional<Room> findByIdForUpdate(@Param("id") Long id);
}
