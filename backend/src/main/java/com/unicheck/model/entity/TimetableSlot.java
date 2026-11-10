package com.unicheck.model.entity;

import com.unicheck.model.enums.TimetableSlotStatus;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Entity
@Table(
    name = "timetable_slots",
    indexes = {
        @Index(name = "idx_timetable_slots_class_name", columnList = "class_name"),
        @Index(name = "idx_timetable_slots_date", columnList = "date"),
        @Index(name = "idx_timetable_slots_room_date_slot", columnList = "room_id, date, slot_number"),
        @Index(name = "idx_timetable_slots_room_date_time", columnList = "room_id, date, start_time, end_time"),
        @Index(name = "idx_timetable_slots_status", columnList = "status"),
        @Index(name = "idx_timetable_slots_slot_type_id", columnList = "slot_type_id")
    }
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TimetableSlot {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "class_name", referencedColumnName = "class_name", nullable = false)
    private ClassSection classSection;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id")
    private Room room;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "slot_type_id")
    private SlotType slotType;

    @Column(name = "date", nullable = false)
    private LocalDate date;

    @Column(name = "day_of_week", nullable = false)
    private Integer dayOfWeek;

    @Column(name = "slot_number", nullable = false)
    private Integer slotNumber;

    @Column(name = "end_slot_number")
    private Integer endSlotNumber;

    @Column(name = "start_time")
    private LocalTime startTime;

    @Column(name = "end_time")
    private LocalTime endTime;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false, length = 20)
    @Builder.Default
    private TimetableSlotStatus status = TimetableSlotStatus.SCHEDULED;

    @Column(name = "note", length = 500)
    private String note;

    @Column(name = "created_at", nullable = false, updatable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at", nullable = false)
    @Builder.Default
    private LocalDateTime updatedAt = LocalDateTime.now();

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (updatedAt == null) {
            updatedAt = LocalDateTime.now();
        }
        if (dayOfWeek == null && date != null) {
            dayOfWeek = date.getDayOfWeek().getValue();
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
        if (dayOfWeek == null && date != null) {
            dayOfWeek = date.getDayOfWeek().getValue();
        }
    }
}
