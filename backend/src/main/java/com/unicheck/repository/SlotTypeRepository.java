package com.unicheck.repository;

import com.unicheck.model.entity.SlotType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SlotTypeRepository extends JpaRepository<SlotType, Long> {

    List<SlotType> findBySemesterIdOrderBySlotIndexAsc(Long semesterId);

    List<SlotType> findBySemesterIdIsNullOrderBySlotIndexAsc();

    List<SlotType> findAllByOrderBySlotIndexAsc();

    Optional<SlotType> findBySlotIndex(Integer slotIndex);
}
