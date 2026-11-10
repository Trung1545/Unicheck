package com.unicheck.repository;

import com.unicheck.model.entity.AttendanceRecheckRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface AttendanceRecheckRequestRepository extends JpaRepository<AttendanceRecheckRequest, Long> {

    List<AttendanceRecheckRequest> findBySessionId(Long sessionId);

    Optional<AttendanceRecheckRequest> findFirstBySessionIdAndStudentIdAndStatus(Long sessionId, Long studentId, String status);

    List<AttendanceRecheckRequest> findByStudentIdAndStatusAndExpiresAtAfterOrderByRequestedAtDesc(
            Long studentId, String status, LocalDateTime now);

    @Query("SELECT r FROM AttendanceRecheckRequest r " +
           "JOIN FETCH r.session s " +
           "JOIN FETCH s.timetableSlot ts " +
           "JOIN FETCH ts.classSection cs " +
           "LEFT JOIN FETCH cs.course c " +
           "LEFT JOIN FETCH ts.room rm " +
           "JOIN FETCH r.requestedBy lec " +
           "WHERE r.student.id = :studentId " +
           "AND r.status = 'PENDING' " +
           "AND r.expiresAt > :now " +
           "ORDER BY r.requestedAt DESC")
    List<AttendanceRecheckRequest> findActivePendingRequestsForStudent(
            @Param("studentId") Long studentId,
            @Param("now") LocalDateTime now);

    @Query("SELECT r FROM AttendanceRecheckRequest r " +
           "JOIN FETCH r.student s " +
           "JOIN FETCH r.requestedBy lec " +
           "WHERE r.session.id = :sessionId " +
           "ORDER BY r.requestedAt DESC")
    List<AttendanceRecheckRequest> findBySessionIdWithDetails(@Param("sessionId") Long sessionId);
}
