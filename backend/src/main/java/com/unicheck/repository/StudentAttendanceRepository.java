package com.unicheck.repository;

import com.unicheck.model.entity.StudentAttendance;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

@Repository
public interface StudentAttendanceRepository extends JpaRepository<StudentAttendance, Long> {

    List<StudentAttendance> findBySessionId(Long sessionId);

    Page<StudentAttendance> findBySessionId(Long sessionId, Pageable pageable);

    Optional<StudentAttendance> findBySessionIdAndStudentId(Long sessionId, Long studentId);

    boolean existsBySessionIdAndStudentId(Long sessionId, Long studentId);

    long countBySessionId(Long sessionId);

    long countBySessionIdAndStatusIn(Long sessionId, Collection<String> statuses);

    @Query("SELECT COUNT(sa) FROM StudentAttendance sa WHERE sa.session.id = :sessionId AND sa.status = 'PRESENT'")
    long countPresentBySessionId(@Param("sessionId") Long sessionId);

    @Query("SELECT sa FROM StudentAttendance sa " +
           "JOIN FETCH sa.student u " +
           "WHERE sa.session.id = :sessionId " +
           "ORDER BY sa.checkInTime DESC NULLS LAST, sa.createdAt DESC")
    List<StudentAttendance> findRecentCheckInsBySessionId(@Param("sessionId") Long sessionId, Pageable pageable);
}
