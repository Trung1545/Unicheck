-- ==============================================================================
-- UniCheck - Safe Data Patch for FPT Seed Enum Mismatch
-- Target: unicheck_db (Development)
-- Resolves BUG-01 (SemesterStatus.COMPLETED -> CLOSED)
-- Resolves BUG-02 (TimetableSlotStatus.IN_PROGRESS -> SCHEDULED)
-- Safe, transactional, idempotent: only affects invalid enum values
-- ==============================================================================

BEGIN;

-- 1. Fix SemesterStatus mismatch: COMPLETED -> CLOSED for past semesters
UPDATE semesters 
SET status = 'CLOSED', updated_at = CURRENT_TIMESTAMP
WHERE status = 'COMPLETED';

-- 2. Fix TimetableSlotStatus mismatch: IN_PROGRESS -> SCHEDULED for future slots
UPDATE timetable_slots 
SET status = 'SCHEDULED', updated_at = CURRENT_TIMESTAMP
WHERE status = 'IN_PROGRESS';

-- 3. Verification Assertion inside transaction (will rollback if any invalid status remains)
DO $$
DECLARE
    invalid_semesters INT;
    invalid_slots INT;
BEGIN
    SELECT count(*) INTO invalid_semesters 
    FROM semesters 
    WHERE status NOT IN ('ACTIVE', 'UPCOMING', 'CLOSED', 'ARCHIVED');

    SELECT count(*) INTO invalid_slots 
    FROM timetable_slots 
    WHERE status NOT IN ('SCHEDULED', 'COMPLETED', 'CANCELLED', 'RESCHEDULED');

    IF invalid_semesters > 0 OR invalid_slots > 0 THEN
        RAISE EXCEPTION 'Validation failed: Found % invalid semesters and % invalid timetable slots!', 
            invalid_semesters, invalid_slots;
    END IF;
END $$;

COMMIT;
