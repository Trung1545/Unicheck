package com.unicheck.repository;

import com.unicheck.model.entity.Semester;
import com.unicheck.model.enums.SemesterStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SemesterRepository extends JpaRepository<Semester, Long>, JpaSpecificationExecutor<Semester> {

    Optional<Semester> findByCode(String code);

    boolean existsByCode(String code);

    boolean existsByCodeAndIdNot(String code, Long id);

    Optional<Semester> findFirstByStatusOrderByStartDateDesc(SemesterStatus status);

    List<Semester> findByStatus(SemesterStatus status);
}
