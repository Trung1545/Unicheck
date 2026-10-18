-- ==============================================================================
-- UniCheck - Flyway Migration V6: Timetable Slots Indexes and Performance Optimization
-- TASK-02D (F-16: Timetable & Slot Operations)
-- ==============================================================================

-- 1. Index on timetable_slots for rapid conflict resolution (room + date + slot_number)
CREATE INDEX IF NOT EXISTS idx_timetable_slots_room_date_slot 
    ON timetable_slots(room_id, date, slot_number);

-- 2. Index on timetable_slots status for active vs cancelled filtering
CREATE INDEX IF NOT EXISTS idx_timetable_slots_status 
    ON timetable_slots(status);

-- 3. Index on timetable_slots slot_type_id
CREATE INDEX IF NOT EXISTS idx_timetable_slots_slot_type_id 
    ON timetable_slots(slot_type_id);

-- 4. Index on slot_types semester_id and slot_index
CREATE INDEX IF NOT EXISTS idx_slot_types_semester_id 
    ON slot_types(semester_id);

CREATE INDEX IF NOT EXISTS idx_slot_types_slot_index 
    ON slot_types(slot_index);

-- 5. Index on holidays for quick semester holiday checks
CREATE INDEX IF NOT EXISTS idx_holidays_semester_date 
    ON holidays(semester_id, holiday_date);

-- 6. Index on semester_weekdays
CREATE INDEX IF NOT EXISTS idx_semester_weekdays_semester_weekday 
    ON semester_weekdays(semester_id, weekday);
