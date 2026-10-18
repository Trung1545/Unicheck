package com.unicheck.repository;

import com.unicheck.model.entity.TimetableSlot;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface TimetableSlotRepository extends JpaRepository<TimetableSlot, Long>, JpaSpecificationExecutor<TimetableSlot> {

    /**
     * 1. Tìm xung đột phòng học: cùng phòng, cùng ngày, cùng tiết (loại trừ slot hiện tại và slot đã hủy)
     */
    @Query("SELECT s FROM TimetableSlot s " +
           "WHERE s.room.id = :roomId " +
           "AND s.date = :date " +
           "AND s.slotNumber = :slotNumber " +
           "AND (:excludeId IS NULL OR s.id != :excludeId) " +
           "AND s.status != com.unicheck.model.enums.TimetableSlotStatus.CANCELLED")
    List<TimetableSlot> findRoomConflicts(
            @Param("roomId") Long roomId,
            @Param("date") LocalDate date,
            @Param("slotNumber") Integer slotNumber,
            @Param("excludeId") Long excludeId
    );

    /**
     * 2. Tìm xung đột giảng viên: cùng giảng viên, cùng ngày, cùng tiết (loại trừ slot hiện tại và slot đã hủy)
     */
    @Query("SELECT s FROM TimetableSlot s " +
           "WHERE s.classSection.lecturer.id = :lecturerId " +
           "AND s.date = :date " +
           "AND s.slotNumber = :slotNumber " +
           "AND (:excludeId IS NULL OR s.id != :excludeId) " +
           "AND s.status != com.unicheck.model.enums.TimetableSlotStatus.CANCELLED")
    List<TimetableSlot> findLecturerConflicts(
            @Param("lecturerId") Long lecturerId,
            @Param("date") LocalDate date,
            @Param("slotNumber") Integer slotNumber,
            @Param("excludeId") Long excludeId
    );

    /**
     * 3. Tìm xung đột lớp học phần: cùng lớp học phần, cùng ngày, cùng tiết (loại trừ slot hiện tại và slot đã hủy)
     */
    @Query("SELECT s FROM TimetableSlot s " +
           "WHERE s.classSection.className = :className " +
           "AND s.date = :date " +
           "AND s.slotNumber = :slotNumber " +
           "AND (:excludeId IS NULL OR s.id != :excludeId) " +
           "AND s.status != com.unicheck.model.enums.TimetableSlotStatus.CANCELLED")
    List<TimetableSlot> findClassConflicts(
            @Param("className") String className,
            @Param("date") LocalDate date,
            @Param("slotNumber") Integer slotNumber,
            @Param("excludeId") Long excludeId
    );

    /**
     * 4. Kiểm tra phiên điểm danh phụ thuộc (AttendanceSession) qua bảng attendance_sessions
     */
    @Query(value = "SELECT COUNT(*) FROM attendance_sessions WHERE timetable_slot_id = :slotId", nativeQuery = true)
    long countAttendanceSessionsBySlotId(@Param("slotId") Long slotId);

    /**
     * 5. Thời khóa biểu của sinh viên theo các lớp học phần đã ghi danh
     */
    @Query("SELECT s FROM TimetableSlot s " +
           "WHERE s.classSection.className IN (" +
           "    SELECT e.classSection.className FROM Enrollment e " +
           "    WHERE e.student.id = :studentId " +
           "    AND e.status = com.unicheck.model.enums.EnrollmentStatus.ENROLLED" +
           ") " +
           "AND s.date BETWEEN :startDate AND :endDate " +
           "AND s.status != com.unicheck.model.enums.TimetableSlotStatus.CANCELLED " +
           "ORDER BY s.date ASC, s.slotNumber ASC")
    List<TimetableSlot> findStudentTimetable(
            @Param("studentId") Long studentId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    /**
     * 6. Thời khóa biểu của giảng viên theo các lớp học phần được phân công
     */
    @Query("SELECT s FROM TimetableSlot s " +
           "WHERE s.classSection.lecturer.id = :lecturerId " +
           "AND s.date BETWEEN :startDate AND :endDate " +
           "AND s.status != com.unicheck.model.enums.TimetableSlotStatus.CANCELLED " +
           "ORDER BY s.date ASC, s.slotNumber ASC")
    List<TimetableSlot> findLecturerTimetable(
            @Param("lecturerId") Long lecturerId,
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    /**
     * 7. Lấy danh sách slot trong tuần phục vụ lưới lịch tuần
     */
    @Query("SELECT s FROM TimetableSlot s " +
           "LEFT JOIN FETCH s.classSection cs " +
           "LEFT JOIN FETCH cs.course c " +
           "LEFT JOIN FETCH cs.lecturer l " +
           "LEFT JOIN FETCH s.room r " +
           "LEFT JOIN FETCH s.slotType st " +
           "WHERE s.date BETWEEN :startDate AND :endDate " +
           "AND (:semesterId IS NULL OR cs.semester.id = :semesterId) " +
           "AND (:className IS NULL OR cs.className = :className) " +
           "AND (:lecturerId IS NULL OR cs.lecturer.id = :lecturerId) " +
           "AND (:roomId IS NULL OR r.id = :roomId) " +
           "ORDER BY s.date ASC, s.slotNumber ASC")
    List<TimetableSlot> findSlotsForWeek(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate,
            @Param("semesterId") Long semesterId,
            @Param("className") String className,
            @Param("lecturerId") Long lecturerId,
            @Param("roomId") Long roomId
    );

    /**
     * 8. Đếm số slot học trong khoảng thời gian
     */
    @Query("SELECT COUNT(s) FROM TimetableSlot s " +
           "WHERE s.date BETWEEN :startDate AND :endDate " +
           "AND s.status != com.unicheck.model.enums.TimetableSlotStatus.CANCELLED")
    long countActiveSlotsInDateRange(
            @Param("startDate") LocalDate startDate,
            @Param("endDate") LocalDate endDate
    );

    /**
     * 9. Đếm số slot theo lớp học phần
     */
    long countByClassSectionClassName(String className);
}
