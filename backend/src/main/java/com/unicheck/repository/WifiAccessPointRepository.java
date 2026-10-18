package com.unicheck.repository;

import com.unicheck.model.entity.WifiAccessPoint;
import com.unicheck.model.enums.WifiApStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface WifiAccessPointRepository extends JpaRepository<WifiAccessPoint, Long>, JpaSpecificationExecutor<WifiAccessPoint> {

    Optional<WifiAccessPoint> findByBssidIgnoreCase(String bssid);

    boolean existsByBssidIgnoreCase(String bssid);

    boolean existsByBssidIgnoreCaseAndIdNot(String bssid, Long id);

    long countByStatus(WifiApStatus status);
}
