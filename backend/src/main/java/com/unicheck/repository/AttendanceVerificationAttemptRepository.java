package com.unicheck.repository;

import com.unicheck.model.entity.AttendanceVerificationAttempt;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttendanceVerificationAttemptRepository extends JpaRepository<AttendanceVerificationAttempt, Long> {

    List<AttendanceVerificationAttempt> findByRecheckRequestIdOrderByAttemptedAtDesc(Long recheckRequestId);

    List<AttendanceVerificationAttempt> findByStudentIdOrderByAttemptedAtDesc(Long studentId);
}
