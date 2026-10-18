package com.unicheck.repository;

import com.unicheck.model.entity.RoomWifiAccessPoint;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface RoomWifiAccessPointRepository extends JpaRepository<RoomWifiAccessPoint, Long> {

    List<RoomWifiAccessPoint> findByRoomId(Long roomId);

    List<RoomWifiAccessPoint> findByWifiAccessPointId(Long wifiAccessPointId);

    Optional<RoomWifiAccessPoint> findByRoomIdAndWifiAccessPointId(Long roomId, Long wifiAccessPointId);

    boolean existsByRoomIdAndWifiAccessPointId(Long roomId, Long wifiAccessPointId);

    @Modifying
    @Query("DELETE FROM RoomWifiAccessPoint r WHERE r.room.id = :roomId AND r.wifiAccessPoint.id = :wifiAccessPointId")
    void deleteByRoomIdAndWifiAccessPointId(@Param("roomId") Long roomId, @Param("wifiAccessPointId") Long wifiAccessPointId);

    long countByRoomId(Long roomId);

    long countByWifiAccessPointId(Long wifiAccessPointId);
}
