package com.unicheck.repository;

import com.unicheck.model.entity.AttendanceSession;
import com.unicheck.model.enums.AttendanceSessionStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface AttendanceSessionRepository extends JpaRepository<AttendanceSession, Long>, JpaSpecificationExecutor<AttendanceSession> {

    Optional<AttendanceSession> findByTimetableSlotId(Long timetableSlotId);

    boolean existsByTimetableSlotId(Long timetableSlotId);

    /**
     * Tìm kiếm phiên điểm danh với bộ lọc đa điều kiện
     */
    @Query("SELECT s FROM AttendanceSession s " +
           "JOIN s.timetableSlot ts " +
           "JOIN ts.classSection cs " +
           "LEFT JOIN cs.course c " +
           "LEFT JOIN cs.semester sem " +
           "LEFT JOIN s.lecturer l " +
           "LEFT JOIN ts.room r " +
           "WHERE (:semesterId IS NULL OR sem.id = :semesterId) " +
           "AND (:className IS NULL OR cs.className = :className) " +
           "AND (:lecturerId IS NULL OR s.lecturer.id = :lecturerId OR cs.lecturer.id = :lecturerId) " +
           "AND (:date IS NULL OR ts.date = :date) " +
           "AND (:status IS NULL OR s.status = :status) " +
           "AND (cast(:searchPattern as string) IS NULL " +
           "     OR LOWER(cs.className) LIKE cast(:searchPattern as string) " +
           "     OR LOWER(c.name) LIKE cast(:searchPattern as string) " +
           "     OR LOWER(c.code) LIKE cast(:searchPattern as string) " +
           "     OR LOWER(r.code) LIKE cast(:searchPattern as string) " +
           "     OR LOWER(l.fullName) LIKE cast(:searchPattern as string))")
    Page<AttendanceSession> findSessionsWithFilter(
            @Param("semesterId") Long semesterId,
            @Param("className") String className,
            @Param("lecturerId") Long lecturerId,
            @Param("date") LocalDate date,
            @Param("status") AttendanceSessionStatus status,
            @Param("searchPattern") String searchPattern,
            Pageable pageable
    );

    /**
     * Nguyên tử mở phiên: Chuyển trạng thái từ expectedStatus sang targetStatus và ghi nhận thời gian mở
     */
    @Modifying
    @Query("UPDATE AttendanceSession s SET s.status = :targetStatus, s.openedAt = :openedAt " +
           "WHERE s.id = :id AND s.status = :expectedStatus")
    int openSessionAtomic(
            @Param("id") Long id,
            @Param("openedAt") LocalDateTime openedAt,
            @Param("targetStatus") AttendanceSessionStatus targetStatus,
            @Param("expectedStatus") AttendanceSessionStatus expectedStatus
    );

    /**
     * Nguyên tử mở phiên có kèm cập nhật thời gian xoay vòng QR động (qrRotationIntervalSeconds)
     */
    @Modifying
    @Query("UPDATE AttendanceSession s SET s.status = :targetStatus, s.openedAt = :openedAt, s.qrRotationIntervalSeconds = :interval " +
           "WHERE s.id = :id AND s.status = :expectedStatus")
    int openSessionAtomicWithInterval(
            @Param("id") Long id,
            @Param("openedAt") LocalDateTime openedAt,
            @Param("targetStatus") AttendanceSessionStatus targetStatus,
            @Param("expectedStatus") AttendanceSessionStatus expectedStatus,
            @Param("interval") Integer interval
    );

    /**
     * Nguyên tử đóng phiên: Chuyển trạng thái từ expectedStatus sang targetStatus và ghi nhận thời gian đóng
     */
    @Modifying
    @Query("UPDATE AttendanceSession s SET s.status = :targetStatus, s.closedAt = :closedAt " +
           "WHERE s.id = :id AND s.status = :expectedStatus")
    int closeSessionAtomic(
            @Param("id") Long id,
            @Param("closedAt") LocalDateTime closedAt,
            @Param("targetStatus") AttendanceSessionStatus targetStatus,
            @Param("expectedStatus") AttendanceSessionStatus expectedStatus
    );

    /**
     * Thống kê số lượng phiên theo ngày và trạng thái
     */
    @Query("SELECT COUNT(s) FROM AttendanceSession s " +
           "JOIN s.timetableSlot ts " +
           "WHERE ts.date = :date " +
           "AND (:lecturerId IS NULL OR s.lecturer.id = :lecturerId)")
    long countSessionsByDateAndLecturer(
            @Param("date") LocalDate date,
            @Param("lecturerId") Long lecturerId
    );

    @Query("SELECT COUNT(s) FROM AttendanceSession s " +
           "JOIN s.timetableSlot ts " +
           "WHERE ts.date = :date " +
           "AND s.status = :status " +
           "AND (:lecturerId IS NULL OR s.lecturer.id = :lecturerId)")
    long countSessionsByDateAndStatusAndLecturer(
            @Param("date") LocalDate date,
            @Param("status") AttendanceSessionStatus status,
            @Param("lecturerId") Long lecturerId
    );

    @Query("SELECT COUNT(s) FROM AttendanceSession s " +
           "WHERE s.status = :status " +
           "AND (:lecturerId IS NULL OR s.lecturer.id = :lecturerId)")
    long countSessionsByStatusAndLecturer(
            @Param("status") AttendanceSessionStatus status,
            @Param("lecturerId") Long lecturerId
    );
}
