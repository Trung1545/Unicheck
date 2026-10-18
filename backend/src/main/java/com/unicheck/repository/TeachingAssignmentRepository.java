package com.unicheck.repository;

import com.unicheck.model.entity.TeachingAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TeachingAssignmentRepository extends JpaRepository<TeachingAssignment, Long> {

    Optional<TeachingAssignment> findByLecturer_IdAndCourse_IdAndSemester_Id(Long lecturerId, Long courseId, Long semesterId);

    boolean existsByLecturer_IdAndCourse_IdAndSemester_Id(Long lecturerId, Long courseId, Long semesterId);

    List<TeachingAssignment> findByLecturer_Id(Long lecturerId);

    List<TeachingAssignment> findBySemester_Id(Long semesterId);

    long countByLecturer_Id(Long lecturerId);
}
