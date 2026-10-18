package com.unicheck.service;

import com.unicheck.model.dto.*;
import com.unicheck.model.enums.TimetableSlotStatus;
import com.unicheck.security.UserPrincipal;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;

public interface TimetableService {

    List<TimetableSlotResponse> getTimetableSlots(
            LocalDate startDate,
            LocalDate endDate,
            Long semesterId,
            String className,
            Long lecturerId,
            Long roomId,
            TimetableSlotStatus status
    );

    Page<TimetableSlotResponse> getTimetableSlotsPaged(
            LocalDate startDate,
            LocalDate endDate,
            Long semesterId,
            String className,
            Long lecturerId,
            Long roomId,
            TimetableSlotStatus status,
            Pageable pageable
    );

    TimetableSlotResponse getTimetableSlotById(Long id);

    TimetableSlotResponse createTimetableSlot(TimetableSlotCreateRequest request);

    TimetableSlotResponse updateTimetableSlot(Long id, TimetableSlotUpdateRequest request);

    void deleteTimetableSlot(Long id);

    List<TimetableSlotResponse> getMyTimetable(UserPrincipal principal, LocalDate startDate, LocalDate endDate);

    TimetableConflictCheckResponse checkConflict(TimetableConflictCheckRequest request);

    List<SlotTypeResponse> getSlotTypes(Long semesterId);

    TimetableStatsResponse getTimetableStats(Long semesterId, LocalDate weekStartDate);

    void publishTimetable(Long semesterId);
}
