package com.unicheck.repository;

import com.unicheck.model.entity.AttendanceAdjustmentHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface AttendanceAdjustmentHistoryRepository extends JpaRepository<AttendanceAdjustmentHistory, Long> {

    @Query("SELECT h FROM AttendanceAdjustmentHistory h " +
           "JOIN FETCH h.student s " +
           "JOIN FETCH h.modifiedBy m " +
           "WHERE h.session.id = :sessionId " +
           "ORDER BY h.modifiedAt DESC")
    List<AttendanceAdjustmentHistory> findBySessionIdWithDetails(@Param("sessionId") Long sessionId);

    List<AttendanceAdjustmentHistory> findBySessionIdOrderByModifiedAtDesc(Long sessionId);

    List<AttendanceAdjustmentHistory> findBySessionIdAndStudentIdOrderByModifiedAtDesc(Long sessionId, Long studentId);
}
