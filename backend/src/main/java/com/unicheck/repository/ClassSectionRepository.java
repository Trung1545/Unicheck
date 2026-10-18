package com.unicheck.repository;

import com.unicheck.model.entity.ClassSection;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ClassSectionRepository extends JpaRepository<ClassSection, String>, JpaSpecificationExecutor<ClassSection> {

    Optional<ClassSection> findByClassName(String className);

    boolean existsByClassName(String className);

    @Query("SELECT COUNT(cs) > 0 FROM ClassSection cs WHERE cs.course.id = :courseId")
    boolean existsByCourseId(@Param("courseId") Long courseId);

    @Query("SELECT COUNT(cs) > 0 FROM ClassSection cs WHERE cs.semester.id = :semesterId")
    boolean existsBySemesterId(@Param("semesterId") Long semesterId);

    @Query("SELECT COUNT(cs) > 0 FROM ClassSection cs WHERE cs.lecturer.id = :lecturerId")
    boolean existsByLecturerId(@Param("lecturerId") Long lecturerId);

    long countBySemesterId(Long semesterId);

    long countByCourseId(Long courseId);

    long countByLecturerId(Long lecturerId);

    Page<ClassSection> findByLecturerId(Long lecturerId, Pageable pageable);

    @Query("SELECT cs FROM ClassSection cs JOIN Enrollment e ON e.classSection.className = cs.className WHERE e.student.id = :studentId")
    Page<ClassSection> findByStudentId(@Param("studentId") Long studentId, Pageable pageable);

    @Query(value = "SELECT COUNT(*) FROM timetable_slots WHERE class_name = :className", nativeQuery = true)
    long countTimetableSlots(@Param("className") String className);

    @Query(value = "SELECT COUNT(*) FROM assignments WHERE class_name = :className", nativeQuery = true)
    long countAssignments(@Param("className") String className);
}
