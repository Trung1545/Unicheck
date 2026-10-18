-- ==============================================================================
-- UniCheck - Flyway Migration V7: Attendance Sessions & Configs Optimization
-- TASK-05: Attendance Session Management
-- ==============================================================================

-- 1. Allow attendance_sessions.opened_at to be NULL for sessions created before opening
ALTER TABLE attendance_sessions ALTER COLUMN opened_at DROP NOT NULL;
ALTER TABLE attendance_sessions ALTER COLUMN opened_at DROP DEFAULT;

-- 2. Set default status to 'CREATED' for new attendance sessions
ALTER TABLE attendance_sessions ALTER COLUMN status SET DEFAULT 'CREATED';

-- 3. Add unique constraint on timetable_slot_id to prevent duplicate sessions for the same class slot
CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_sessions_slot_unique 
    ON attendance_sessions(timetable_slot_id);

-- 4. Additional performance indexes for attendance session management
CREATE INDEX IF NOT EXISTS idx_attendance_sessions_status 
    ON attendance_sessions(status);

CREATE INDEX IF NOT EXISTS idx_attendance_sessions_lecturer_id 
    ON attendance_sessions(lecturer_id);

CREATE INDEX IF NOT EXISTS idx_attendance_sessions_created_at 
    ON attendance_sessions(created_at);

CREATE INDEX IF NOT EXISTS idx_student_attendances_session_student 
    ON student_attendances(session_id, student_id);

-- 5. Insert default attendance configuration if not already present (ANSI SQL compatible with H2 & PostgreSQL)
INSERT INTO attendance_configs (
    config_key, 
    manual_enabled, 
    absent_threshold_minutes, 
    min_attendance_percentage, 
    face_recognition_enabled, 
    max_attempts, 
    wifi_location_enabled,
    created_at,
    updated_at
)
SELECT 
    'DEFAULT', 
    TRUE, 
    15, 
    80.0, 
    TRUE, 
    3, 
    TRUE,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
WHERE NOT EXISTS (
    SELECT 1 FROM attendance_configs WHERE config_key = 'DEFAULT'
);
