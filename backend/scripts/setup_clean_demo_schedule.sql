-- ==============================================================================
-- UniCheck - Demo Timetable & Single Test Class Setup
-- Target Environment: Development / Demo (unicheck_db)
-- Preserves: Users, Roles, Passwords, Profiles, Rooms, Courses, Semesters, AI Encodings
-- Cleans: Redundant timetable slots, attendance sessions, attendances, enrollments
-- ==============================================================================

BEGIN;

-- 1. CLEAN ATTENDANCE RECORDS (Child tables first)
DELETE FROM student_attendances;
DELETE FROM attendance_sessions;

-- 2. CLEAN TIMETABLE SLOTS
DELETE FROM timetable_slots;

-- 3. CLEAN OTHER CLASS SECTIONS AND KEEP ONLY SE1801-PRJ301
-- Clean enrollments of other classes and other students
DELETE FROM enrollments WHERE NOT (class_name = 'SE1801-PRJ301' AND student_id = 14);

-- Clean any other class sections
DELETE FROM class_sections WHERE class_name != 'SE1801-PRJ301';

-- Clean assignments of other classes if any exist
DELETE FROM assignments WHERE class_name != 'SE1801-PRJ301';
DELETE FROM chat_groups WHERE class_name != 'SE1801-PRJ301';
DELETE FROM academic_requests WHERE class_section_id IS NOT NULL AND class_section_id != 'SE1801-PRJ301';
DELETE FROM schedule_requests WHERE class_name != 'SE1801-PRJ301';

-- 4. UPDATE COURSE INFORMATION
UPDATE courses 
SET name = 'Java Web Application Development' 
WHERE code = 'PRJ301';

-- 5. ENSURE CLASS SECTION SE1801-PRJ301 IS CORRECTLY CONFIGURED
INSERT INTO class_sections (
    class_name, course_id, semester_id, lecturer_id, number_of_slots, max_students, current_enrollment, status
) VALUES (
    'SE1801-PRJ301',
    (SELECT id FROM courses WHERE code = 'PRJ301'),
    (SELECT id FROM semesters WHERE code = 'FALL2026'),
    (SELECT id FROM users WHERE username = 'gv_sonnt'),
    30, 30, 1, 'OPEN'
)
ON CONFLICT (class_name) DO UPDATE SET
    course_id = EXCLUDED.course_id,
    semester_id = EXCLUDED.semester_id,
    lecturer_id = EXCLUDED.lecturer_id,
    number_of_slots = 30,
    max_students = 30,
    current_enrollment = 1,
    status = 'OPEN';

-- 6. ENSURE TEACHING ASSIGNMENT FOR LECTURER NGUYEN TAN SON (gv_sonnt)
DELETE FROM teaching_assignments WHERE NOT (
    lecturer_id = (SELECT id FROM users WHERE username = 'gv_sonnt')
    AND course_id = (SELECT id FROM courses WHERE code = 'PRJ301')
    AND semester_id = (SELECT id FROM semesters WHERE code = 'FALL2026')
);

INSERT INTO teaching_assignments (lecturer_id, course_id, semester_id)
SELECT 
    (SELECT id FROM users WHERE username = 'gv_sonnt'),
    (SELECT id FROM courses WHERE code = 'PRJ301'),
    (SELECT id FROM semesters WHERE code = 'FALL2026')
WHERE NOT EXISTS (
    SELECT 1 FROM teaching_assignments 
    WHERE lecturer_id = (SELECT id FROM users WHERE username = 'gv_sonnt')
      AND course_id = (SELECT id FROM courses WHERE code = 'PRJ301')
      AND semester_id = (SELECT id FROM semesters WHERE code = 'FALL2026')
);

-- 7. ENSURE EXACTLY 1 TEST STUDENT IS ENROLLED (sv_he180001 - Bui Thi An)
INSERT INTO enrollments (class_name, student_id, student_code, status)
SELECT 
    'SE1801-PRJ301',
    (SELECT id FROM users WHERE username = 'sv_he180001'),
    'HE180001',
    'ENROLLED'
WHERE NOT EXISTS (
    SELECT 1 FROM enrollments 
    WHERE class_name = 'SE1801-PRJ301' 
      AND student_id = (SELECT id FROM users WHERE username = 'sv_he180001')
);

UPDATE enrollments 
SET status = 'ENROLLED' 
WHERE class_name = 'SE1801-PRJ301' 
  AND student_id = (SELECT id FROM users WHERE username = 'sv_he180001');

-- 8. ENSURE LECTURER gv_sonnt PASSWORD IS Password@123
UPDATE users 
SET password = '$2b$10$3eV87R/T4mW25MrL0m6yS.eB9rl6fz6YQ48eEU/M0SQzgrsroNWJy' 
WHERE username = 'gv_sonnt';

-- 9. CREATE EXACTLY 1 TIMETABLE SLOT FOR DEMO
-- Date: 2026-11-10 (Tuesday, day_of_week = 2)
-- Time: 07:00:00 - 09:25:00 (Slot 1)
-- Room: AL-L201
-- Class: SE1801-PRJ301
INSERT INTO timetable_slots (
    class_name, room_id, slot_type_id, date, day_of_week, slot_number, status, note
) VALUES (
    'SE1801-PRJ301',
    (SELECT id FROM rooms WHERE code = 'AL-L201'),
    (SELECT id FROM slot_types WHERE slot_index = 1 AND semester_id = (SELECT id FROM semesters WHERE code = 'FALL2026') LIMIT 1),
    '2026-11-10'::DATE,
    2,
    1,
    'SCHEDULED',
    'Buổi học môn Java Web Application Development'
);

-- 10. CREATE 1 ATTENDANCE SESSION IN 'CREATED' STATUS (Ready for lecturer to open)
INSERT INTO attendance_sessions (
    timetable_slot_id, lecturer_id, opened_at, closed_at, status, created_at
) VALUES (
    (SELECT id FROM timetable_slots WHERE class_name = 'SE1801-PRJ301' AND date = '2026-11-10'::DATE LIMIT 1),
    (SELECT id FROM users WHERE username = 'gv_sonnt'),
    NULL,
    NULL,
    'CREATED',
    CURRENT_TIMESTAMP
);

-- 11. REGISTER WIFI ACCESS POINT FOR ROOM AL-L201 (SUPPORT ANDROID EMULATOR)
INSERT INTO wifi_access_points (ssid, bssid, name, location, status) 
VALUES ('AndroidWifi', '02:00:00:00:00:00', 'AP Android Emulator Demo', 'Phòng học AL-L201 - Tòa Alpha Tầng 2', 'ACTIVE') 
ON CONFLICT (bssid) DO NOTHING;

INSERT INTO room_wifi_access_points (room_id, wifi_access_point_id, signal_strength, is_primary) 
SELECT 
    (SELECT id FROM rooms WHERE code = 'AL-L201'), 
    id, 
    -50, 
    FALSE 
FROM wifi_access_points 
WHERE bssid = '02:00:00:00:00:00' 
ON CONFLICT (room_id, wifi_access_point_id) DO NOTHING;

-- 12. UPDATE ATTENDANCE CONFIGURATION FOR DEMO
-- Set absent threshold to 180 minutes so student check-in is marked PRESENT during the class
-- Set wifi_location_enabled to FALSE to prevent Android emulator BSSID blockage
UPDATE attendance_configs 
SET absent_threshold_minutes = 180,
    wifi_location_enabled = FALSE
WHERE config_key = 'DEFAULT';

-- 13. RESET PRIMARY KEY SEQUENCES
SELECT setval('timetable_slots_id_seq', COALESCE((SELECT MAX(id) FROM timetable_slots), 1));
SELECT setval('attendance_sessions_id_seq', COALESCE((SELECT MAX(id) FROM attendance_sessions), 1));
SELECT setval('student_attendances_id_seq', COALESCE((SELECT MAX(id) FROM student_attendances), 1));
SELECT setval('enrollments_id_seq', COALESCE((SELECT MAX(id) FROM enrollments), 1));

COMMIT;
