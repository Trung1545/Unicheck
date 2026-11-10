-- ==============================================================================
-- Migration V10: Add Attendance Recheck Requests, Verification Attempts & Adjustment History
-- UniCheck Enterprise Attendance Management & Audit Trail
-- ==============================================================================

-- 1. Table: Attendance Adjustment History (Lịch sử chỉnh sửa điểm danh thủ công & tái xác thực)
CREATE TABLE IF NOT EXISTS attendance_adjustment_histories (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20) NOT NULL,
    reason VARCHAR(500) NOT NULL,
    modified_by BIGINT NOT NULL,
    modified_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    modification_type VARCHAR(50) NOT NULL,
    CONSTRAINT fk_adj_history_session FOREIGN KEY (session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_adj_history_student FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_adj_history_modifier FOREIGN KEY (modified_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_adj_history_session ON attendance_adjustment_histories(session_id);
CREATE INDEX IF NOT EXISTS idx_adj_history_student ON attendance_adjustment_histories(student_id);
CREATE INDEX IF NOT EXISTS idx_adj_history_modified_at ON attendance_adjustment_histories(modified_at DESC);

-- 2. Table: Attendance Recheck Request (Yêu cầu điểm danh lại từ giảng viên)
CREATE TABLE IF NOT EXISTS attendance_recheck_requests (
    id BIGSERIAL PRIMARY KEY,
    session_id BIGINT NOT NULL,
    student_id BIGINT NOT NULL,
    requested_by BIGINT NOT NULL,
    reason VARCHAR(500) NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    requested_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    completed_at TIMESTAMP WITHOUT TIME ZONE,
    CONSTRAINT fk_recheck_session FOREIGN KEY (session_id) REFERENCES attendance_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_recheck_student FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_recheck_requester FOREIGN KEY (requested_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_recheck_session ON attendance_recheck_requests(session_id);
CREATE INDEX IF NOT EXISTS idx_recheck_student ON attendance_recheck_requests(student_id);
CREATE INDEX IF NOT EXISTS idx_recheck_status ON attendance_recheck_requests(status);

-- 3. Table: Attendance Verification Attempt (Chi tiết các lần thử tái xác thực)
CREATE TABLE IF NOT EXISTS attendance_verification_attempts (
    id BIGSERIAL PRIMARY KEY,
    recheck_request_id BIGINT,
    student_id BIGINT NOT NULL,
    attempted_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    qr_result VARCHAR(20) NOT NULL,
    wifi_result VARCHAR(20) NOT NULL,
    face_match_result VARCHAR(20) NOT NULL,
    liveness_result VARCHAR(20) NOT NULL,
    verification_status VARCHAR(20) NOT NULL,
    failure_code VARCHAR(50),
    failure_reason VARCHAR(500),
    CONSTRAINT fk_attempt_recheck FOREIGN KEY (recheck_request_id) REFERENCES attendance_recheck_requests(id) ON DELETE CASCADE,
    CONSTRAINT fk_attempt_student FOREIGN KEY (student_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_attempt_recheck_id ON attendance_verification_attempts(recheck_request_id);
CREATE INDEX IF NOT EXISTS idx_attempt_student_id ON attendance_verification_attempts(student_id);
