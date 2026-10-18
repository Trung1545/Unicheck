package com.unicheck.repository;

import com.unicheck.model.entity.FaceEncoding;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface FaceEncodingRepository extends JpaRepository<FaceEncoding, Long> {

    Optional<FaceEncoding> findByUserId(Long userId);

    boolean existsByUserId(Long userId);

    void deleteByUserId(Long userId);
}
