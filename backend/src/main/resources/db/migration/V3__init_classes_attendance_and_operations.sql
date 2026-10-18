-- ==============================================================================
-- UniCheck - Flyway Migration V3: Classes, Attendance, Grading & Communication
-- Dependent operations tables
-- ==============================================================================

-- 1. class_sections
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

-- 2. teaching_assignments
CREATE TABLE teaching_assignments (
    id BIGSERIAL PRIMARY KEY,
    lecturer_id BIGINT NOT NULL REFERENCES users(id),
    course_id BIGINT NOT NULL REFERENCES courses(id),
    semester_id BIGINT NOT NULL REFERENCES semesters(id)
);

-- 3. enrollments
CREATE TABLE enrollments (
    id BIGSERIAL PRIMARY KEY,
    class_name VARCHAR(50) NOT NULL REFERENCES class_sections(class_name) ON DELETE CASCADE,
    student_code VARCHAR(20) NOT NULL,
    student_id BIGINT NOT NULL REFERENCES users(id),
    status VARCHAR(20) NOT NULL DEFAULT 'ENROLLED',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 4. timetable_slots
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

-- 5. grade_components
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

-- 6. student_grades
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

-- 7. attendance_sessions
CREATE TABLE attendance_sessions (
    id BIGSERIAL PRIMARY KEY,
    timetable_slot_id BIGINT NOT NULL REFERENCES timetable_slots(id) ON DELETE CASCADE,
    lecturer_id BIGINT REFERENCES users(id),
    opened_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 8. student_attendances
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

-- 9. assignments
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

-- 10. assignment_submissions
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

-- 11. chat_groups
CREATE TABLE chat_groups (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    class_name VARCHAR(50) REFERENCES class_sections(class_name) ON DELETE SET NULL,
    created_by_id BIGINT REFERENCES users(id),
    type VARCHAR(20) NOT NULL DEFAULT 'CLASS',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 12. chat_group_members
CREATE TABLE chat_group_members (
    id BIGSERIAL PRIMARY KEY,
    chat_group_id BIGINT NOT NULL REFERENCES chat_groups(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(20) NOT NULL DEFAULT 'MEMBER',
    joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    left_at TIMESTAMP
);

-- 13. chat_messages
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

-- 14. chat_message_reads
CREATE TABLE chat_message_reads (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    read_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 15. chat_message_reactions
CREATE TABLE chat_message_reactions (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    emoji VARCHAR(10) NOT NULL,
    reacted_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 16. ai_chat_sessions
CREATE TABLE ai_chat_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200),
    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    last_message_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 17. ai_chat_messages
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

-- 18. notifications
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

-- 19. news
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

-- 20. news_attachments
CREATE TABLE news_attachments (
    id BIGSERIAL PRIMARY KEY,
    news_id BIGINT NOT NULL REFERENCES news(id) ON DELETE CASCADE,
    url TEXT NOT NULL
);

-- 21. academic_requests
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

-- 22. schedule_requests
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

-- 23. alerts
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

-- 24. system_logs
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

-- 25. import_jobs
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

-- Additional operation indexes
CREATE INDEX idx_enrollments_student_id ON enrollments(student_id);
CREATE INDEX idx_enrollments_class_name ON enrollments(class_name);
CREATE INDEX idx_timetable_slots_class_name ON timetable_slots(class_name);
CREATE INDEX idx_timetable_slots_date ON timetable_slots(date);
CREATE INDEX idx_student_attendances_session_id ON student_attendances(session_id);
CREATE INDEX idx_student_attendances_student_id ON student_attendances(student_id);
