package com.unicheck.repository;

import com.unicheck.model.entity.LecturerProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LecturerProfileRepository extends JpaRepository<LecturerProfile, Long> {

    Optional<LecturerProfile> findByUserId(Long userId);
}
