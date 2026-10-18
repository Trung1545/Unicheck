package com.unicheck.repository;

import com.unicheck.model.entity.Holiday;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface HolidayRepository extends JpaRepository<Holiday, Long> {

    boolean existsBySemesterIdAndHolidayDate(Long semesterId, LocalDate holidayDate);

    List<Holiday> findBySemesterId(Long semesterId);

    List<Holiday> findBySemesterIdAndHolidayDateBetween(Long semesterId, LocalDate startDate, LocalDate endDate);
}
