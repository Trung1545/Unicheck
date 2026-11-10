-- ==============================================================================
-- UniCheck - Flyway Migration V9: Add QR Rotation Interval Column to Attendance Sessions
-- Allows lecturers to configure dynamic QR rotation interval (10s to 300s, default 10s)
-- ==============================================================================

ALTER TABLE attendance_sessions ADD COLUMN IF NOT EXISTS qr_rotation_interval_seconds INTEGER DEFAULT 10;

UPDATE attendance_sessions SET qr_rotation_interval_seconds = 10 WHERE qr_rotation_interval_seconds IS NULL;
