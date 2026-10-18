package com.unicheck.repository;

import com.unicheck.model.entity.SemesterConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface SemesterConfigRepository extends JpaRepository<SemesterConfig, Long> {

    Optional<SemesterConfig> findBySemesterId(Long semesterId);
}
