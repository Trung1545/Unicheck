-- ==============================================================================
-- UniCheck - Flyway Migration V4: Additional Indexes & Constraints for TASK-02B
-- ==============================================================================

-- Unique index to prevent duplicate enrollments of a student in the same class section
CREATE UNIQUE INDEX IF NOT EXISTS idx_enrollments_class_student_unique 
    ON enrollments(class_name, student_id);

-- Performance index for class_sections queries by semester, course, and lecturer
CREATE INDEX IF NOT EXISTS idx_class_sections_semester_id 
    ON class_sections(semester_id);

CREATE INDEX IF NOT EXISTS idx_class_sections_course_id 
    ON class_sections(course_id);

CREATE INDEX IF NOT EXISTS idx_class_sections_lecturer_id 
    ON class_sections(lecturer_id);

-- Performance index for teaching_assignments
CREATE INDEX IF NOT EXISTS idx_teaching_assignments_composite 
    ON teaching_assignments(lecturer_id, course_id, semester_id);
