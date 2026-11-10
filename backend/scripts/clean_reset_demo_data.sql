-- ==============================================================================
-- UniCheck - Clean Reset Demo Data Script
-- Environment: Development / Demo (unicheck_db)
-- Preserves: Users, Roles, Passwords, Profiles, Face Encodings, Rooms, APs,
--            Courses, Semesters, Attendance Configs, Migrations
-- Cleans: Attendance Verification Attempts, Recheck Requests, Histories,
--         Student Attendances, Attendance Sessions, Timetable Slots,
--         Enrollments, Teaching Assignments, Class Sections
-- ==============================================================================

BEGIN;

-- 1. Operational Attendance Verification Attempts & Re-check Requests
DELETE FROM attendance_verification_attempts;
DELETE FROM attendance_recheck_requests;

-- 2. Operational Attendance Adjustments & Records
DELETE FROM attendance_adjustment_histories;
DELETE FROM student_attendances;

-- 3. Operational Attendance Sessions
DELETE FROM attendance_sessions;

-- 4. Dependent operational items tied to class sections & timetable slots
DELETE FROM assignment_submissions;
DELETE FROM assignments;
DELETE FROM chat_message_reactions;
DELETE FROM chat_message_reads;
DELETE FROM chat_messages;
DELETE FROM chat_group_members;
DELETE FROM chat_groups;
DELETE FROM academic_requests WHERE class_section_id IS NOT NULL;
DELETE FROM schedule_requests;

-- 5. Timetable Slots
DELETE FROM timetable_slots;

-- 6. Student Enrollments & Lecturer Teaching Assignments
DELETE FROM enrollments;
DELETE FROM teaching_assignments;

-- 7. Class Sections
DELETE FROM class_sections;

-- 8. Reset sequences for cleaned operational tables
ALTER SEQUENCE IF EXISTS attendance_verification_attempts_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS attendance_recheck_requests_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS attendance_adjustment_histories_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS student_attendances_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS attendance_sessions_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS timetable_slots_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS enrollments_id_seq RESTART WITH 1;
ALTER SEQUENCE IF EXISTS teaching_assignments_id_seq RESTART WITH 1;

COMMIT;
