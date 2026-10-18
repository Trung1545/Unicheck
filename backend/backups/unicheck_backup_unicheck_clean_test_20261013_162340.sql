--
-- PostgreSQL database dump
--

\restrict VfglvrDvgOo7l4LzpPoUnWOxC4Q3IdioNYMOvn4KuNJkZ6s6GAhlycCHkFyNP8I

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_permissions DROP CONSTRAINT IF EXISTS user_permissions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.user_permissions DROP CONSTRAINT IF EXISTS user_permissions_granted_by_fkey;
ALTER TABLE IF EXISTS ONLY public.user_device_tokens DROP CONSTRAINT IF EXISTS user_device_tokens_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.timetable_slots DROP CONSTRAINT IF EXISTS timetable_slots_slot_type_id_fkey;
ALTER TABLE IF EXISTS ONLY public.timetable_slots DROP CONSTRAINT IF EXISTS timetable_slots_room_id_fkey;
ALTER TABLE IF EXISTS ONLY public.timetable_slots DROP CONSTRAINT IF EXISTS timetable_slots_class_name_fkey;
ALTER TABLE IF EXISTS ONLY public.teaching_assignments DROP CONSTRAINT IF EXISTS teaching_assignments_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.teaching_assignments DROP CONSTRAINT IF EXISTS teaching_assignments_lecturer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.teaching_assignments DROP CONSTRAINT IF EXISTS teaching_assignments_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.system_logs DROP CONSTRAINT IF EXISTS system_logs_performer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sub_specializations DROP CONSTRAINT IF EXISTS sub_specializations_specialization_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sub_specialization_courses DROP CONSTRAINT IF EXISTS sub_specialization_courses_sub_specialization_id_fkey;
ALTER TABLE IF EXISTS ONLY public.sub_specialization_courses DROP CONSTRAINT IF EXISTS sub_specialization_courses_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_profiles DROP CONSTRAINT IF EXISTS student_profiles_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_profiles DROP CONSTRAINT IF EXISTS student_profiles_sub_specialization_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_profiles DROP CONSTRAINT IF EXISTS student_profiles_specialization_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_profiles DROP CONSTRAINT IF EXISTS student_profiles_major_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_grades DROP CONSTRAINT IF EXISTS student_grades_graded_by_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_grades DROP CONSTRAINT IF EXISTS student_grades_grade_component_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_grades DROP CONSTRAINT IF EXISTS student_grades_enrollment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_attendances DROP CONSTRAINT IF EXISTS student_attendances_updated_by_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_attendances DROP CONSTRAINT IF EXISTS student_attendances_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_attendances DROP CONSTRAINT IF EXISTS student_attendances_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.student_attendances DROP CONSTRAINT IF EXISTS student_attendances_manual_verified_by_fkey;
ALTER TABLE IF EXISTS ONLY public.specializations DROP CONSTRAINT IF EXISTS specializations_major_id_fkey;
ALTER TABLE IF EXISTS ONLY public.specialization_courses DROP CONSTRAINT IF EXISTS specialization_courses_specialization_id_fkey;
ALTER TABLE IF EXISTS ONLY public.specialization_courses DROP CONSTRAINT IF EXISTS specialization_courses_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.slot_types DROP CONSTRAINT IF EXISTS slot_types_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.semester_weekdays DROP CONSTRAINT IF EXISTS semester_weekdays_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.semester_configs DROP CONSTRAINT IF EXISTS semester_configs_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_requester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_requested_slot_id_fkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_requested_room_id_fkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_original_slot_id_fkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_class_name_fkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_approver_id_fkey;
ALTER TABLE IF EXISTS ONLY public.room_wifi_access_points DROP CONSTRAINT IF EXISTS room_wifi_access_points_wifi_access_point_id_fkey;
ALTER TABLE IF EXISTS ONLY public.room_wifi_access_points DROP CONSTRAINT IF EXISTS room_wifi_access_points_room_id_fkey;
ALTER TABLE IF EXISTS ONLY public.news DROP CONSTRAINT IF EXISTS news_sender_id_fkey;
ALTER TABLE IF EXISTS ONLY public.news_attachments DROP CONSTRAINT IF EXISTS news_attachments_news_id_fkey;
ALTER TABLE IF EXISTS ONLY public.lecturer_profiles DROP CONSTRAINT IF EXISTS lecturer_profiles_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.lecturer_grade_otps DROP CONSTRAINT IF EXISTS lecturer_grade_otps_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.holidays DROP CONSTRAINT IF EXISTS holidays_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.grade_components DROP CONSTRAINT IF EXISTS grade_components_reference_component_id_fkey;
ALTER TABLE IF EXISTS ONLY public.grade_components DROP CONSTRAINT IF EXISTS grade_components_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.face_encodings DROP CONSTRAINT IF EXISTS face_encodings_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS enrollments_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS enrollments_class_name_fkey;
ALTER TABLE IF EXISTS ONLY public.course_prerequisites DROP CONSTRAINT IF EXISTS course_prerequisites_prerequisite_id_fkey;
ALTER TABLE IF EXISTS ONLY public.course_prerequisites DROP CONSTRAINT IF EXISTS course_prerequisites_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_resit_grades_published_by_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_lecturer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_grades_submitted_by_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_grades_published_by_fkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_reply_to_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_chat_group_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_message_reads DROP CONSTRAINT IF EXISTS chat_message_reads_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_message_reads DROP CONSTRAINT IF EXISTS chat_message_reads_message_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_message_reactions DROP CONSTRAINT IF EXISTS chat_message_reactions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_message_reactions DROP CONSTRAINT IF EXISTS chat_message_reactions_message_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_groups DROP CONSTRAINT IF EXISTS chat_groups_created_by_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_groups DROP CONSTRAINT IF EXISTS chat_groups_class_name_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_group_members DROP CONSTRAINT IF EXISTS chat_group_members_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.chat_group_members DROP CONSTRAINT IF EXISTS chat_group_members_chat_group_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attendance_sessions DROP CONSTRAINT IF EXISTS attendance_sessions_timetable_slot_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attendance_sessions DROP CONSTRAINT IF EXISTS attendance_sessions_lecturer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assignments DROP CONSTRAINT IF EXISTS assignments_timetable_slot_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assignments DROP CONSTRAINT IF EXISTS assignments_created_by_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assignments DROP CONSTRAINT IF EXISTS assignments_class_name_fkey;
ALTER TABLE IF EXISTS ONLY public.assignment_submissions DROP CONSTRAINT IF EXISTS assignment_submissions_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assignment_submissions DROP CONSTRAINT IF EXISTS assignment_submissions_enrollment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.assignment_submissions DROP CONSTRAINT IF EXISTS assignment_submissions_assignment_id_fkey;
ALTER TABLE IF EXISTS ONLY public.alerts DROP CONSTRAINT IF EXISTS alerts_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.alerts DROP CONSTRAINT IF EXISTS alerts_resolved_by_fkey;
ALTER TABLE IF EXISTS ONLY public.ai_chat_sessions DROP CONSTRAINT IF EXISTS ai_chat_sessions_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.ai_chat_messages DROP CONSTRAINT IF EXISTS ai_chat_messages_session_id_fkey;
ALTER TABLE IF EXISTS ONLY public.access_logs DROP CONSTRAINT IF EXISTS access_logs_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.academic_requests DROP CONSTRAINT IF EXISTS academic_requests_student_id_fkey;
ALTER TABLE IF EXISTS ONLY public.academic_requests DROP CONSTRAINT IF EXISTS academic_requests_semester_id_fkey;
ALTER TABLE IF EXISTS ONLY public.academic_requests DROP CONSTRAINT IF EXISTS academic_requests_course_id_fkey;
ALTER TABLE IF EXISTS ONLY public.academic_requests DROP CONSTRAINT IF EXISTS academic_requests_class_section_id_fkey;
ALTER TABLE IF EXISTS ONLY public.academic_requests DROP CONSTRAINT IF EXISTS academic_requests_approver_id_fkey;
DROP INDEX IF EXISTS public.idx_users_username;
DROP INDEX IF EXISTS public.idx_users_status;
DROP INDEX IF EXISTS public.idx_users_role;
DROP INDEX IF EXISTS public.idx_users_email;
DROP INDEX IF EXISTS public.idx_users_code;
DROP INDEX IF EXISTS public.idx_user_sessions_user_id;
DROP INDEX IF EXISTS public.idx_user_sessions_token;
DROP INDEX IF EXISTS public.idx_user_permissions_user_id;
DROP INDEX IF EXISTS public.idx_user_permissions_permission;
DROP INDEX IF EXISTS public.idx_user_device_tokens_user_id;
DROP INDEX IF EXISTS public.idx_timetable_slots_date;
DROP INDEX IF EXISTS public.idx_timetable_slots_class_name;
DROP INDEX IF EXISTS public.idx_student_profiles_user_id;
DROP INDEX IF EXISTS public.idx_student_profiles_specialization_id;
DROP INDEX IF EXISTS public.idx_student_profiles_major_id;
DROP INDEX IF EXISTS public.idx_student_attendances_student_id;
DROP INDEX IF EXISTS public.idx_student_attendances_session_id;
DROP INDEX IF EXISTS public.idx_lecturer_profiles_user_id;
DROP INDEX IF EXISTS public.idx_face_encodings_user_id;
DROP INDEX IF EXISTS public.idx_enrollments_student_id;
DROP INDEX IF EXISTS public.idx_enrollments_class_name;
DROP INDEX IF EXISTS public.idx_access_logs_user_id;
DROP INDEX IF EXISTS public.flyway_schema_history_s_idx;
ALTER TABLE IF EXISTS ONLY public.wifi_access_points DROP CONSTRAINT IF EXISTS wifi_access_points_pkey;
ALTER TABLE IF EXISTS ONLY public.wifi_access_points DROP CONSTRAINT IF EXISTS wifi_access_points_bssid_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.user_sessions DROP CONSTRAINT IF EXISTS user_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.user_permissions DROP CONSTRAINT IF EXISTS user_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.user_device_tokens DROP CONSTRAINT IF EXISTS user_device_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.timetable_slots DROP CONSTRAINT IF EXISTS timetable_slots_pkey;
ALTER TABLE IF EXISTS ONLY public.teaching_assignments DROP CONSTRAINT IF EXISTS teaching_assignments_pkey;
ALTER TABLE IF EXISTS ONLY public.system_logs DROP CONSTRAINT IF EXISTS system_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.sub_specializations DROP CONSTRAINT IF EXISTS sub_specializations_pkey;
ALTER TABLE IF EXISTS ONLY public.sub_specializations DROP CONSTRAINT IF EXISTS sub_specializations_code_key;
ALTER TABLE IF EXISTS ONLY public.sub_specialization_courses DROP CONSTRAINT IF EXISTS sub_specialization_courses_pkey;
ALTER TABLE IF EXISTS ONLY public.student_profiles DROP CONSTRAINT IF EXISTS student_profiles_pkey;
ALTER TABLE IF EXISTS ONLY public.student_grades DROP CONSTRAINT IF EXISTS student_grades_pkey;
ALTER TABLE IF EXISTS ONLY public.student_attendances DROP CONSTRAINT IF EXISTS student_attendances_pkey;
ALTER TABLE IF EXISTS ONLY public.specializations DROP CONSTRAINT IF EXISTS specializations_pkey;
ALTER TABLE IF EXISTS ONLY public.specializations DROP CONSTRAINT IF EXISTS specializations_code_key;
ALTER TABLE IF EXISTS ONLY public.specialization_courses DROP CONSTRAINT IF EXISTS specialization_courses_pkey;
ALTER TABLE IF EXISTS ONLY public.slot_types DROP CONSTRAINT IF EXISTS slot_types_pkey;
ALTER TABLE IF EXISTS ONLY public.semesters DROP CONSTRAINT IF EXISTS semesters_pkey;
ALTER TABLE IF EXISTS ONLY public.semesters DROP CONSTRAINT IF EXISTS semesters_code_key;
ALTER TABLE IF EXISTS ONLY public.semester_weekdays DROP CONSTRAINT IF EXISTS semester_weekdays_pkey;
ALTER TABLE IF EXISTS ONLY public.semester_configs DROP CONSTRAINT IF EXISTS semester_configs_pkey;
ALTER TABLE IF EXISTS ONLY public.schedule_requests DROP CONSTRAINT IF EXISTS schedule_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.rooms DROP CONSTRAINT IF EXISTS rooms_pkey;
ALTER TABLE IF EXISTS ONLY public.rooms DROP CONSTRAINT IF EXISTS rooms_code_key;
ALTER TABLE IF EXISTS ONLY public.room_wifi_access_points DROP CONSTRAINT IF EXISTS room_wifi_access_points_pkey;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.news DROP CONSTRAINT IF EXISTS news_pkey;
ALTER TABLE IF EXISTS ONLY public.news_attachments DROP CONSTRAINT IF EXISTS news_attachments_pkey;
ALTER TABLE IF EXISTS ONLY public.majors DROP CONSTRAINT IF EXISTS majors_pkey;
ALTER TABLE IF EXISTS ONLY public.majors DROP CONSTRAINT IF EXISTS majors_code_key;
ALTER TABLE IF EXISTS ONLY public.lecturer_profiles DROP CONSTRAINT IF EXISTS lecturer_profiles_pkey;
ALTER TABLE IF EXISTS ONLY public.lecturer_grade_otps DROP CONSTRAINT IF EXISTS lecturer_grade_otps_pkey;
ALTER TABLE IF EXISTS ONLY public.import_jobs DROP CONSTRAINT IF EXISTS import_jobs_pkey;
ALTER TABLE IF EXISTS ONLY public.import_jobs DROP CONSTRAINT IF EXISTS import_jobs_job_id_key;
ALTER TABLE IF EXISTS ONLY public.holidays DROP CONSTRAINT IF EXISTS holidays_pkey;
ALTER TABLE IF EXISTS ONLY public.grade_components DROP CONSTRAINT IF EXISTS grade_components_pkey;
ALTER TABLE IF EXISTS ONLY public.flyway_schema_history DROP CONSTRAINT IF EXISTS flyway_schema_history_pk;
ALTER TABLE IF EXISTS ONLY public.face_encodings DROP CONSTRAINT IF EXISTS face_encodings_pkey;
ALTER TABLE IF EXISTS ONLY public.enrollments DROP CONSTRAINT IF EXISTS enrollments_pkey;
ALTER TABLE IF EXISTS ONLY public.courses DROP CONSTRAINT IF EXISTS courses_pkey;
ALTER TABLE IF EXISTS ONLY public.courses DROP CONSTRAINT IF EXISTS courses_code_key;
ALTER TABLE IF EXISTS ONLY public.course_prerequisites DROP CONSTRAINT IF EXISTS course_prerequisites_pkey;
ALTER TABLE IF EXISTS ONLY public.class_sections DROP CONSTRAINT IF EXISTS class_sections_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_message_reads DROP CONSTRAINT IF EXISTS chat_message_reads_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_message_reactions DROP CONSTRAINT IF EXISTS chat_message_reactions_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_groups DROP CONSTRAINT IF EXISTS chat_groups_pkey;
ALTER TABLE IF EXISTS ONLY public.chat_group_members DROP CONSTRAINT IF EXISTS chat_group_members_pkey;
ALTER TABLE IF EXISTS ONLY public.attendance_sessions DROP CONSTRAINT IF EXISTS attendance_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.attendance_configs DROP CONSTRAINT IF EXISTS attendance_configs_pkey;
ALTER TABLE IF EXISTS ONLY public.attendance_configs DROP CONSTRAINT IF EXISTS attendance_configs_config_key_key;
ALTER TABLE IF EXISTS ONLY public.assignments DROP CONSTRAINT IF EXISTS assignments_pkey;
ALTER TABLE IF EXISTS ONLY public.assignment_submissions DROP CONSTRAINT IF EXISTS assignment_submissions_pkey;
ALTER TABLE IF EXISTS ONLY public.alerts DROP CONSTRAINT IF EXISTS alerts_pkey;
ALTER TABLE IF EXISTS ONLY public.ai_chat_sessions DROP CONSTRAINT IF EXISTS ai_chat_sessions_pkey;
ALTER TABLE IF EXISTS ONLY public.ai_chat_messages DROP CONSTRAINT IF EXISTS ai_chat_messages_pkey;
ALTER TABLE IF EXISTS ONLY public.access_logs DROP CONSTRAINT IF EXISTS access_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.academic_requests DROP CONSTRAINT IF EXISTS academic_requests_pkey;
ALTER TABLE IF EXISTS public.wifi_access_points ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.user_sessions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.user_permissions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.user_device_tokens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.timetable_slots ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.teaching_assignments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.system_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.sub_specializations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.sub_specialization_courses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.student_grades ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.student_attendances ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.specializations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.specialization_courses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.slot_types ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.semesters ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.semester_weekdays ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.semester_configs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.schedule_requests ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rooms ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.room_wifi_access_points ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.news_attachments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.news ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.majors ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.import_jobs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.holidays ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.grade_components ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.face_encodings ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.enrollments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.courses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_messages ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_message_reads ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_message_reactions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_groups ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.chat_group_members ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.attendance_sessions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.attendance_configs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.assignments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.assignment_submissions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.alerts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.ai_chat_sessions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.ai_chat_messages ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.access_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.academic_requests ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.wifi_access_points_id_seq;
DROP TABLE IF EXISTS public.wifi_access_points;
DROP SEQUENCE IF EXISTS public.users_id_seq;
DROP TABLE IF EXISTS public.users;
DROP SEQUENCE IF EXISTS public.user_sessions_id_seq;
DROP TABLE IF EXISTS public.user_sessions;
DROP SEQUENCE IF EXISTS public.user_permissions_id_seq;
DROP TABLE IF EXISTS public.user_permissions;
DROP SEQUENCE IF EXISTS public.user_device_tokens_id_seq;
DROP TABLE IF EXISTS public.user_device_tokens;
DROP SEQUENCE IF EXISTS public.timetable_slots_id_seq;
DROP TABLE IF EXISTS public.timetable_slots;
DROP SEQUENCE IF EXISTS public.teaching_assignments_id_seq;
DROP TABLE IF EXISTS public.teaching_assignments;
DROP SEQUENCE IF EXISTS public.system_logs_id_seq;
DROP TABLE IF EXISTS public.system_logs;
DROP SEQUENCE IF EXISTS public.sub_specializations_id_seq;
DROP TABLE IF EXISTS public.sub_specializations;
DROP SEQUENCE IF EXISTS public.sub_specialization_courses_id_seq;
DROP TABLE IF EXISTS public.sub_specialization_courses;
DROP TABLE IF EXISTS public.student_profiles;
DROP SEQUENCE IF EXISTS public.student_grades_id_seq;
DROP TABLE IF EXISTS public.student_grades;
DROP SEQUENCE IF EXISTS public.student_attendances_id_seq;
DROP TABLE IF EXISTS public.student_attendances;
DROP SEQUENCE IF EXISTS public.specializations_id_seq;
DROP TABLE IF EXISTS public.specializations;
DROP SEQUENCE IF EXISTS public.specialization_courses_id_seq;
DROP TABLE IF EXISTS public.specialization_courses;
DROP SEQUENCE IF EXISTS public.slot_types_id_seq;
DROP TABLE IF EXISTS public.slot_types;
DROP SEQUENCE IF EXISTS public.semesters_id_seq;
DROP TABLE IF EXISTS public.semesters;
DROP SEQUENCE IF EXISTS public.semester_weekdays_id_seq;
DROP TABLE IF EXISTS public.semester_weekdays;
DROP SEQUENCE IF EXISTS public.semester_configs_id_seq;
DROP TABLE IF EXISTS public.semester_configs;
DROP SEQUENCE IF EXISTS public.schedule_requests_id_seq;
DROP TABLE IF EXISTS public.schedule_requests;
DROP SEQUENCE IF EXISTS public.rooms_id_seq;
DROP TABLE IF EXISTS public.rooms;
DROP SEQUENCE IF EXISTS public.room_wifi_access_points_id_seq;
DROP TABLE IF EXISTS public.room_wifi_access_points;
DROP SEQUENCE IF EXISTS public.notifications_id_seq;
DROP TABLE IF EXISTS public.notifications;
DROP SEQUENCE IF EXISTS public.news_id_seq;
DROP SEQUENCE IF EXISTS public.news_attachments_id_seq;
DROP TABLE IF EXISTS public.news_attachments;
DROP TABLE IF EXISTS public.news;
DROP SEQUENCE IF EXISTS public.majors_id_seq;
DROP TABLE IF EXISTS public.majors;
DROP TABLE IF EXISTS public.lecturer_profiles;
DROP TABLE IF EXISTS public.lecturer_grade_otps;
DROP SEQUENCE IF EXISTS public.import_jobs_id_seq;
DROP TABLE IF EXISTS public.import_jobs;
DROP SEQUENCE IF EXISTS public.holidays_id_seq;
DROP TABLE IF EXISTS public.holidays;
DROP SEQUENCE IF EXISTS public.grade_components_id_seq;
DROP TABLE IF EXISTS public.grade_components;
DROP TABLE IF EXISTS public.flyway_schema_history;
DROP SEQUENCE IF EXISTS public.face_encodings_id_seq;
DROP TABLE IF EXISTS public.face_encodings;
DROP SEQUENCE IF EXISTS public.enrollments_id_seq;
DROP TABLE IF EXISTS public.enrollments;
DROP SEQUENCE IF EXISTS public.courses_id_seq;
DROP TABLE IF EXISTS public.courses;
DROP TABLE IF EXISTS public.course_prerequisites;
DROP TABLE IF EXISTS public.class_sections;
DROP SEQUENCE IF EXISTS public.chat_messages_id_seq;
DROP TABLE IF EXISTS public.chat_messages;
DROP SEQUENCE IF EXISTS public.chat_message_reads_id_seq;
DROP TABLE IF EXISTS public.chat_message_reads;
DROP SEQUENCE IF EXISTS public.chat_message_reactions_id_seq;
DROP TABLE IF EXISTS public.chat_message_reactions;
DROP SEQUENCE IF EXISTS public.chat_groups_id_seq;
DROP TABLE IF EXISTS public.chat_groups;
DROP SEQUENCE IF EXISTS public.chat_group_members_id_seq;
DROP TABLE IF EXISTS public.chat_group_members;
DROP SEQUENCE IF EXISTS public.attendance_sessions_id_seq;
DROP TABLE IF EXISTS public.attendance_sessions;
DROP SEQUENCE IF EXISTS public.attendance_configs_id_seq;
DROP TABLE IF EXISTS public.attendance_configs;
DROP SEQUENCE IF EXISTS public.assignments_id_seq;
DROP TABLE IF EXISTS public.assignments;
DROP SEQUENCE IF EXISTS public.assignment_submissions_id_seq;
DROP TABLE IF EXISTS public.assignment_submissions;
DROP SEQUENCE IF EXISTS public.alerts_id_seq;
DROP TABLE IF EXISTS public.alerts;
DROP SEQUENCE IF EXISTS public.ai_chat_sessions_id_seq;
DROP TABLE IF EXISTS public.ai_chat_sessions;
DROP SEQUENCE IF EXISTS public.ai_chat_messages_id_seq;
DROP TABLE IF EXISTS public.ai_chat_messages;
DROP SEQUENCE IF EXISTS public.access_logs_id_seq;
DROP TABLE IF EXISTS public.access_logs;
DROP SEQUENCE IF EXISTS public.academic_requests_id_seq;
DROP TABLE IF EXISTS public.academic_requests;
SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.academic_requests (
    id bigint NOT NULL,
    student_id bigint NOT NULL,
    request_type character varying(50) NOT NULL,
    request_title character varying(255) NOT NULL,
    semester_id bigint,
    course_id bigint,
    class_section_id character varying(50),
    to_major character varying(100),
    to_specialization character varying(100),
    to_sub_specialization character varying(100),
    reason text,
    note text,
    file_url character varying(500),
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    start_date date,
    due_date date,
    approver_id bigint,
    approved_at timestamp without time zone,
    approver_note character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: academic_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.academic_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: academic_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.academic_requests_id_seq OWNED BY public.academic_requests.id;


--
-- Name: access_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.access_logs (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    location character varying(100) NOT NULL,
    status character varying(50) NOT NULL,
    access_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ip_address character varying(45),
    user_agent character varying(255)
);


--
-- Name: access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.access_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.access_logs_id_seq OWNED BY public.access_logs.id;


--
-- Name: ai_chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chat_messages (
    id bigint NOT NULL,
    session_id bigint NOT NULL,
    role character varying(20) NOT NULL,
    content text NOT NULL,
    tokens_count integer,
    model_version character varying(50),
    processing_time_ms bigint,
    redirect_path character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ai_chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_chat_messages_id_seq OWNED BY public.ai_chat_messages.id;


--
-- Name: ai_chat_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ai_chat_sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    title character varying(200),
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    last_message_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: ai_chat_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ai_chat_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ai_chat_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ai_chat_sessions_id_seq OWNED BY public.ai_chat_sessions.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alerts (
    id bigint NOT NULL,
    user_id bigint,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    type character varying(20) DEFAULT 'INFO'::character varying NOT NULL,
    is_resolved boolean DEFAULT false NOT NULL,
    resolved_at timestamp without time zone,
    resolved_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: assignment_submissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignment_submissions (
    id bigint NOT NULL,
    assignment_id bigint NOT NULL,
    student_id bigint NOT NULL,
    enrollment_id bigint NOT NULL,
    file_url character varying(2000),
    file_name character varying(1000),
    note text,
    lecturer_comment text,
    status character varying(20) DEFAULT 'SUBMITTED'::character varying NOT NULL,
    submitted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignment_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignment_submissions_id_seq OWNED BY public.assignment_submissions.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.assignments (
    id bigint NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    class_name character varying(50) NOT NULL,
    created_by_id bigint,
    timetable_slot_id bigint,
    due_date timestamp without time zone,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    reference_url character varying(500),
    reference_name character varying(255),
    reminder_sent boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: attendance_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_configs (
    id bigint NOT NULL,
    config_key character varying(50) NOT NULL,
    manual_enabled boolean DEFAULT true NOT NULL,
    absent_threshold_minutes integer DEFAULT 15 NOT NULL,
    min_attendance_percentage double precision DEFAULT 80.0 NOT NULL,
    face_recognition_enabled boolean DEFAULT true NOT NULL,
    max_attempts integer DEFAULT 3 NOT NULL,
    wifi_location_enabled boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: attendance_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_configs_id_seq OWNED BY public.attendance_configs.id;


--
-- Name: attendance_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.attendance_sessions (
    id bigint NOT NULL,
    timetable_slot_id bigint NOT NULL,
    lecturer_id bigint,
    opened_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    closed_at timestamp without time zone,
    status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.attendance_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.attendance_sessions_id_seq OWNED BY public.attendance_sessions.id;


--
-- Name: chat_group_members; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_group_members (
    id bigint NOT NULL,
    chat_group_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying(20) DEFAULT 'MEMBER'::character varying NOT NULL,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    left_at timestamp without time zone
);


--
-- Name: chat_group_members_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_group_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_group_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_group_members_id_seq OWNED BY public.chat_group_members.id;


--
-- Name: chat_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_groups (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    class_name character varying(50),
    created_by_id bigint,
    type character varying(20) DEFAULT 'CLASS'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_groups_id_seq OWNED BY public.chat_groups.id;


--
-- Name: chat_message_reactions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_reactions (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    emoji character varying(10) NOT NULL,
    reacted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_message_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_reactions_id_seq OWNED BY public.chat_message_reactions.id;


--
-- Name: chat_message_reads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_message_reads (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    read_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_message_reads_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_message_reads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_message_reads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_message_reads_id_seq OWNED BY public.chat_message_reads.id;


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.chat_messages (
    id bigint NOT NULL,
    chat_group_id bigint NOT NULL,
    sender_id bigint NOT NULL,
    content text,
    type character varying(20) DEFAULT 'TEXT'::character varying NOT NULL,
    attachment_url character varying(500),
    attachment_name character varying(255),
    reply_to_id bigint,
    is_deleted boolean DEFAULT false NOT NULL,
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- Name: class_sections; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.class_sections (
    class_name character varying(50) NOT NULL,
    course_id bigint NOT NULL,
    semester_id bigint NOT NULL,
    lecturer_id bigint,
    number_of_slots integer NOT NULL,
    max_students integer NOT NULL,
    current_enrollment integer DEFAULT 0 NOT NULL,
    status character varying(20) DEFAULT 'OPEN'::character varying NOT NULL,
    grades_submitted boolean DEFAULT false NOT NULL,
    grades_submitted_at timestamp without time zone,
    grades_submitted_by bigint,
    grades_published boolean DEFAULT false NOT NULL,
    grades_published_at timestamp without time zone,
    grades_published_by bigint,
    resit_grades_published boolean DEFAULT false NOT NULL,
    resit_grades_published_at timestamp without time zone,
    resit_grades_published_by bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: course_prerequisites; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.course_prerequisites (
    course_id bigint NOT NULL,
    prerequisite_id bigint NOT NULL
);


--
-- Name: courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.courses (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    credits integer NOT NULL,
    number_of_slots integer NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    is_calculated_in_gpa boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.enrollments (
    id bigint NOT NULL,
    class_name character varying(50) NOT NULL,
    student_code character varying(20) NOT NULL,
    student_id bigint NOT NULL,
    status character varying(20) DEFAULT 'ENROLLED'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: face_encodings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.face_encodings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    encoding_data bytea NOT NULL,
    registered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    liveness_verified boolean DEFAULT false NOT NULL,
    face_image text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: face_encodings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.face_encodings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: face_encodings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.face_encodings_id_seq OWNED BY public.face_encodings.id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flyway_schema_history (
    installed_rank integer NOT NULL,
    version character varying(50),
    description character varying(200) NOT NULL,
    type character varying(20) NOT NULL,
    script character varying(1000) NOT NULL,
    checksum integer,
    installed_by character varying(100) NOT NULL,
    installed_on timestamp without time zone DEFAULT now() NOT NULL,
    execution_time integer NOT NULL,
    success boolean NOT NULL
);


--
-- Name: grade_components; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.grade_components (
    id bigint NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    type character varying(50) NOT NULL,
    weight double precision NOT NULL,
    is_resit boolean DEFAULT false NOT NULL,
    reference_component_id bigint,
    course_id bigint NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: grade_components_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.grade_components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: grade_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.grade_components_id_seq OWNED BY public.grade_components.id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.holidays (
    id bigint NOT NULL,
    semester_id bigint NOT NULL,
    holiday_date date NOT NULL,
    description character varying(255),
    is_recurring boolean DEFAULT false NOT NULL
);


--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;


--
-- Name: import_jobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.import_jobs (
    id bigint NOT NULL,
    job_id character varying(255) NOT NULL,
    type character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    filename character varying(255),
    total_records integer,
    processed_records integer,
    success_count integer,
    failed_count integer,
    status_message character varying(255),
    error_message text,
    created_by character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    started_at timestamp without time zone,
    completed_at timestamp without time zone
);


--
-- Name: import_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.import_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: import_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.import_jobs_id_seq OWNED BY public.import_jobs.id;


--
-- Name: lecturer_grade_otps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lecturer_grade_otps (
    user_id bigint NOT NULL,
    otp_hash character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_used_at timestamp without time zone
);


--
-- Name: lecturer_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.lecturer_profiles (
    user_id bigint NOT NULL,
    department character varying(100),
    expertise character varying(100),
    bio text
);


--
-- Name: majors; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.majors (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    program_duration character varying(50),
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: majors_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.majors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: majors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.majors_id_seq OWNED BY public.majors.id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.news (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    type character varying(20) DEFAULT 'GENERAL'::character varying NOT NULL,
    priority character varying(20) DEFAULT 'NORMAL'::character varying NOT NULL,
    sender_id bigint,
    target_url character varying(255),
    target_type character varying(20),
    target_class_name character varying(50),
    scheduled_at timestamp without time zone,
    sent_at timestamp without time zone,
    status character varying(20) DEFAULT 'PUBLISHED'::character varying NOT NULL,
    thumbnail_image character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: news_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.news_attachments (
    id bigint NOT NULL,
    news_id bigint NOT NULL,
    url text NOT NULL
);


--
-- Name: news_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.news_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.news_attachments_id_seq OWNED BY public.news_attachments.id;


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.news_id_seq OWNED BY public.news.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.notifications (
    id bigint NOT NULL,
    title character varying(200) NOT NULL,
    content text NOT NULL,
    type character varying(20) DEFAULT 'SYSTEM'::character varying NOT NULL,
    target_url character varying(255),
    target_type character varying(20),
    sent_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: room_wifi_access_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.room_wifi_access_points (
    id bigint NOT NULL,
    room_id bigint NOT NULL,
    wifi_access_point_id bigint NOT NULL,
    signal_strength integer,
    is_primary boolean DEFAULT false NOT NULL,
    position_note character varying(200),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: room_wifi_access_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.room_wifi_access_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_wifi_access_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.room_wifi_access_points_id_seq OWNED BY public.room_wifi_access_points.id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rooms (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    capacity integer NOT NULL,
    building character varying(50),
    description character varying(500),
    floor integer,
    grid_row integer,
    grid_col integer,
    grid_row_span integer,
    grid_col_span integer,
    type character varying(20) NOT NULL,
    status character varying(20) DEFAULT 'AVAILABLE'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rooms_id_seq OWNED BY public.rooms.id;


--
-- Name: schedule_requests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schedule_requests (
    id bigint NOT NULL,
    requester_id bigint NOT NULL,
    class_name character varying(50) NOT NULL,
    original_slot_id bigint,
    requested_slot_id bigint,
    requested_room_id bigint,
    type character varying(30) NOT NULL,
    requested_date date,
    requested_slot_number integer,
    reason text,
    file text,
    status character varying(20) DEFAULT 'PENDING'::character varying NOT NULL,
    approver_id bigint,
    approved_at timestamp without time zone,
    approver_note character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: schedule_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.schedule_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.schedule_requests_id_seq OWNED BY public.schedule_requests.id;


--
-- Name: semester_configs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.semester_configs (
    id bigint NOT NULL,
    semester_id bigint NOT NULL,
    max_slot_per_day integer NOT NULL,
    slot_per_subject_per_week integer NOT NULL,
    slot_duration integer NOT NULL,
    is_published boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: semester_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.semester_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: semester_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.semester_configs_id_seq OWNED BY public.semester_configs.id;


--
-- Name: semester_weekdays; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.semester_weekdays (
    id bigint NOT NULL,
    semester_id bigint NOT NULL,
    weekday integer NOT NULL
);


--
-- Name: semester_weekdays_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.semester_weekdays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: semester_weekdays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.semester_weekdays_id_seq OWNED BY public.semester_weekdays.id;


--
-- Name: semesters; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.semesters (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(100) NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: semesters_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.semesters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: semesters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.semesters_id_seq OWNED BY public.semesters.id;


--
-- Name: slot_types; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.slot_types (
    id bigint NOT NULL,
    name character varying(50) NOT NULL,
    slot_index integer NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    description character varying(255),
    semester_id bigint,
    duration character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: slot_types_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.slot_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: slot_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.slot_types_id_seq OWNED BY public.slot_types.id;


--
-- Name: specialization_courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specialization_courses (
    id bigint NOT NULL,
    specialization_id bigint NOT NULL,
    course_id bigint NOT NULL,
    order_index integer,
    semester integer,
    note character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: specialization_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.specialization_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: specialization_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.specialization_courses_id_seq OWNED BY public.specialization_courses.id;


--
-- Name: specializations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.specializations (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    major_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: specializations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.specializations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: specializations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.specializations_id_seq OWNED BY public.specializations.id;


--
-- Name: student_attendances; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_attendances (
    id bigint NOT NULL,
    session_id bigint NOT NULL,
    student_id bigint NOT NULL,
    status character varying(20) DEFAULT 'ABSENT'::character varying NOT NULL,
    method character varying(20),
    check_in_time timestamp without time zone,
    face_confidence double precision,
    wifi_bssid character varying(17),
    wifi_rssi integer,
    note character varying(500),
    updated_by_id bigint,
    attempt_count integer DEFAULT 0,
    failure_reason character varying(500),
    requires_manual_verify boolean DEFAULT false,
    manual_verified_by bigint,
    manual_verified_at timestamp without time zone,
    captured_face_url character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: student_attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.student_attendances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: student_attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.student_attendances_id_seq OWNED BY public.student_attendances.id;


--
-- Name: student_grades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_grades (
    id bigint NOT NULL,
    enrollment_id bigint NOT NULL,
    grade_component_id bigint NOT NULL,
    score double precision NOT NULL,
    attempt integer DEFAULT 1 NOT NULL,
    graded_at timestamp without time zone,
    graded_by_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: student_grades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.student_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: student_grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.student_grades_id_seq OWNED BY public.student_grades.id;


--
-- Name: student_profiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.student_profiles (
    user_id bigint NOT NULL,
    course character varying(20),
    gpa double precision DEFAULT 0.0,
    major_id bigint,
    specialization_id bigint,
    sub_specialization_id bigint
);


--
-- Name: sub_specialization_courses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sub_specialization_courses (
    id bigint NOT NULL,
    sub_specialization_id bigint NOT NULL,
    course_id bigint NOT NULL,
    order_index integer,
    semester integer,
    note character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sub_specialization_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sub_specialization_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_specialization_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sub_specialization_courses_id_seq OWNED BY public.sub_specialization_courses.id;


--
-- Name: sub_specializations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sub_specializations (
    id bigint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    specialization_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: sub_specializations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sub_specializations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sub_specializations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sub_specializations_id_seq OWNED BY public.sub_specializations.id;


--
-- Name: system_logs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.system_logs (
    id bigint NOT NULL,
    action character varying(200) NOT NULL,
    description text NOT NULL,
    type character varying(20) DEFAULT 'AUDIT'::character varying NOT NULL,
    source character varying(100),
    ip_address character varying(45),
    user_agent text,
    old_value text,
    new_value text,
    performer_id bigint,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: system_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.system_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: system_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.system_logs_id_seq OWNED BY public.system_logs.id;


--
-- Name: teaching_assignments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.teaching_assignments (
    id bigint NOT NULL,
    lecturer_id bigint NOT NULL,
    course_id bigint NOT NULL,
    semester_id bigint NOT NULL
);


--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.teaching_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.teaching_assignments_id_seq OWNED BY public.teaching_assignments.id;


--
-- Name: timetable_slots; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.timetable_slots (
    id bigint NOT NULL,
    class_name character varying(50) NOT NULL,
    room_id bigint,
    slot_type_id bigint,
    date date NOT NULL,
    day_of_week integer NOT NULL,
    slot_number integer NOT NULL,
    status character varying(20) DEFAULT 'SCHEDULED'::character varying NOT NULL,
    note character varying(500),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: timetable_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.timetable_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: timetable_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.timetable_slots_id_seq OWNED BY public.timetable_slots.id;


--
-- Name: user_device_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_device_tokens (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying(255) NOT NULL,
    platform character varying(50),
    device_id character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_device_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_device_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_device_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_device_tokens_id_seq OWNED BY public.user_device_tokens.id;


--
-- Name: user_permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_permissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    permission character varying(50) NOT NULL,
    granted_by bigint,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_permissions_id_seq OWNED BY public.user_permissions.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.user_sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying(500),
    ip_address character varying(45),
    province character varying(100),
    city character varying(100),
    latitude numeric(10,8),
    longitude numeric(11,8),
    login_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true,
    user_agent character varying(500)
);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    code character varying(50),
    username character varying(50) NOT NULL,
    password character varying(255),
    full_name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    dob date,
    phone character varying(20),
    sex character varying(10) DEFAULT 'OTHER'::character varying NOT NULL,
    role character varying(50) DEFAULT 'STUDENT'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    face_data_status character varying(20) DEFAULT 'NOT_REGISTERED'::character varying NOT NULL,
    avatar character varying(255),
    face_registration_attempts integer DEFAULT 0 NOT NULL,
    face_registration_blocked_until timestamp without time zone,
    is_password_changed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: wifi_access_points; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.wifi_access_points (
    id bigint NOT NULL,
    ssid character varying(100) NOT NULL,
    bssid character varying(17) NOT NULL,
    name character varying(100),
    location character varying(200),
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


--
-- Name: wifi_access_points_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.wifi_access_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: wifi_access_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.wifi_access_points_id_seq OWNED BY public.wifi_access_points.id;


--
-- Name: academic_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests ALTER COLUMN id SET DEFAULT nextval('public.academic_requests_id_seq'::regclass);


--
-- Name: access_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs ALTER COLUMN id SET DEFAULT nextval('public.access_logs_id_seq'::regclass);


--
-- Name: ai_chat_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_messages ALTER COLUMN id SET DEFAULT nextval('public.ai_chat_messages_id_seq'::regclass);


--
-- Name: ai_chat_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_sessions ALTER COLUMN id SET DEFAULT nextval('public.ai_chat_sessions_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: assignment_submissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_submissions ALTER COLUMN id SET DEFAULT nextval('public.assignment_submissions_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: attendance_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_configs ALTER COLUMN id SET DEFAULT nextval('public.attendance_configs_id_seq'::regclass);


--
-- Name: attendance_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sessions ALTER COLUMN id SET DEFAULT nextval('public.attendance_sessions_id_seq'::regclass);


--
-- Name: chat_group_members id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_group_members ALTER COLUMN id SET DEFAULT nextval('public.chat_group_members_id_seq'::regclass);


--
-- Name: chat_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_groups ALTER COLUMN id SET DEFAULT nextval('public.chat_groups_id_seq'::regclass);


--
-- Name: chat_message_reactions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reactions ALTER COLUMN id SET DEFAULT nextval('public.chat_message_reactions_id_seq'::regclass);


--
-- Name: chat_message_reads id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reads ALTER COLUMN id SET DEFAULT nextval('public.chat_message_reads_id_seq'::regclass);


--
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: face_encodings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.face_encodings ALTER COLUMN id SET DEFAULT nextval('public.face_encodings_id_seq'::regclass);


--
-- Name: grade_components id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_components ALTER COLUMN id SET DEFAULT nextval('public.grade_components_id_seq'::regclass);


--
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);


--
-- Name: import_jobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_jobs ALTER COLUMN id SET DEFAULT nextval('public.import_jobs_id_seq'::regclass);


--
-- Name: majors id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.majors ALTER COLUMN id SET DEFAULT nextval('public.majors_id_seq'::regclass);


--
-- Name: news id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news ALTER COLUMN id SET DEFAULT nextval('public.news_id_seq'::regclass);


--
-- Name: news_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_attachments ALTER COLUMN id SET DEFAULT nextval('public.news_attachments_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: room_wifi_access_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_wifi_access_points ALTER COLUMN id SET DEFAULT nextval('public.room_wifi_access_points_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms ALTER COLUMN id SET DEFAULT nextval('public.rooms_id_seq'::regclass);


--
-- Name: schedule_requests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests ALTER COLUMN id SET DEFAULT nextval('public.schedule_requests_id_seq'::regclass);


--
-- Name: semester_configs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semester_configs ALTER COLUMN id SET DEFAULT nextval('public.semester_configs_id_seq'::regclass);


--
-- Name: semester_weekdays id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semester_weekdays ALTER COLUMN id SET DEFAULT nextval('public.semester_weekdays_id_seq'::regclass);


--
-- Name: semesters id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters ALTER COLUMN id SET DEFAULT nextval('public.semesters_id_seq'::regclass);


--
-- Name: slot_types id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_types ALTER COLUMN id SET DEFAULT nextval('public.slot_types_id_seq'::regclass);


--
-- Name: specialization_courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialization_courses ALTER COLUMN id SET DEFAULT nextval('public.specialization_courses_id_seq'::regclass);


--
-- Name: specializations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specializations ALTER COLUMN id SET DEFAULT nextval('public.specializations_id_seq'::regclass);


--
-- Name: student_attendances id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances ALTER COLUMN id SET DEFAULT nextval('public.student_attendances_id_seq'::regclass);


--
-- Name: student_grades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_grades ALTER COLUMN id SET DEFAULT nextval('public.student_grades_id_seq'::regclass);


--
-- Name: sub_specialization_courses id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specialization_courses ALTER COLUMN id SET DEFAULT nextval('public.sub_specialization_courses_id_seq'::regclass);


--
-- Name: sub_specializations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specializations ALTER COLUMN id SET DEFAULT nextval('public.sub_specializations_id_seq'::regclass);


--
-- Name: system_logs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_logs ALTER COLUMN id SET DEFAULT nextval('public.system_logs_id_seq'::regclass);


--
-- Name: teaching_assignments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teaching_assignments ALTER COLUMN id SET DEFAULT nextval('public.teaching_assignments_id_seq'::regclass);


--
-- Name: timetable_slots id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timetable_slots ALTER COLUMN id SET DEFAULT nextval('public.timetable_slots_id_seq'::regclass);


--
-- Name: user_device_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_device_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_device_tokens_id_seq'::regclass);


--
-- Name: user_permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_permissions ALTER COLUMN id SET DEFAULT nextval('public.user_permissions_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wifi_access_points id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wifi_access_points ALTER COLUMN id SET DEFAULT nextval('public.wifi_access_points_id_seq'::regclass);


--
-- Data for Name: academic_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.academic_requests (id, student_id, request_type, request_title, semester_id, course_id, class_section_id, to_major, to_specialization, to_sub_specialization, reason, note, file_url, status, start_date, due_date, approver_id, approved_at, approver_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: access_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.access_logs (id, user_id, location, status, access_time, ip_address, user_agent) FROM stdin;
\.


--
-- Data for Name: ai_chat_messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_chat_messages (id, session_id, role, content, tokens_count, model_version, processing_time_ms, redirect_path, created_at) FROM stdin;
\.


--
-- Data for Name: ai_chat_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.ai_chat_sessions (id, user_id, title, status, last_message_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.alerts (id, user_id, title, content, type, is_resolved, resolved_at, resolved_by, created_at) FROM stdin;
\.


--
-- Data for Name: assignment_submissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.assignment_submissions (id, assignment_id, student_id, enrollment_id, file_url, file_name, note, lecturer_comment, status, submitted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: assignments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.assignments (id, title, description, class_name, created_by_id, timetable_slot_id, due_date, status, reference_url, reference_name, reminder_sent, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attendance_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attendance_configs (id, config_key, manual_enabled, absent_threshold_minutes, min_attendance_percentage, face_recognition_enabled, max_attempts, wifi_location_enabled, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attendance_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.attendance_sessions (id, timetable_slot_id, lecturer_id, opened_at, closed_at, status, created_at) FROM stdin;
\.


--
-- Data for Name: chat_group_members; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_group_members (id, chat_group_id, user_id, role, joined_at, left_at) FROM stdin;
\.


--
-- Data for Name: chat_groups; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_groups (id, name, class_name, created_by_id, type, created_at) FROM stdin;
\.


--
-- Data for Name: chat_message_reactions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_message_reactions (id, message_id, user_id, emoji, reacted_at) FROM stdin;
\.


--
-- Data for Name: chat_message_reads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_message_reads (id, message_id, user_id, read_at) FROM stdin;
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.chat_messages (id, chat_group_id, sender_id, content, type, attachment_url, attachment_name, reply_to_id, is_deleted, sent_at) FROM stdin;
\.


--
-- Data for Name: class_sections; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.class_sections (class_name, course_id, semester_id, lecturer_id, number_of_slots, max_students, current_enrollment, status, grades_submitted, grades_submitted_at, grades_submitted_by, grades_published, grades_published_at, grades_published_by, resit_grades_published, resit_grades_published_at, resit_grades_published_by, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: course_prerequisites; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.course_prerequisites (course_id, prerequisite_id) FROM stdin;
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.courses (id, code, name, description, credits, number_of_slots, status, is_calculated_in_gpa, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.enrollments (id, class_name, student_code, student_id, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: face_encodings; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.face_encodings (id, user_id, encoding_data, registered_at, liveness_verified, face_image, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	1	init academic catalog	SQL	V1__init_academic_catalog.sql	521673728	unicheck_user	2026-10-12 14:43:29.557978	79	t
2	2	init users and profiles	SQL	V2__init_users_and_profiles.sql	216176508	unicheck_user	2026-10-12 14:43:29.685201	45	t
3	3	init classes attendance and operations	SQL	V3__init_classes_attendance_and_operations.sql	261591654	unicheck_user	2026-10-12 14:43:29.749927	106	t
\.


--
-- Data for Name: grade_components; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.grade_components (id, name, description, type, weight, is_resit, reference_component_id, course_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.holidays (id, semester_id, holiday_date, description, is_recurring) FROM stdin;
\.


--
-- Data for Name: import_jobs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.import_jobs (id, job_id, type, status, filename, total_records, processed_records, success_count, failed_count, status_message, error_message, created_by, created_at, started_at, completed_at) FROM stdin;
\.


--
-- Data for Name: lecturer_grade_otps; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturer_grade_otps (user_id, otp_hash, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: lecturer_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.lecturer_profiles (user_id, department, expertise, bio) FROM stdin;
\.


--
-- Data for Name: majors; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.majors (id, code, name, description, program_duration, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: news; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.news (id, title, content, type, priority, sender_id, target_url, target_type, target_class_name, scheduled_at, sent_at, status, thumbnail_image, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: news_attachments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.news_attachments (id, news_id, url) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.notifications (id, title, content, type, target_url, target_type, sent_at, created_at) FROM stdin;
\.


--
-- Data for Name: room_wifi_access_points; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.room_wifi_access_points (id, room_id, wifi_access_point_id, signal_strength, is_primary, position_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rooms (id, code, name, capacity, building, description, floor, grid_row, grid_col, grid_row_span, grid_col_span, type, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: schedule_requests; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.schedule_requests (id, requester_id, class_name, original_slot_id, requested_slot_id, requested_room_id, type, requested_date, requested_slot_number, reason, file, status, approver_id, approved_at, approver_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: semester_configs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.semester_configs (id, semester_id, max_slot_per_day, slot_per_subject_per_week, slot_duration, is_published, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: semester_weekdays; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.semester_weekdays (id, semester_id, weekday) FROM stdin;
\.


--
-- Data for Name: semesters; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.semesters (id, code, name, start_date, end_date, status, description, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: slot_types; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.slot_types (id, name, slot_index, start_time, end_time, description, semester_id, duration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: specialization_courses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.specialization_courses (id, specialization_id, course_id, order_index, semester, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: specializations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.specializations (id, code, name, description, status, major_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_attendances; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.student_attendances (id, session_id, student_id, status, method, check_in_time, face_confidence, wifi_bssid, wifi_rssi, note, updated_by_id, attempt_count, failure_reason, requires_manual_verify, manual_verified_by, manual_verified_at, captured_face_url, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_grades; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.student_grades (id, enrollment_id, grade_component_id, score, attempt, graded_at, graded_by_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_profiles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.student_profiles (user_id, course, gpa, major_id, specialization_id, sub_specialization_id) FROM stdin;
\.


--
-- Data for Name: sub_specialization_courses; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sub_specialization_courses (id, sub_specialization_id, course_id, order_index, semester, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sub_specializations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sub_specializations (id, code, name, description, status, specialization_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.system_logs (id, action, description, type, source, ip_address, user_agent, old_value, new_value, performer_id, created_at) FROM stdin;
\.


--
-- Data for Name: teaching_assignments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.teaching_assignments (id, lecturer_id, course_id, semester_id) FROM stdin;
\.


--
-- Data for Name: timetable_slots; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.timetable_slots (id, class_name, room_id, slot_type_id, date, day_of_week, slot_number, status, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_device_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_device_tokens (id, user_id, token, platform, device_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_permissions (id, user_id, permission, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.user_sessions (id, user_id, token, ip_address, province, city, latitude, longitude, login_time, last_activity_time, is_active, user_agent) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.users (id, code, username, password, full_name, email, dob, phone, sex, role, status, face_data_status, avatar, face_registration_attempts, face_registration_blocked_until, is_password_changed, created_at, updated_at) FROM stdin;
1	SV2026999	sv_clean_pg	$2a$10$hashedCleanPgPass	Lê Văn Postgres	sv2026999@unicheck.edu.vn	2003-10-10	0987654321	MALE	STUDENT	ACTIVE	NOT_REGISTERED	\N	0	\N	f	2026-10-12 14:43:34.444377	2026-10-12 14:43:34.444377
\.


--
-- Data for Name: wifi_access_points; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.wifi_access_points (id, ssid, bssid, name, location, status, created_at, updated_at) FROM stdin;
\.


--
-- Name: academic_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.academic_requests_id_seq', 1, false);


--
-- Name: access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.access_logs_id_seq', 8, true);


--
-- Name: ai_chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ai_chat_messages_id_seq', 1, false);


--
-- Name: ai_chat_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ai_chat_sessions_id_seq', 1, false);


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.alerts_id_seq', 1, false);


--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.assignment_submissions_id_seq', 1, false);


--
-- Name: assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.assignments_id_seq', 1, false);


--
-- Name: attendance_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendance_configs_id_seq', 1, false);


--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.attendance_sessions_id_seq', 1, false);


--
-- Name: chat_group_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_group_members_id_seq', 1, false);


--
-- Name: chat_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_groups_id_seq', 1, false);


--
-- Name: chat_message_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_message_reactions_id_seq', 1, false);


--
-- Name: chat_message_reads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_message_reads_id_seq', 1, false);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.chat_messages_id_seq', 1, false);


--
-- Name: courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.courses_id_seq', 1, false);


--
-- Name: enrollments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.enrollments_id_seq', 1, false);


--
-- Name: face_encodings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.face_encodings_id_seq', 1, false);


--
-- Name: grade_components_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.grade_components_id_seq', 1, false);


--
-- Name: holidays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.holidays_id_seq', 1, false);


--
-- Name: import_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.import_jobs_id_seq', 1, false);


--
-- Name: majors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.majors_id_seq', 1, false);


--
-- Name: news_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.news_attachments_id_seq', 1, false);


--
-- Name: news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.news_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: room_wifi_access_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.room_wifi_access_points_id_seq', 1, false);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rooms_id_seq', 1, false);


--
-- Name: schedule_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.schedule_requests_id_seq', 1, false);


--
-- Name: semester_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.semester_configs_id_seq', 1, false);


--
-- Name: semester_weekdays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.semester_weekdays_id_seq', 1, false);


--
-- Name: semesters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.semesters_id_seq', 1, false);


--
-- Name: slot_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.slot_types_id_seq', 1, false);


--
-- Name: specialization_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.specialization_courses_id_seq', 1, false);


--
-- Name: specializations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.specializations_id_seq', 1, false);


--
-- Name: student_attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.student_attendances_id_seq', 1, false);


--
-- Name: student_grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.student_grades_id_seq', 1, false);


--
-- Name: sub_specialization_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sub_specialization_courses_id_seq', 1, false);


--
-- Name: sub_specializations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.sub_specializations_id_seq', 1, false);


--
-- Name: system_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.system_logs_id_seq', 1, false);


--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.teaching_assignments_id_seq', 1, false);


--
-- Name: timetable_slots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.timetable_slots_id_seq', 1, false);


--
-- Name: user_device_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_device_tokens_id_seq', 1, false);


--
-- Name: user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_permissions_id_seq', 8, true);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 1, false);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 18, true);


--
-- Name: wifi_access_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.wifi_access_points_id_seq', 1, false);


--
-- Name: academic_requests academic_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_pkey PRIMARY KEY (id);


--
-- Name: access_logs access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_messages ai_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_messages
    ADD CONSTRAINT ai_chat_messages_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_sessions ai_chat_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_sessions
    ADD CONSTRAINT ai_chat_sessions_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: assignment_submissions assignment_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: attendance_configs attendance_configs_config_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_configs
    ADD CONSTRAINT attendance_configs_config_key_key UNIQUE (config_key);


--
-- Name: attendance_configs attendance_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_configs
    ADD CONSTRAINT attendance_configs_pkey PRIMARY KEY (id);


--
-- Name: attendance_sessions attendance_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id);


--
-- Name: chat_group_members chat_group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_group_members
    ADD CONSTRAINT chat_group_members_pkey PRIMARY KEY (id);


--
-- Name: chat_groups chat_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_groups
    ADD CONSTRAINT chat_groups_pkey PRIMARY KEY (id);


--
-- Name: chat_message_reactions chat_message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reactions
    ADD CONSTRAINT chat_message_reactions_pkey PRIMARY KEY (id);


--
-- Name: chat_message_reads chat_message_reads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reads
    ADD CONSTRAINT chat_message_reads_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: class_sections class_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_pkey PRIMARY KEY (class_name);


--
-- Name: course_prerequisites course_prerequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_pkey PRIMARY KEY (course_id, prerequisite_id);


--
-- Name: courses courses_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_code_key UNIQUE (code);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: face_encodings face_encodings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.face_encodings
    ADD CONSTRAINT face_encodings_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: grade_components grade_components_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_components
    ADD CONSTRAINT grade_components_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: import_jobs import_jobs_job_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_jobs
    ADD CONSTRAINT import_jobs_job_id_key UNIQUE (job_id);


--
-- Name: import_jobs import_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.import_jobs
    ADD CONSTRAINT import_jobs_pkey PRIMARY KEY (id);


--
-- Name: lecturer_grade_otps lecturer_grade_otps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturer_grade_otps
    ADD CONSTRAINT lecturer_grade_otps_pkey PRIMARY KEY (user_id);


--
-- Name: lecturer_profiles lecturer_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturer_profiles
    ADD CONSTRAINT lecturer_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: majors majors_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.majors
    ADD CONSTRAINT majors_code_key UNIQUE (code);


--
-- Name: majors majors_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.majors
    ADD CONSTRAINT majors_pkey PRIMARY KEY (id);


--
-- Name: news_attachments news_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_attachments
    ADD CONSTRAINT news_attachments_pkey PRIMARY KEY (id);


--
-- Name: news news_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: room_wifi_access_points room_wifi_access_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_wifi_access_points
    ADD CONSTRAINT room_wifi_access_points_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_code_key UNIQUE (code);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schedule_requests schedule_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_pkey PRIMARY KEY (id);


--
-- Name: semester_configs semester_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semester_configs
    ADD CONSTRAINT semester_configs_pkey PRIMARY KEY (id);


--
-- Name: semester_weekdays semester_weekdays_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semester_weekdays
    ADD CONSTRAINT semester_weekdays_pkey PRIMARY KEY (id);


--
-- Name: semesters semesters_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_code_key UNIQUE (code);


--
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- Name: slot_types slot_types_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_types
    ADD CONSTRAINT slot_types_pkey PRIMARY KEY (id);


--
-- Name: specialization_courses specialization_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialization_courses
    ADD CONSTRAINT specialization_courses_pkey PRIMARY KEY (id);


--
-- Name: specializations specializations_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_code_key UNIQUE (code);


--
-- Name: specializations specializations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_pkey PRIMARY KEY (id);


--
-- Name: student_attendances student_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_pkey PRIMARY KEY (id);


--
-- Name: student_grades student_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_pkey PRIMARY KEY (id);


--
-- Name: student_profiles student_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: sub_specialization_courses sub_specialization_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specialization_courses
    ADD CONSTRAINT sub_specialization_courses_pkey PRIMARY KEY (id);


--
-- Name: sub_specializations sub_specializations_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specializations
    ADD CONSTRAINT sub_specializations_code_key UNIQUE (code);


--
-- Name: sub_specializations sub_specializations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specializations
    ADD CONSTRAINT sub_specializations_pkey PRIMARY KEY (id);


--
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);


--
-- Name: teaching_assignments teaching_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_pkey PRIMARY KEY (id);


--
-- Name: timetable_slots timetable_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_pkey PRIMARY KEY (id);


--
-- Name: user_device_tokens user_device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_device_tokens
    ADD CONSTRAINT user_device_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_permissions user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: wifi_access_points wifi_access_points_bssid_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wifi_access_points
    ADD CONSTRAINT wifi_access_points_bssid_key UNIQUE (bssid);


--
-- Name: wifi_access_points wifi_access_points_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.wifi_access_points
    ADD CONSTRAINT wifi_access_points_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_access_logs_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_access_logs_user_id ON public.access_logs USING btree (user_id);


--
-- Name: idx_enrollments_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enrollments_class_name ON public.enrollments USING btree (class_name);


--
-- Name: idx_enrollments_student_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_enrollments_student_id ON public.enrollments USING btree (student_id);


--
-- Name: idx_face_encodings_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_face_encodings_user_id ON public.face_encodings USING btree (user_id);


--
-- Name: idx_lecturer_profiles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_lecturer_profiles_user_id ON public.lecturer_profiles USING btree (user_id);


--
-- Name: idx_student_attendances_session_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_attendances_session_id ON public.student_attendances USING btree (session_id);


--
-- Name: idx_student_attendances_student_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_attendances_student_id ON public.student_attendances USING btree (student_id);


--
-- Name: idx_student_profiles_major_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_profiles_major_id ON public.student_profiles USING btree (major_id);


--
-- Name: idx_student_profiles_specialization_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_profiles_specialization_id ON public.student_profiles USING btree (specialization_id);


--
-- Name: idx_student_profiles_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_student_profiles_user_id ON public.student_profiles USING btree (user_id);


--
-- Name: idx_timetable_slots_class_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timetable_slots_class_name ON public.timetable_slots USING btree (class_name);


--
-- Name: idx_timetable_slots_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_timetable_slots_date ON public.timetable_slots USING btree (date);


--
-- Name: idx_user_device_tokens_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_device_tokens_user_id ON public.user_device_tokens USING btree (user_id);


--
-- Name: idx_user_permissions_permission; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_permissions_permission ON public.user_permissions USING btree (permission);


--
-- Name: idx_user_permissions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_permissions_user_id ON public.user_permissions USING btree (user_id);


--
-- Name: idx_user_sessions_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (token);


--
-- Name: idx_user_sessions_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: idx_users_code; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_code ON public.users USING btree (code);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: academic_requests academic_requests_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: academic_requests academic_requests_class_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_class_section_id_fkey FOREIGN KEY (class_section_id) REFERENCES public.class_sections(class_name);


--
-- Name: academic_requests academic_requests_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: academic_requests academic_requests_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id);


--
-- Name: academic_requests academic_requests_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: access_logs access_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ai_chat_messages ai_chat_messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_messages
    ADD CONSTRAINT ai_chat_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.ai_chat_sessions(id) ON DELETE CASCADE;


--
-- Name: ai_chat_sessions ai_chat_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ai_chat_sessions
    ADD CONSTRAINT ai_chat_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: alerts alerts_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: alerts alerts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: assignment_submissions assignment_submissions_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;


--
-- Name: assignment_submissions assignment_submissions_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id);


--
-- Name: assignment_submissions assignment_submissions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: assignments assignments_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE CASCADE;


--
-- Name: assignments assignments_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: assignments assignments_timetable_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_timetable_slot_id_fkey FOREIGN KEY (timetable_slot_id) REFERENCES public.timetable_slots(id);


--
-- Name: attendance_sessions attendance_sessions_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id);


--
-- Name: attendance_sessions attendance_sessions_timetable_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_timetable_slot_id_fkey FOREIGN KEY (timetable_slot_id) REFERENCES public.timetable_slots(id) ON DELETE CASCADE;


--
-- Name: chat_group_members chat_group_members_chat_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_group_members
    ADD CONSTRAINT chat_group_members_chat_group_id_fkey FOREIGN KEY (chat_group_id) REFERENCES public.chat_groups(id) ON DELETE CASCADE;


--
-- Name: chat_group_members chat_group_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_group_members
    ADD CONSTRAINT chat_group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_groups chat_groups_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_groups
    ADD CONSTRAINT chat_groups_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE SET NULL;


--
-- Name: chat_groups chat_groups_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_groups
    ADD CONSTRAINT chat_groups_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: chat_message_reactions chat_message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reactions
    ADD CONSTRAINT chat_message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat_messages(id) ON DELETE CASCADE;


--
-- Name: chat_message_reactions chat_message_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reactions
    ADD CONSTRAINT chat_message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_message_reads chat_message_reads_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reads
    ADD CONSTRAINT chat_message_reads_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat_messages(id) ON DELETE CASCADE;


--
-- Name: chat_message_reads chat_message_reads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_message_reads
    ADD CONSTRAINT chat_message_reads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_chat_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_chat_group_id_fkey FOREIGN KEY (chat_group_id) REFERENCES public.chat_groups(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_reply_to_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.chat_messages(id);


--
-- Name: chat_messages chat_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: class_sections class_sections_grades_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_grades_published_by_fkey FOREIGN KEY (grades_published_by) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_grades_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_grades_submitted_by_fkey FOREIGN KEY (grades_submitted_by) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_resit_grades_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_resit_grades_published_by_fkey FOREIGN KEY (resit_grades_published_by) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id);


--
-- Name: course_prerequisites course_prerequisites_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_prerequisites course_prerequisites_prerequisite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_prerequisite_id_fkey FOREIGN KEY (prerequisite_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: enrollments enrollments_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE CASCADE;


--
-- Name: enrollments enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: face_encodings face_encodings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.face_encodings
    ADD CONSTRAINT face_encodings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: grade_components grade_components_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_components
    ADD CONSTRAINT grade_components_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: grade_components grade_components_reference_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.grade_components
    ADD CONSTRAINT grade_components_reference_component_id_fkey FOREIGN KEY (reference_component_id) REFERENCES public.grade_components(id);


--
-- Name: holidays holidays_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: lecturer_grade_otps lecturer_grade_otps_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturer_grade_otps
    ADD CONSTRAINT lecturer_grade_otps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: lecturer_profiles lecturer_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.lecturer_profiles
    ADD CONSTRAINT lecturer_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: news_attachments news_attachments_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news_attachments
    ADD CONSTRAINT news_attachments_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(id) ON DELETE CASCADE;


--
-- Name: news news_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: room_wifi_access_points room_wifi_access_points_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_wifi_access_points
    ADD CONSTRAINT room_wifi_access_points_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;


--
-- Name: room_wifi_access_points room_wifi_access_points_wifi_access_point_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.room_wifi_access_points
    ADD CONSTRAINT room_wifi_access_points_wifi_access_point_id_fkey FOREIGN KEY (wifi_access_point_id) REFERENCES public.wifi_access_points(id) ON DELETE CASCADE;


--
-- Name: schedule_requests schedule_requests_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: schedule_requests schedule_requests_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name);


--
-- Name: schedule_requests schedule_requests_original_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_original_slot_id_fkey FOREIGN KEY (original_slot_id) REFERENCES public.timetable_slots(id);


--
-- Name: schedule_requests schedule_requests_requested_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_requested_room_id_fkey FOREIGN KEY (requested_room_id) REFERENCES public.rooms(id);


--
-- Name: schedule_requests schedule_requests_requested_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_requested_slot_id_fkey FOREIGN KEY (requested_slot_id) REFERENCES public.timetable_slots(id);


--
-- Name: schedule_requests schedule_requests_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.users(id);


--
-- Name: semester_configs semester_configs_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semester_configs
    ADD CONSTRAINT semester_configs_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: semester_weekdays semester_weekdays_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.semester_weekdays
    ADD CONSTRAINT semester_weekdays_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: slot_types slot_types_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.slot_types
    ADD CONSTRAINT slot_types_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: specialization_courses specialization_courses_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialization_courses
    ADD CONSTRAINT specialization_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: specialization_courses specialization_courses_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specialization_courses
    ADD CONSTRAINT specialization_courses_specialization_id_fkey FOREIGN KEY (specialization_id) REFERENCES public.specializations(id) ON DELETE CASCADE;


--
-- Name: specializations specializations_major_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_major_id_fkey FOREIGN KEY (major_id) REFERENCES public.majors(id) ON DELETE CASCADE;


--
-- Name: student_attendances student_attendances_manual_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_manual_verified_by_fkey FOREIGN KEY (manual_verified_by) REFERENCES public.users(id);


--
-- Name: student_attendances student_attendances_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id) ON DELETE CASCADE;


--
-- Name: student_attendances student_attendances_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: student_attendances student_attendances_updated_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_updated_by_id_fkey FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: student_grades student_grades_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id) ON DELETE CASCADE;


--
-- Name: student_grades student_grades_grade_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_grade_component_id_fkey FOREIGN KEY (grade_component_id) REFERENCES public.grade_components(id);


--
-- Name: student_grades student_grades_graded_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_graded_by_id_fkey FOREIGN KEY (graded_by_id) REFERENCES public.users(id);


--
-- Name: student_profiles student_profiles_major_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_major_id_fkey FOREIGN KEY (major_id) REFERENCES public.majors(id) ON DELETE SET NULL;


--
-- Name: student_profiles student_profiles_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_specialization_id_fkey FOREIGN KEY (specialization_id) REFERENCES public.specializations(id) ON DELETE SET NULL;


--
-- Name: student_profiles student_profiles_sub_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_sub_specialization_id_fkey FOREIGN KEY (sub_specialization_id) REFERENCES public.sub_specializations(id) ON DELETE SET NULL;


--
-- Name: student_profiles student_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sub_specialization_courses sub_specialization_courses_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specialization_courses
    ADD CONSTRAINT sub_specialization_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: sub_specialization_courses sub_specialization_courses_sub_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specialization_courses
    ADD CONSTRAINT sub_specialization_courses_sub_specialization_id_fkey FOREIGN KEY (sub_specialization_id) REFERENCES public.sub_specializations(id) ON DELETE CASCADE;


--
-- Name: sub_specializations sub_specializations_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sub_specializations
    ADD CONSTRAINT sub_specializations_specialization_id_fkey FOREIGN KEY (specialization_id) REFERENCES public.specializations(id) ON DELETE CASCADE;


--
-- Name: system_logs system_logs_performer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_performer_id_fkey FOREIGN KEY (performer_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: teaching_assignments teaching_assignments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: teaching_assignments teaching_assignments_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id);


--
-- Name: teaching_assignments teaching_assignments_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id);


--
-- Name: timetable_slots timetable_slots_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE CASCADE;


--
-- Name: timetable_slots timetable_slots_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: timetable_slots timetable_slots_slot_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_slot_type_id_fkey FOREIGN KEY (slot_type_id) REFERENCES public.slot_types(id);


--
-- Name: user_device_tokens user_device_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_device_tokens
    ADD CONSTRAINT user_device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_permissions user_permissions_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_permissions user_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict VfglvrDvgOo7l4LzpPoUnWOxC4Q3IdioNYMOvn4KuNJkZ6s6GAhlycCHkFyNP8I

