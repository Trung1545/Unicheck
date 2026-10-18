package com.unicheck.repository;

import com.unicheck.model.entity.Course;
import com.unicheck.model.enums.CourseStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CourseRepository extends JpaRepository<Course, Long>, JpaSpecificationExecutor<Course> {

    Optional<Course> findByCode(String code);

    boolean existsByCode(String code);

    boolean existsByCodeAndIdNot(String code, Long id);

    List<Course> findByStatus(CourseStatus status);

    @Query("SELECT COUNT(c) > 0 FROM Course c JOIN c.prerequisites p WHERE p.id = :courseId")
    boolean isPrerequisiteForOthers(@Param("courseId") Long courseId);
}
