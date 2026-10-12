package com.unicheck.repository;

import com.unicheck.model.entity.AccessLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AccessLogRepository extends JpaRepository<AccessLog, Long> {

    List<AccessLog> findByUserId(Long userId);

    List<AccessLog> findByUserIdOrderByAccessTimeDesc(Long userId);
}
