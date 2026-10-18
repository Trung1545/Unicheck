package com.unicheck.repository;

import com.unicheck.model.entity.Enrollment;
import com.unicheck.model.enums.EnrollmentStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface EnrollmentRepository extends JpaRepository<Enrollment, Long>, JpaSpecificationExecutor<Enrollment> {

    Optional<Enrollment> findByClassSection_ClassNameAndStudent_Id(String className, Long studentId);

    boolean existsByClassSection_ClassNameAndStudent_Id(String className, Long studentId);

    long countByClassSection_ClassName(String className);

    long countByClassSection_ClassNameAndStatus(String className, EnrollmentStatus status);

    List<Enrollment> findByClassSection_ClassName(String className);

    Page<Enrollment> findByClassSection_ClassName(String className, Pageable pageable);

    Page<Enrollment> findByStudent_Id(Long studentId, Pageable pageable);

    long countByStudent_Id(Long studentId);

    @Query(value = "SELECT COUNT(*) FROM student_grades WHERE enrollment_id = :enrollmentId", nativeQuery = true)
    long countStudentGradesByEnrollmentId(@Param("enrollmentId") Long enrollmentId);

    @Query(value = "SELECT COUNT(*) FROM assignment_submissions WHERE enrollment_id = :enrollmentId", nativeQuery = true)
    long countAssignmentSubmissionsByEnrollmentId(@Param("enrollmentId") Long enrollmentId);

    @Query(value = "SELECT COUNT(*) FROM student_attendances sa " +
            "JOIN attendance_sessions s ON sa.session_id = s.id " +
            "JOIN timetable_slots ts ON s.timetable_slot_id = ts.id " +
            "WHERE ts.class_name = :className AND sa.student_id = :studentId", nativeQuery = true)
    long countAttendanceRecords(@Param("className") String className, @Param("studentId") Long studentId);
}
