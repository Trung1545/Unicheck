-- ==============================================================================
-- UniCheck - Flyway Migration V8: Add Time Columns and Interval Index to Timetable Slots
-- Interval Conflict Prevention and Real-time Available Room Checking
-- ==============================================================================

-- 1. Add end_slot_number, start_time, and end_time columns
ALTER TABLE timetable_slots ADD COLUMN IF NOT EXISTS end_slot_number INTEGER;
ALTER TABLE timetable_slots ADD COLUMN IF NOT EXISTS start_time TIME;
ALTER TABLE timetable_slots ADD COLUMN IF NOT EXISTS end_time TIME;

-- 2. Backfill end_slot_number where null (default: 3-period block for 1, 4, 7, 10; otherwise single period)
UPDATE timetable_slots 
SET end_slot_number = slot_number + 2 
WHERE end_slot_number IS NULL AND slot_number IN (1, 4, 7, 10);

UPDATE timetable_slots 
SET end_slot_number = slot_number 
WHERE end_slot_number IS NULL;

-- 3. Backfill start_time and end_time based on slot_number and end_slot_number
UPDATE timetable_slots 
SET start_time = TIME '07:00:00', end_time = TIME '09:25:00' 
WHERE slot_number = 1 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '07:50:00', end_time = TIME '08:35:00' 
WHERE slot_number = 2 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '08:40:00', end_time = TIME '09:25:00' 
WHERE slot_number = 3 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '09:45:00', end_time = TIME '12:10:00' 
WHERE slot_number = 4 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '10:35:00', end_time = TIME '11:20:00' 
WHERE slot_number = 5 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '11:25:00', end_time = TIME '12:10:00' 
WHERE slot_number = 6 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '12:45:00', end_time = TIME '15:10:00' 
WHERE slot_number = 7 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '13:35:00', end_time = TIME '14:20:00' 
WHERE slot_number = 8 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '14:25:00', end_time = TIME '15:10:00' 
WHERE slot_number = 9 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '15:30:00', end_time = TIME '17:55:00' 
WHERE slot_number = 10 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '16:20:00', end_time = TIME '17:05:00' 
WHERE slot_number = 11 AND (start_time IS NULL OR end_time IS NULL);

UPDATE timetable_slots 
SET start_time = TIME '17:10:00', end_time = TIME '17:55:00' 
WHERE slot_number = 12 AND (start_time IS NULL OR end_time IS NULL);

-- Fallback for any other remaining slots
UPDATE timetable_slots 
SET start_time = TIME '07:00:00', end_time = TIME '07:45:00' 
WHERE start_time IS NULL;

-- 4. Create performance index for interval conflict checking and room availability
CREATE INDEX IF NOT EXISTS idx_timetable_slots_room_date_time 
    ON timetable_slots(room_id, date, start_time, end_time);
