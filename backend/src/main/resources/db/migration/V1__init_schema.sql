-- ==============================================================================
-- UniCheck - Flyway Migration V1: Initial Database Schema (50 Tables)
-- Strictly adhering to Software Design Document ERD
-- ==============================================================================

-- 1. users
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255),
    full_name VARCHAR(150) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    dob DATE,
    phone VARCHAR(20),
    sex VARCHAR(10) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    face_data_status VARCHAR(20) DEFAULT 'NOT_REGISTERED',
    avatar VARCHAR(255),
    face_registration_attempts INT NOT NULL DEFAULT 0,
    face_registration_blocked_until TIMESTAMP,
    is_password_changed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 2. majors
CREATE TABLE majors (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    program_duration VARCHAR(50),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 3. specializations
CREATE TABLE specializations (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    major_id BIGINT REFERENCES majors(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. sub_specializations
CREATE TABLE sub_specializations (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    specialization_id BIGINT REFERENCES specializations(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5. student_profiles
CREATE TABLE student_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    course VARCHAR(20),
    gpa DOUBLE PRECISION DEFAULT 0.0,
    major_id BIGINT REFERENCES majors(id),
    specialization_id BIGINT REFERENCES specializations(id),
    sub_specialization_id BIGINT REFERENCES sub_specializations(id)
);

-- 6. lecturer_profiles
CREATE TABLE lecturer_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    department VARCHAR(100),
    expertise VARCHAR(100),
    bio TEXT
);

-- 7. lecturer_grade_otps
CREATE TABLE lecturer_grade_otps (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    otp_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP
);

-- 8. user_permissions
CREATE TABLE user_permissions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission VARCHAR(50) NOT NULL,
    granted_by BIGINT REFERENCES users(id),
    granted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 9. user_device_tokens
CREATE TABLE user_device_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token VARCHAR(255) NOT NULL,
    platform VARCHAR(50),
    device_id VARCHAR(100),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 10. face_encodings (Biometric privacy: only vector embedding stored, no raw face image)
CREATE TABLE face_encodings (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    encoding_data BYTEA NOT NULL,
    registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    liveness_verified BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 11. courses
CREATE TABLE courses (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    credits INT NOT NULL,
    number_of_slots INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    is_calculated_in_gpa BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. course_prerequisites
CREATE TABLE course_prerequisites (
    course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    prerequisite_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    PRIMARY KEY (course_id, prerequisite_id)
);

-- 13. specialization_courses
CREATE TABLE specialization_courses (
    id BIGSERIAL PRIMARY KEY,
    specialization_id BIGINT NOT NULL REFERENCES specializations(id) ON DELETE CASCADE,
    course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    order_index INT,
    semester INT,
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 14. sub_specialization_courses
CREATE TABLE sub_specialization_courses (
    id BIGSERIAL PRIMARY KEY,
    sub_specialization_id BIGINT NOT NULL REFERENCES sub_specializations(id) ON DELETE CASCADE,
    course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    order_index INT,
    semester INT,
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 15. grade_components
CREATE TABLE grade_components (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL,
    weight DOUBLE PRECISION NOT NULL,
    is_resit BOOLEAN NOT NULL DEFAULT FALSE,
    reference_component_id BIGINT REFERENCES grade_components(id),
    course_id BIGINT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 16. semesters
CREATE TABLE semesters (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    description TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 17. semester_configs
CREATE TABLE semester_configs (
    id BIGSERIAL PRIMARY KEY,
    semester_id BIGINT NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
    max_slot_per_day INT NOT NULL,
    slot_per_subject_per_week INT NOT NULL,
    slot_duration INT NOT NULL,
    is_published BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 18. semester_weekdays
CREATE TABLE semester_weekdays (
    id BIGSERIAL PRIMARY KEY,
    semester_id BIGINT NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
    weekday INT NOT NULL
);

-- 19. holidays
CREATE TABLE holidays (
    id BIGSERIAL PRIMARY KEY,
    semester_id BIGINT NOT NULL REFERENCES semesters(id) ON DELETE CASCADE,
    holiday_date DATE NOT NULL,
    description VARCHAR(255),
    is_recurring BOOLEAN NOT NULL DEFAULT FALSE
);

-- 20. slot_types
CREATE TABLE slot_types (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    slot_index INT NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    description VARCHAR(255),
    semester_id BIGINT REFERENCES semesters(id) ON DELETE CASCADE,
    duration VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 21. rooms
CREATE TABLE rooms (
    id BIGSERIAL PRIMARY KEY,
    code VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    capacity INT NOT NULL,
    building VARCHAR(50),
    description VARCHAR(500),
    floor INT,
    grid_row INT,
    grid_col INT,
    grid_row_span INT,
    grid_col_span INT,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'AVAILABLE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 22. wifi_access_points
CREATE TABLE wifi_access_points (
    id BIGSERIAL PRIMARY KEY,
    ssid VARCHAR(100) NOT NULL,
    bssid VARCHAR(17) NOT NULL UNIQUE,
    name VARCHAR(100),
    location VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 23. room_wifi_access_points
CREATE TABLE room_wifi_access_points (
    id BIGSERIAL PRIMARY KEY,
    room_id BIGINT NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
    wifi_access_point_id BIGINT NOT NULL REFERENCES wifi_access_points(id) ON DELETE CASCADE,
    signal_strength INT,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    position_note VARCHAR(200),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 24. class_sections
CREATE TABLE class_sections (
    class_name VARCHAR(50) PRIMARY KEY,
    course_id BIGINT NOT NULL REFERENCES courses(id),
    semester_id BIGINT NOT NULL REFERENCES semesters(id),
    lecturer_id BIGINT REFERENCES users(id),
    number_of_slots INT NOT NULL,
    max_students INT NOT NULL,
    current_enrollment INT NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    grades_submitted BOOLEAN NOT NULL DEFAULT FALSE,
    grades_submitted_at TIMESTAMP,
    grades_submitted_by BIGINT REFERENCES users(id),
    grades_published BOOLEAN NOT NULL DEFAULT FALSE,
    grades_published_at TIMESTAMP,
    grades_published_by BIGINT REFERENCES users(id),
    resit_grades_published BOOLEAN NOT NULL DEFAULT FALSE,
    resit_grades_published_at TIMESTAMP,
    resit_grades_published_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 25. teaching_assignments
CREATE TABLE teaching_assignments (
    id BIGSERIAL PRIMARY KEY,
    lecturer_id BIGINT NOT NULL REFERENCES users(id),
    course_id BIGINT NOT NULL REFERENCES courses(id),
    semester_id BIGINT NOT NULL REFERENCES semesters(id)
);

-- 26. enrollments
CREATE TABLE enrollments (
    id BIGSERIAL PRIMARY KEY,
    class_name VARCHAR(50) NOT NULL REFERENCES class_sections(class_name) ON DELETE CASCADE,
    student_code VARCHAR(20) NOT NULL,
    student_id BIGINT NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'ENROLLED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 27. timetable_slots
CREATE TABLE timetable_slots (
    id BIGSERIAL PRIMARY KEY,
    class_name VARCHAR(50) NOT NULL REFERENCES class_sections(class_name) ON DELETE CASCADE,
    room_id BIGINT REFERENCES rooms(id),
    slot_type_id BIGINT REFERENCES slot_types(id),
    date DATE NOT NULL,
    day_of_week INT NOT NULL,
    slot_number INT NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 28. student_grades
CREATE TABLE student_grades (
    id BIGSERIAL PRIMARY KEY,
    enrollment_id BIGINT NOT NULL REFERENCES enrollments(id) ON DELETE CASCADE,
    grade_component_id BIGINT NOT NULL REFERENCES grade_components(id),
    score DOUBLE PRECISION NOT NULL,
    attempt INT NOT NULL DEFAULT 1,
    graded_at TIMESTAMP,
    graded_by_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 29. attendance_configs
CREATE TABLE attendance_configs (
    id BIGSERIAL PRIMARY KEY,
    config_key VARCHAR(50) NOT NULL UNIQUE,
    manual_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    absent_threshold_minutes INT NOT NULL DEFAULT 15,
    min_attendance_percentage DOUBLE PRECISION NOT NULL DEFAULT 80.0,
    face_recognition_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    max_attempts INT NOT NULL DEFAULT 3,
    wifi_location_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 30. attendance_sessions
CREATE TABLE attendance_sessions (
    id BIGSERIAL PRIMARY KEY,
    timetable_slot_id BIGINT NOT NULL REFERENCES timetable_slots(id) ON DELETE CASCADE,
    lecturer_id BIGINT REFERENCES users(id),
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 31. student_attendances
CREATE TABLE student_attendances (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'ABSENT',
    method VARCHAR(20),
    check_in_time TIMESTAMP,
    face_confidence DOUBLE PRECISION,
    wifi_bssid VARCHAR(17),
    wifi_rssi INT,
    note VARCHAR(500),
    updated_by_id BIGINT REFERENCES users(id),
    attempt_count INT DEFAULT 0,
    failure_reason VARCHAR(500),
    requires_manual_verify BOOLEAN DEFAULT FALSE,
    manual_verified_by BIGINT REFERENCES users(id),
    manual_verified_at TIMESTAMP,
    captured_face_url VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 32. assignments
CREATE TABLE assignments (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    class_name VARCHAR(50) NOT NULL REFERENCES class_sections(class_name) ON DELETE CASCADE,
    created_by_id BIGINT REFERENCES users(id),
    timetable_slot_id BIGINT REFERENCES timetable_slots(id),
    due_date TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    reference_url VARCHAR(500),
    reference_name VARCHAR(255),
    reminder_sent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 33. assignment_submissions
CREATE TABLE assignment_submissions (
    id BIGSERIAL PRIMARY KEY,
    assignment_id BIGINT NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES users(id),
    enrollment_id BIGINT NOT NULL REFERENCES enrollments(id),
    file_url VARCHAR(2000),
    file_name VARCHAR(1000),
    note TEXT,
    lecturer_comment TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'SUBMITTED',
    submitted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 34. chat_groups
CREATE TABLE chat_groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    class_name VARCHAR(50) REFERENCES class_sections(class_name) ON DELETE SET NULL,
    created_by_id BIGINT REFERENCES users(id),
    type VARCHAR(20) NOT NULL DEFAULT 'CLASS',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 35. chat_group_members
CREATE TABLE chat_group_members (
    id BIGSERIAL PRIMARY KEY,
    chat_group_id BIGINT NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP
);

-- 36. chat_messages
CREATE TABLE chat_messages (
    id BIGSERIAL PRIMARY KEY,
    chat_group_id BIGINT NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
    sender_id BIGINT NOT NULL REFERENCES users(id),
    content TEXT,
    type VARCHAR(20) NOT NULL DEFAULT 'TEXT',
    attachment_url VARCHAR(500),
    attachment_name VARCHAR(255),
    reply_to_id BIGINT REFERENCES chat_messages(id),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 37. chat_message_reads
CREATE TABLE chat_message_reads (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 38. chat_message_reactions
CREATE TABLE chat_message_reactions (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji VARCHAR(10) NOT NULL,
    reacted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 39. ai_chat_sessions
CREATE TABLE ai_chat_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    last_message_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 40. ai_chat_messages
CREATE TABLE ai_chat_messages (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    tokens_count INT,
    model_version VARCHAR(50),
    processing_time_ms BIGINT,
    redirect_path VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 41. notifications
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'SYSTEM',
    target_url VARCHAR(255),
    target_type VARCHAR(20),
    sent_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 42. news
CREATE TABLE news (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'GENERAL',
    priority VARCHAR(20) NOT NULL DEFAULT 'NORMAL',
    sender_id BIGINT REFERENCES users(id),
    target_url VARCHAR(255),
    target_type VARCHAR(20),
    target_class_name VARCHAR(50),
    scheduled_at TIMESTAMP,
    sent_at TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'PUBLISHED',
    thumbnail_image VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 43. news_attachments
CREATE TABLE news_attachments (
    id BIGSERIAL PRIMARY KEY,
    news_id BIGINT NOT NULL REFERENCES news(id) ON DELETE CASCADE,
    url TEXT NOT NULL
);

-- 44. academic_requests
CREATE TABLE academic_requests (
    id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES users(id),
    request_type VARCHAR(50) NOT NULL,
    request_title VARCHAR(255) NOT NULL,
    semester_id BIGINT REFERENCES semesters(id),
    course_id BIGINT REFERENCES courses(id),
    class_section_id VARCHAR(50) REFERENCES class_sections(class_name),
    to_major VARCHAR(100),
    to_specialization VARCHAR(100),
    to_sub_specialization VARCHAR(100),
    reason TEXT,
    note TEXT,
    file_url VARCHAR(500),
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    start_date DATE,
    due_date DATE,
    approver_id BIGINT REFERENCES users(id),
    approved_at TIMESTAMP,
    approver_note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 45. schedule_requests
CREATE TABLE schedule_requests (
    id BIGSERIAL PRIMARY KEY,
    requester_id BIGINT NOT NULL REFERENCES users(id),
    class_name VARCHAR(50) NOT NULL REFERENCES class_sections(class_name),
    original_slot_id BIGINT REFERENCES timetable_slots(id),
    requested_slot_id BIGINT REFERENCES timetable_slots(id),
    requested_room_id BIGINT REFERENCES rooms(id),
    type VARCHAR(30) NOT NULL,
    requested_date DATE,
    requested_slot_number INT,
    reason TEXT,
    file TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    approver_id BIGINT REFERENCES users(id),
    approved_at TIMESTAMP,
    approver_note VARCHAR(500),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 46. access_logs
CREATE TABLE access_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    location VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    access_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent VARCHAR(255)
);

-- 47. user_sessions
CREATE TABLE user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ip_address VARCHAR(45),
    province VARCHAR(100),
    city VARCHAR(100),
    latitude DECIMAL(11,8),
    longitude DECIMAL(11,8),
    login_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_activity_time TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE,
    user_agent VARCHAR(500)
);

-- 48. alerts
CREATE TABLE alerts (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'INFO',
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMP,
    resolved_by BIGINT REFERENCES users(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 49. system_logs
CREATE TABLE system_logs (
    id BIGSERIAL PRIMARY KEY,
    action VARCHAR(200) NOT NULL,
    description TEXT NOT NULL,
    type VARCHAR(20) NOT NULL DEFAULT 'AUDIT',
    source VARCHAR(100),
    ip_address VARCHAR(45),
    user_agent TEXT,
    old_value TEXT,
    new_value TEXT,
    performer_id BIGINT REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 50. import_jobs
CREATE TABLE import_jobs (
    id BIGSERIAL PRIMARY KEY,
    job_id VARCHAR(255) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    filename VARCHAR(255),
    total_records INT,
    processed_records INT,
    success_count INT,
    failed_count INT,
    status_message VARCHAR(255),
    error_message TEXT,
    created_by VARCHAR(255) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    started_at TIMESTAMP,
    completed_at TIMESTAMP
);

-- Indexes for performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_class_name ON enrollments(class_name);
CREATE INDEX idx_timetable_slots_class_name ON timetable_slots(class_name);
CREATE INDEX idx_timetable_slots_date ON timetable_slots(date);
CREATE INDEX idx_student_attendances_session_id ON student_attendances(session_id);
CREATE INDEX idx_student_attendances_student_id ON student_attendances(student_id);
CREATE INDEX idx_face_encodings_user_id ON face_encodings(user_id);
