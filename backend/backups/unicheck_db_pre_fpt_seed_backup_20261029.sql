--
-- PostgreSQL database dump
--

\restrict bith0XsQcvAmveJahMSc37LNDNB0sVg5e1IEs9CefAvF4GDhmCUdb7QaTSWtSYB

-- Dumped from database version 15.19
-- Dumped by pg_dump version 15.19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: academic_requests; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.academic_requests OWNER TO unicheck_user;

--
-- Name: academic_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.academic_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.academic_requests_id_seq OWNER TO unicheck_user;

--
-- Name: academic_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.academic_requests_id_seq OWNED BY public.academic_requests.id;


--
-- Name: access_logs; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.access_logs OWNER TO unicheck_user;

--
-- Name: access_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.access_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.access_logs_id_seq OWNER TO unicheck_user;

--
-- Name: access_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.access_logs_id_seq OWNED BY public.access_logs.id;


--
-- Name: ai_chat_messages; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.ai_chat_messages OWNER TO unicheck_user;

--
-- Name: ai_chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.ai_chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ai_chat_messages_id_seq OWNER TO unicheck_user;

--
-- Name: ai_chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.ai_chat_messages_id_seq OWNED BY public.ai_chat_messages.id;


--
-- Name: ai_chat_sessions; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.ai_chat_sessions OWNER TO unicheck_user;

--
-- Name: ai_chat_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.ai_chat_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ai_chat_sessions_id_seq OWNER TO unicheck_user;

--
-- Name: ai_chat_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.ai_chat_sessions_id_seq OWNED BY public.ai_chat_sessions.id;


--
-- Name: alerts; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.alerts OWNER TO unicheck_user;

--
-- Name: alerts_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.alerts_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.alerts_id_seq OWNER TO unicheck_user;

--
-- Name: alerts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.alerts_id_seq OWNED BY public.alerts.id;


--
-- Name: assignment_submissions; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.assignment_submissions OWNER TO unicheck_user;

--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.assignment_submissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assignment_submissions_id_seq OWNER TO unicheck_user;

--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.assignment_submissions_id_seq OWNED BY public.assignment_submissions.id;


--
-- Name: assignments; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.assignments OWNER TO unicheck_user;

--
-- Name: assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.assignments_id_seq OWNER TO unicheck_user;

--
-- Name: assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.assignments_id_seq OWNED BY public.assignments.id;


--
-- Name: attendance_configs; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.attendance_configs OWNER TO unicheck_user;

--
-- Name: attendance_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.attendance_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_configs_id_seq OWNER TO unicheck_user;

--
-- Name: attendance_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.attendance_configs_id_seq OWNED BY public.attendance_configs.id;


--
-- Name: attendance_sessions; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.attendance_sessions (
    id bigint NOT NULL,
    timetable_slot_id bigint NOT NULL,
    lecturer_id bigint,
    opened_at timestamp without time zone,
    closed_at timestamp without time zone,
    status character varying(20) DEFAULT 'CREATED'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.attendance_sessions OWNER TO unicheck_user;

--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.attendance_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attendance_sessions_id_seq OWNER TO unicheck_user;

--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.attendance_sessions_id_seq OWNED BY public.attendance_sessions.id;


--
-- Name: chat_group_members; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.chat_group_members (
    id bigint NOT NULL,
    chat_group_id bigint NOT NULL,
    user_id bigint NOT NULL,
    role character varying(20) DEFAULT 'MEMBER'::character varying NOT NULL,
    joined_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    left_at timestamp without time zone
);


ALTER TABLE public.chat_group_members OWNER TO unicheck_user;

--
-- Name: chat_group_members_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.chat_group_members_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_group_members_id_seq OWNER TO unicheck_user;

--
-- Name: chat_group_members_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.chat_group_members_id_seq OWNED BY public.chat_group_members.id;


--
-- Name: chat_groups; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.chat_groups (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    class_name character varying(50),
    created_by_id bigint,
    type character varying(20) DEFAULT 'CLASS'::character varying NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.chat_groups OWNER TO unicheck_user;

--
-- Name: chat_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.chat_groups_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_groups_id_seq OWNER TO unicheck_user;

--
-- Name: chat_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.chat_groups_id_seq OWNED BY public.chat_groups.id;


--
-- Name: chat_message_reactions; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.chat_message_reactions (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    emoji character varying(10) NOT NULL,
    reacted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.chat_message_reactions OWNER TO unicheck_user;

--
-- Name: chat_message_reactions_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.chat_message_reactions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_message_reactions_id_seq OWNER TO unicheck_user;

--
-- Name: chat_message_reactions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.chat_message_reactions_id_seq OWNED BY public.chat_message_reactions.id;


--
-- Name: chat_message_reads; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.chat_message_reads (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    user_id bigint NOT NULL,
    read_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.chat_message_reads OWNER TO unicheck_user;

--
-- Name: chat_message_reads_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.chat_message_reads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_message_reads_id_seq OWNER TO unicheck_user;

--
-- Name: chat_message_reads_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.chat_message_reads_id_seq OWNED BY public.chat_message_reads.id;


--
-- Name: chat_messages; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.chat_messages OWNER TO unicheck_user;

--
-- Name: chat_messages_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.chat_messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.chat_messages_id_seq OWNER TO unicheck_user;

--
-- Name: chat_messages_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.chat_messages_id_seq OWNED BY public.chat_messages.id;


--
-- Name: class_sections; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.class_sections OWNER TO unicheck_user;

--
-- Name: course_prerequisites; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.course_prerequisites (
    course_id bigint NOT NULL,
    prerequisite_id bigint NOT NULL
);


ALTER TABLE public.course_prerequisites OWNER TO unicheck_user;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.courses OWNER TO unicheck_user;

--
-- Name: courses_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.courses_id_seq OWNER TO unicheck_user;

--
-- Name: courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.courses_id_seq OWNED BY public.courses.id;


--
-- Name: enrollments; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.enrollments OWNER TO unicheck_user;

--
-- Name: enrollments_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.enrollments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.enrollments_id_seq OWNER TO unicheck_user;

--
-- Name: enrollments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.enrollments_id_seq OWNED BY public.enrollments.id;


--
-- Name: face_encodings; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.face_encodings (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    encoding_data bytea NOT NULL,
    registered_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    liveness_verified boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    face_image text
);


ALTER TABLE public.face_encodings OWNER TO unicheck_user;

--
-- Name: face_encodings_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.face_encodings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.face_encodings_id_seq OWNER TO unicheck_user;

--
-- Name: face_encodings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.face_encodings_id_seq OWNED BY public.face_encodings.id;


--
-- Name: flyway_schema_history; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.flyway_schema_history OWNER TO unicheck_user;

--
-- Name: grade_components; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.grade_components OWNER TO unicheck_user;

--
-- Name: grade_components_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.grade_components_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.grade_components_id_seq OWNER TO unicheck_user;

--
-- Name: grade_components_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.grade_components_id_seq OWNED BY public.grade_components.id;


--
-- Name: holidays; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.holidays (
    id bigint NOT NULL,
    semester_id bigint NOT NULL,
    holiday_date date NOT NULL,
    description character varying(255),
    is_recurring boolean DEFAULT false NOT NULL
);


ALTER TABLE public.holidays OWNER TO unicheck_user;

--
-- Name: holidays_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.holidays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.holidays_id_seq OWNER TO unicheck_user;

--
-- Name: holidays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.holidays_id_seq OWNED BY public.holidays.id;


--
-- Name: import_jobs; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.import_jobs OWNER TO unicheck_user;

--
-- Name: import_jobs_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.import_jobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.import_jobs_id_seq OWNER TO unicheck_user;

--
-- Name: import_jobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.import_jobs_id_seq OWNED BY public.import_jobs.id;


--
-- Name: lecturer_grade_otps; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.lecturer_grade_otps (
    user_id bigint NOT NULL,
    otp_hash character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_used_at timestamp without time zone
);


ALTER TABLE public.lecturer_grade_otps OWNER TO unicheck_user;

--
-- Name: lecturer_profiles; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.lecturer_profiles (
    user_id bigint NOT NULL,
    department character varying(100),
    expertise character varying(100),
    bio text
);


ALTER TABLE public.lecturer_profiles OWNER TO unicheck_user;

--
-- Name: majors; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.majors OWNER TO unicheck_user;

--
-- Name: majors_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.majors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.majors_id_seq OWNER TO unicheck_user;

--
-- Name: majors_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.majors_id_seq OWNED BY public.majors.id;


--
-- Name: news; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.news OWNER TO unicheck_user;

--
-- Name: news_attachments; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.news_attachments (
    id bigint NOT NULL,
    news_id bigint NOT NULL,
    url text NOT NULL
);


ALTER TABLE public.news_attachments OWNER TO unicheck_user;

--
-- Name: news_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.news_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.news_attachments_id_seq OWNER TO unicheck_user;

--
-- Name: news_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.news_attachments_id_seq OWNED BY public.news_attachments.id;


--
-- Name: news_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.news_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.news_id_seq OWNER TO unicheck_user;

--
-- Name: news_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.news_id_seq OWNED BY public.news.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.notifications OWNER TO unicheck_user;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.notifications_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO unicheck_user;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: room_wifi_access_points; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.room_wifi_access_points OWNER TO unicheck_user;

--
-- Name: room_wifi_access_points_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.room_wifi_access_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.room_wifi_access_points_id_seq OWNER TO unicheck_user;

--
-- Name: room_wifi_access_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.room_wifi_access_points_id_seq OWNED BY public.room_wifi_access_points.id;


--
-- Name: rooms; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.rooms OWNER TO unicheck_user;

--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.rooms_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rooms_id_seq OWNER TO unicheck_user;

--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.rooms_id_seq OWNED BY public.rooms.id;


--
-- Name: schedule_requests; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.schedule_requests OWNER TO unicheck_user;

--
-- Name: schedule_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.schedule_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.schedule_requests_id_seq OWNER TO unicheck_user;

--
-- Name: schedule_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.schedule_requests_id_seq OWNED BY public.schedule_requests.id;


--
-- Name: semester_configs; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.semester_configs OWNER TO unicheck_user;

--
-- Name: semester_configs_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.semester_configs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.semester_configs_id_seq OWNER TO unicheck_user;

--
-- Name: semester_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.semester_configs_id_seq OWNED BY public.semester_configs.id;


--
-- Name: semester_weekdays; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.semester_weekdays (
    id bigint NOT NULL,
    semester_id bigint NOT NULL,
    weekday integer NOT NULL
);


ALTER TABLE public.semester_weekdays OWNER TO unicheck_user;

--
-- Name: semester_weekdays_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.semester_weekdays_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.semester_weekdays_id_seq OWNER TO unicheck_user;

--
-- Name: semester_weekdays_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.semester_weekdays_id_seq OWNED BY public.semester_weekdays.id;


--
-- Name: semesters; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.semesters OWNER TO unicheck_user;

--
-- Name: semesters_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.semesters_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.semesters_id_seq OWNER TO unicheck_user;

--
-- Name: semesters_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.semesters_id_seq OWNED BY public.semesters.id;


--
-- Name: slot_types; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.slot_types OWNER TO unicheck_user;

--
-- Name: slot_types_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.slot_types_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.slot_types_id_seq OWNER TO unicheck_user;

--
-- Name: slot_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.slot_types_id_seq OWNED BY public.slot_types.id;


--
-- Name: specialization_courses; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.specialization_courses OWNER TO unicheck_user;

--
-- Name: specialization_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.specialization_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.specialization_courses_id_seq OWNER TO unicheck_user;

--
-- Name: specialization_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.specialization_courses_id_seq OWNED BY public.specialization_courses.id;


--
-- Name: specializations; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.specializations OWNER TO unicheck_user;

--
-- Name: specializations_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.specializations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.specializations_id_seq OWNER TO unicheck_user;

--
-- Name: specializations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.specializations_id_seq OWNED BY public.specializations.id;


--
-- Name: student_attendances; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.student_attendances OWNER TO unicheck_user;

--
-- Name: student_attendances_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.student_attendances_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.student_attendances_id_seq OWNER TO unicheck_user;

--
-- Name: student_attendances_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.student_attendances_id_seq OWNED BY public.student_attendances.id;


--
-- Name: student_grades; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.student_grades OWNER TO unicheck_user;

--
-- Name: student_grades_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.student_grades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.student_grades_id_seq OWNER TO unicheck_user;

--
-- Name: student_grades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.student_grades_id_seq OWNED BY public.student_grades.id;


--
-- Name: student_profiles; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.student_profiles (
    user_id bigint NOT NULL,
    course character varying(20),
    gpa double precision DEFAULT 0.0,
    major_id bigint,
    specialization_id bigint,
    sub_specialization_id bigint
);


ALTER TABLE public.student_profiles OWNER TO unicheck_user;

--
-- Name: sub_specialization_courses; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.sub_specialization_courses OWNER TO unicheck_user;

--
-- Name: sub_specialization_courses_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.sub_specialization_courses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_specialization_courses_id_seq OWNER TO unicheck_user;

--
-- Name: sub_specialization_courses_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.sub_specialization_courses_id_seq OWNED BY public.sub_specialization_courses.id;


--
-- Name: sub_specializations; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.sub_specializations OWNER TO unicheck_user;

--
-- Name: sub_specializations_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.sub_specializations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_specializations_id_seq OWNER TO unicheck_user;

--
-- Name: sub_specializations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.sub_specializations_id_seq OWNED BY public.sub_specializations.id;


--
-- Name: system_logs; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.system_logs OWNER TO unicheck_user;

--
-- Name: system_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.system_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.system_logs_id_seq OWNER TO unicheck_user;

--
-- Name: system_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.system_logs_id_seq OWNED BY public.system_logs.id;


--
-- Name: teaching_assignments; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.teaching_assignments (
    id bigint NOT NULL,
    lecturer_id bigint NOT NULL,
    course_id bigint NOT NULL,
    semester_id bigint NOT NULL
);


ALTER TABLE public.teaching_assignments OWNER TO unicheck_user;

--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.teaching_assignments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.teaching_assignments_id_seq OWNER TO unicheck_user;

--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.teaching_assignments_id_seq OWNED BY public.teaching_assignments.id;


--
-- Name: timetable_slots; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.timetable_slots OWNER TO unicheck_user;

--
-- Name: timetable_slots_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.timetable_slots_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timetable_slots_id_seq OWNER TO unicheck_user;

--
-- Name: timetable_slots_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.timetable_slots_id_seq OWNED BY public.timetable_slots.id;


--
-- Name: user_device_tokens; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.user_device_tokens OWNER TO unicheck_user;

--
-- Name: user_device_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.user_device_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_device_tokens_id_seq OWNER TO unicheck_user;

--
-- Name: user_device_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.user_device_tokens_id_seq OWNED BY public.user_device_tokens.id;


--
-- Name: user_permissions; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.user_permissions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    permission character varying(50) NOT NULL,
    granted_by bigint,
    granted_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.user_permissions OWNER TO unicheck_user;

--
-- Name: user_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.user_permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_permissions_id_seq OWNER TO unicheck_user;

--
-- Name: user_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.user_permissions_id_seq OWNED BY public.user_permissions.id;


--
-- Name: user_sessions; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.user_sessions (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    token character varying(500),
    ip_address character varying(45),
    province character varying(100),
    city character varying(100),
    latitude numeric(11,8),
    longitude numeric(11,8),
    login_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    last_activity_time timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_active boolean DEFAULT true,
    user_agent character varying(500)
);


ALTER TABLE public.user_sessions OWNER TO unicheck_user;

--
-- Name: user_sessions_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.user_sessions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_sessions_id_seq OWNER TO unicheck_user;

--
-- Name: user_sessions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.user_sessions_id_seq OWNED BY public.user_sessions.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: unicheck_user
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    username character varying(50) NOT NULL,
    password character varying(255),
    full_name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    dob date,
    phone character varying(20),
    sex character varying(10) DEFAULT 'OTHER'::character varying NOT NULL,
    role character varying(20) DEFAULT 'STUDENT'::character varying NOT NULL,
    status character varying(20) DEFAULT 'ACTIVE'::character varying NOT NULL,
    face_data_status character varying(20) DEFAULT 'NOT_REGISTERED'::character varying NOT NULL,
    avatar character varying(255),
    face_registration_attempts integer DEFAULT 0 NOT NULL,
    face_registration_blocked_until timestamp without time zone,
    is_password_changed boolean DEFAULT false NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    code character varying(50)
);


ALTER TABLE public.users OWNER TO unicheck_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO unicheck_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: wifi_access_points; Type: TABLE; Schema: public; Owner: unicheck_user
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


ALTER TABLE public.wifi_access_points OWNER TO unicheck_user;

--
-- Name: wifi_access_points_id_seq; Type: SEQUENCE; Schema: public; Owner: unicheck_user
--

CREATE SEQUENCE public.wifi_access_points_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.wifi_access_points_id_seq OWNER TO unicheck_user;

--
-- Name: wifi_access_points_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: unicheck_user
--

ALTER SEQUENCE public.wifi_access_points_id_seq OWNED BY public.wifi_access_points.id;


--
-- Name: academic_requests id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests ALTER COLUMN id SET DEFAULT nextval('public.academic_requests_id_seq'::regclass);


--
-- Name: access_logs id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.access_logs ALTER COLUMN id SET DEFAULT nextval('public.access_logs_id_seq'::regclass);


--
-- Name: ai_chat_messages id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.ai_chat_messages ALTER COLUMN id SET DEFAULT nextval('public.ai_chat_messages_id_seq'::regclass);


--
-- Name: ai_chat_sessions id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.ai_chat_sessions ALTER COLUMN id SET DEFAULT nextval('public.ai_chat_sessions_id_seq'::regclass);


--
-- Name: alerts id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.alerts ALTER COLUMN id SET DEFAULT nextval('public.alerts_id_seq'::regclass);


--
-- Name: assignment_submissions id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignment_submissions ALTER COLUMN id SET DEFAULT nextval('public.assignment_submissions_id_seq'::regclass);


--
-- Name: assignments id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignments ALTER COLUMN id SET DEFAULT nextval('public.assignments_id_seq'::regclass);


--
-- Name: attendance_configs id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_configs ALTER COLUMN id SET DEFAULT nextval('public.attendance_configs_id_seq'::regclass);


--
-- Name: attendance_sessions id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_sessions ALTER COLUMN id SET DEFAULT nextval('public.attendance_sessions_id_seq'::regclass);


--
-- Name: chat_group_members id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_group_members ALTER COLUMN id SET DEFAULT nextval('public.chat_group_members_id_seq'::regclass);


--
-- Name: chat_groups id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_groups ALTER COLUMN id SET DEFAULT nextval('public.chat_groups_id_seq'::regclass);


--
-- Name: chat_message_reactions id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reactions ALTER COLUMN id SET DEFAULT nextval('public.chat_message_reactions_id_seq'::regclass);


--
-- Name: chat_message_reads id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reads ALTER COLUMN id SET DEFAULT nextval('public.chat_message_reads_id_seq'::regclass);


--
-- Name: chat_messages id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_messages ALTER COLUMN id SET DEFAULT nextval('public.chat_messages_id_seq'::regclass);


--
-- Name: courses id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.courses ALTER COLUMN id SET DEFAULT nextval('public.courses_id_seq'::regclass);


--
-- Name: enrollments id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.enrollments ALTER COLUMN id SET DEFAULT nextval('public.enrollments_id_seq'::regclass);


--
-- Name: face_encodings id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.face_encodings ALTER COLUMN id SET DEFAULT nextval('public.face_encodings_id_seq'::regclass);


--
-- Name: grade_components id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.grade_components ALTER COLUMN id SET DEFAULT nextval('public.grade_components_id_seq'::regclass);


--
-- Name: holidays id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.holidays ALTER COLUMN id SET DEFAULT nextval('public.holidays_id_seq'::regclass);


--
-- Name: import_jobs id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.import_jobs ALTER COLUMN id SET DEFAULT nextval('public.import_jobs_id_seq'::regclass);


--
-- Name: majors id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.majors ALTER COLUMN id SET DEFAULT nextval('public.majors_id_seq'::regclass);


--
-- Name: news id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.news ALTER COLUMN id SET DEFAULT nextval('public.news_id_seq'::regclass);


--
-- Name: news_attachments id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.news_attachments ALTER COLUMN id SET DEFAULT nextval('public.news_attachments_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: room_wifi_access_points id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.room_wifi_access_points ALTER COLUMN id SET DEFAULT nextval('public.room_wifi_access_points_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.rooms ALTER COLUMN id SET DEFAULT nextval('public.rooms_id_seq'::regclass);


--
-- Name: schedule_requests id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests ALTER COLUMN id SET DEFAULT nextval('public.schedule_requests_id_seq'::regclass);


--
-- Name: semester_configs id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semester_configs ALTER COLUMN id SET DEFAULT nextval('public.semester_configs_id_seq'::regclass);


--
-- Name: semester_weekdays id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semester_weekdays ALTER COLUMN id SET DEFAULT nextval('public.semester_weekdays_id_seq'::regclass);


--
-- Name: semesters id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semesters ALTER COLUMN id SET DEFAULT nextval('public.semesters_id_seq'::regclass);


--
-- Name: slot_types id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.slot_types ALTER COLUMN id SET DEFAULT nextval('public.slot_types_id_seq'::regclass);


--
-- Name: specialization_courses id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specialization_courses ALTER COLUMN id SET DEFAULT nextval('public.specialization_courses_id_seq'::regclass);


--
-- Name: specializations id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specializations ALTER COLUMN id SET DEFAULT nextval('public.specializations_id_seq'::regclass);


--
-- Name: student_attendances id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_attendances ALTER COLUMN id SET DEFAULT nextval('public.student_attendances_id_seq'::regclass);


--
-- Name: student_grades id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_grades ALTER COLUMN id SET DEFAULT nextval('public.student_grades_id_seq'::regclass);


--
-- Name: sub_specialization_courses id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specialization_courses ALTER COLUMN id SET DEFAULT nextval('public.sub_specialization_courses_id_seq'::regclass);


--
-- Name: sub_specializations id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specializations ALTER COLUMN id SET DEFAULT nextval('public.sub_specializations_id_seq'::regclass);


--
-- Name: system_logs id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.system_logs ALTER COLUMN id SET DEFAULT nextval('public.system_logs_id_seq'::regclass);


--
-- Name: teaching_assignments id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.teaching_assignments ALTER COLUMN id SET DEFAULT nextval('public.teaching_assignments_id_seq'::regclass);


--
-- Name: timetable_slots id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.timetable_slots ALTER COLUMN id SET DEFAULT nextval('public.timetable_slots_id_seq'::regclass);


--
-- Name: user_device_tokens id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_device_tokens ALTER COLUMN id SET DEFAULT nextval('public.user_device_tokens_id_seq'::regclass);


--
-- Name: user_permissions id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_permissions ALTER COLUMN id SET DEFAULT nextval('public.user_permissions_id_seq'::regclass);


--
-- Name: user_sessions id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_sessions ALTER COLUMN id SET DEFAULT nextval('public.user_sessions_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: wifi_access_points id; Type: DEFAULT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.wifi_access_points ALTER COLUMN id SET DEFAULT nextval('public.wifi_access_points_id_seq'::regclass);


--
-- Data for Name: academic_requests; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.academic_requests (id, student_id, request_type, request_title, semester_id, course_id, class_section_id, to_major, to_specialization, to_sub_specialization, reason, note, file_url, status, start_date, due_date, approver_id, approved_at, approver_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: access_logs; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.access_logs (id, user_id, location, status, access_time, ip_address, user_agent) FROM stdin;
1	1	Vietnam	SUCCESS	2026-10-16 07:10:30.206527	172.19.0.1	curl/8.21.0
2	1	Vietnam	SUCCESS	2026-10-16 07:10:37.596738	172.19.0.1	curl/8.21.0
3	1	Vietnam	SUCCESS	2026-10-16 07:10:43.396256	172.19.0.1	curl/8.21.0
4	1	Vietnam	SUCCESS	2026-10-16 07:25:26.458485	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
5	1	Vietnam	SUCCESS	2026-10-16 07:47:37.511977	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
6	1	Vietnam	SUCCESS	2026-10-16 07:48:33.084075	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
7	1	Vietnam	SUCCESS	2026-10-16 07:48:47.652741	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
8	1	Vietnam	SUCCESS	2026-10-16 07:50:17.915178	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
9	1	Vietnam	SUCCESS	2026-10-16 07:50:22.819651	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
10	1	Vietnam	SUCCESS	2026-10-16 07:50:41.035862	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
11	1	Vietnam	SUCCESS	2026-10-16 07:50:52.680316	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
12	1	Vietnam	SUCCESS	2026-10-16 07:51:18.631422	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
13	1	Vietnam	SUCCESS	2026-10-16 07:51:42.163397	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
14	1	Vietnam	SUCCESS	2026-10-16 14:21:27.205931	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
15	1	Vietnam	SUCCESS	2026-10-16 14:29:41.83062	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
16	1	Vietnam	SUCCESS	2026-10-16 14:30:06.45069	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
17	1	Vietnam	SUCCESS	2026-10-16 14:30:21.368667	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
18	1	Vietnam	SUCCESS	2026-10-16 14:30:28.493774	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
19	2	Vietnam	SUCCESS	2026-10-16 14:30:51.347503	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
20	2	Vietnam	SUCCESS	2026-10-16 14:30:51.440434	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
21	2	Vietnam	SUCCESS	2026-10-16 14:31:00.706197	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
22	2	Vietnam	SUCCESS	2026-10-16 14:31:10.382452	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
23	2	Vietnam	SUCCESS	2026-10-16 14:33:31.57709	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
24	1	Vietnam	LOGOUT	2026-10-16 14:35:22.658315	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
25	2	Vietnam	SUCCESS	2026-10-16 14:35:32.980979	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
26	2	Vietnam	SUCCESS	2026-10-16 14:54:32.183339	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
27	2	Vietnam	SUCCESS	2026-10-16 14:54:49.958316	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
28	2	Vietnam	SUCCESS	2026-10-16 14:55:03.059644	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
29	2	Vietnam	SUCCESS	2026-10-16 14:55:42.238244	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
30	2	Vietnam	SUCCESS	2026-10-16 14:55:55.22234	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
31	2	Vietnam	SUCCESS	2026-10-16 14:56:06.304226	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
32	1	Vietnam	SUCCESS	2026-10-18 15:07:01.726976	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
33	1	Vietnam	LOGOUT	2026-10-18 15:08:20.945038	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
34	1	Vietnam	SUCCESS	2026-10-18 15:08:53.130656	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
35	1	Vietnam	LOGOUT	2026-10-18 15:10:00.157254	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
36	3	Vietnam	SUCCESS	2026-10-18 15:10:08.868754	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
37	1	Vietnam	SUCCESS	2026-10-18 15:12:11.398495	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
38	1	Vietnam	SUCCESS	2026-10-18 15:17:57.391871	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
39	1	Vietnam	SUCCESS	2026-10-18 15:18:03.800017	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
40	1	Vietnam	SUCCESS	2026-10-18 15:19:24.933359	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
41	3	Vietnam	LOGOUT	2026-10-18 15:20:13.535585	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
42	2	Vietnam	SUCCESS	2026-10-18 15:20:15.738735	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
43	1	Vietnam	SUCCESS	2026-10-18 15:25:47.698292	172.19.0.1	curl/8.21.0
44	1	Vietnam	SUCCESS	2026-10-18 15:36:11.873354	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
45	1	Vietnam	SUCCESS	2026-10-18 15:36:25.70544	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
46	1	Vietnam	SUCCESS	2026-10-18 15:36:32.541067	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
47	1	Vietnam	SUCCESS	2026-10-18 15:36:50.665329	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
48	1	Vietnam	SUCCESS	2026-10-18 15:37:00.052871	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
49	1	Vietnam	SUCCESS	2026-10-18 15:37:11.620462	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
50	1	Vietnam	SUCCESS	2026-10-18 15:37:17.200144	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
51	1	Vietnam	SUCCESS	2026-10-18 15:37:25.813695	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
52	1	Vietnam	SUCCESS	2026-10-18 15:38:46.61613	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
53	1	Vietnam	SUCCESS	2026-10-18 15:38:53.128119	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
54	1	Vietnam	SUCCESS	2026-10-18 15:38:58.558308	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
55	1	Vietnam	SUCCESS	2026-10-18 15:39:03.430682	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
56	1	Vietnam	SUCCESS	2026-10-18 15:39:29.82402	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
57	1	Vietnam	SUCCESS	2026-10-18 15:39:37.349576	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
58	1	Vietnam	SUCCESS	2026-10-18 15:39:44.255999	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
59	1	Vietnam	SUCCESS	2026-10-18 15:39:52.357394	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
60	1	Vietnam	SUCCESS	2026-10-18 15:39:57.041848	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
61	1	Vietnam	SUCCESS	2026-10-18 16:04:06.280427	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
62	1	Vietnam	SUCCESS	2026-10-18 16:12:44.460155	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
63	1	Vietnam	SUCCESS	2026-10-18 16:13:12.139878	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
64	1	Vietnam	SUCCESS	2026-10-18 16:13:20.14266	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
65	1	Vietnam	SUCCESS	2026-10-18 16:50:09.69249	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
66	1	Vietnam	SUCCESS	2026-10-18 16:50:16.840072	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
67	1	Vietnam	SUCCESS	2026-10-18 16:57:34.167456	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
68	1	Vietnam	SUCCESS	2026-10-18 16:58:19.404376	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
69	1	Vietnam	LOGOUT	2026-10-18 17:00:59.472243	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
70	3	Vietnam	SUCCESS	2026-10-18 17:01:01.765486	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
71	3	Vietnam	LOGOUT	2026-10-18 17:01:35.105543	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
72	1	Vietnam	SUCCESS	2026-10-18 17:01:37.395807	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
73	2	Vietnam	SUCCESS	2026-10-18 17:02:26.395632	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36 Edg/155.0.0.0
74	2	Vietnam	LOGOUT	2026-10-18 17:02:42.897068	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
75	3	Vietnam	SUCCESS	2026-10-18 17:02:45.941843	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
76	3	Vietnam	SUCCESS	2026-10-19 06:33:56.099786	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
77	1	Vietnam	SUCCESS	2026-10-19 07:55:23.05802	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
78	2	Vietnam	SUCCESS	2026-10-19 07:55:29.494302	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
79	2	Vietnam	SUCCESS	2026-10-19 07:55:59.273445	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
80	2	Vietnam	SUCCESS	2026-10-19 07:56:20.593712	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
81	3	Vietnam	SUCCESS	2026-10-19 07:56:20.668772	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
82	3	Vietnam	SUCCESS	2026-10-19 07:56:43.353051	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
83	2	Vietnam	SUCCESS	2026-10-19 07:56:43.732598	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
84	3	Vietnam	SUCCESS	2026-10-19 07:59:11.891659	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
85	2	Vietnam	SUCCESS	2026-10-19 07:59:12.011158	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
86	3	Vietnam	LOGOUT	2026-10-19 08:38:15.165748	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
87	3	Vietnam	LOGOUT	2026-10-19 08:38:15.165748	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
88	2	Vietnam	SUCCESS	2026-10-19 08:38:24.657741	172.19.0.1	Dart/3.13 (dart:io)
89	1	Vietnam	SUCCESS	2026-10-20 06:41:41.554351	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
92	1	Vietnam	LOGOUT	2026-10-20 07:40:20.430777	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
91	1	Vietnam	LOGOUT	2026-10-20 07:40:20.430823	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
90	1	Vietnam	LOGOUT	2026-10-20 07:40:20.430823	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
93	2	Vietnam	SUCCESS	2026-10-20 07:40:41.383721	172.19.0.1	Dart/3.13 (dart:io)
94	2	Vietnam	SUCCESS	2026-10-20 07:44:26.865786	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
95	2	Vietnam	LOGOUT	2026-10-20 07:45:34.25401	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
96	2	Vietnam	SUCCESS	2026-10-20 07:45:35.961773	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
97	2	Vietnam	LOGOUT	2026-10-20 07:45:50.481554	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
100	1	Vietnam	SUCCESS	2026-10-20 07:50:33.273761	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
103	4	Vietnam	LOGOUT	2026-10-20 07:51:57.016664	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
106	2	Vietnam	SUCCESS	2026-10-20 07:52:39.376514	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
98	1	Vietnam	SUCCESS	2026-10-20 07:46:06.999117	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
104	1	Vietnam	SUCCESS	2026-10-20 07:51:59.687118	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
99	1	Vietnam	LOGOUT	2026-10-20 07:50:13.836624	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
101	1	Vietnam	LOGOUT	2026-10-20 07:50:47.613959	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
105	1	Vietnam	LOGOUT	2026-10-20 07:52:37.128402	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
102	4	Vietnam	SUCCESS	2026-10-20 07:51:01.568772	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
107	2	Vietnam	SUCCESS	2026-10-20 08:10:10.892274	172.19.0.1	Dart/3.13 (dart:io)
108	2	Vietnam	LOGOUT	2026-10-20 08:35:34.94399	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
109	2	Vietnam	LOGOUT	2026-10-20 08:35:34.943987	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
110	1	Vietnam	SUCCESS	2026-10-20 08:35:44.297376	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
111	1	Vietnam	LOGOUT	2026-10-20 08:36:01.48566	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
112	1	Vietnam	SUCCESS	2026-10-20 08:36:04.849967	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
113	1	Vietnam	LOGOUT	2026-10-20 08:36:30.687715	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
114	1	Vietnam	SUCCESS	2026-10-20 08:36:45.324345	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
115	1	Vietnam	LOGOUT	2026-10-20 08:36:47.25314	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
116	1	Vietnam	SUCCESS	2026-10-20 08:37:06.585365	172.19.0.1	curl/8.21.0
117	1	Vietnam	SUCCESS	2026-10-20 08:37:19.479559	172.19.0.1	curl/8.21.0
118	3	Vietnam	SUCCESS	2026-10-20 08:43:05.397608	172.19.0.1	curl/8.21.0
119	3	Vietnam	SUCCESS	2026-10-20 08:43:57.817493	172.19.0.1	curl/8.21.0
120	1	Vietnam	SUCCESS	2026-10-20 09:06:33.963126	172.19.0.1	node
121	2	Vietnam	SUCCESS	2026-10-20 09:06:39.363876	172.19.0.1	node
122	3	Vietnam	SUCCESS	2026-10-20 09:06:39.483121	172.19.0.1	node
123	2	Vietnam	SUCCESS	2026-10-20 09:10:00.010413	172.19.0.1	node
124	1	Vietnam	SUCCESS	2026-10-20 09:10:19.843098	172.19.0.1	node
125	3	Vietnam	SUCCESS	2026-10-20 09:10:19.864229	172.19.0.1	node
126	2	Vietnam	SUCCESS	2026-10-20 09:10:19.864927	172.19.0.1	node
127	2	Vietnam	SUCCESS	2026-10-20 09:10:31.610462	172.19.0.1	node
128	4	Vietnam	SUCCESS	2026-10-20 09:10:40.312002	172.19.0.1	node
129	2	Vietnam	SUCCESS	2026-10-20 09:11:13.64225	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
130	2	Vietnam	LOGOUT	2026-10-20 09:12:55.945414	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
131	3	Vietnam	SUCCESS	2026-10-20 09:14:03.182839	172.19.0.1	node
132	3	Vietnam	SUCCESS	2026-10-20 09:15:01.297493	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
133	2	Vietnam	SUCCESS	2026-10-20 09:19:28.598411	172.19.0.1	Dart/3.13 (dart:io)
134	2	Vietnam	SUCCESS	2026-10-20 09:38:35.964432	172.19.0.1	node
135	3	Vietnam	SUCCESS	2026-10-21 13:01:33.332794	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
136	3	Vietnam	LOGOUT	2026-10-21 13:51:05.651994	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
137	3	Vietnam	SUCCESS	2026-10-29 08:11:14.462278	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36
\.


--
-- Data for Name: ai_chat_messages; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.ai_chat_messages (id, session_id, role, content, tokens_count, model_version, processing_time_ms, redirect_path, created_at) FROM stdin;
\.


--
-- Data for Name: ai_chat_sessions; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.ai_chat_sessions (id, user_id, title, status, last_message_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.alerts (id, user_id, title, content, type, is_resolved, resolved_at, resolved_by, created_at) FROM stdin;
\.


--
-- Data for Name: assignment_submissions; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.assignment_submissions (id, assignment_id, student_id, enrollment_id, file_url, file_name, note, lecturer_comment, status, submitted_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: assignments; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.assignments (id, title, description, class_name, created_by_id, timetable_slot_id, due_date, status, reference_url, reference_name, reminder_sent, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attendance_configs; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.attendance_configs (id, config_key, manual_enabled, absent_threshold_minutes, min_attendance_percentage, face_recognition_enabled, max_attempts, wifi_location_enabled, created_at, updated_at) FROM stdin;
1	DEFAULT	t	15	80	t	3	t	2026-10-18 15:38:33.753818	2026-10-18 15:38:33.753818
\.


--
-- Data for Name: attendance_sessions; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.attendance_sessions (id, timetable_slot_id, lecturer_id, opened_at, closed_at, status, created_at) FROM stdin;
4	1	3	2026-10-18 17:17:26.078548	2026-10-18 17:18:01.681623	CLOSED	2026-10-18 17:17:26.078548
37	2	3	2026-10-19 06:34:16.736539	2026-10-19 07:03:09.662858	CLOSED	2026-10-19 06:34:16.736539
38	3	3	2026-10-19 07:56:43.605516	\N	OPEN	2026-10-19 07:56:43.564436
\.


--
-- Data for Name: chat_group_members; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.chat_group_members (id, chat_group_id, user_id, role, joined_at, left_at) FROM stdin;
\.


--
-- Data for Name: chat_groups; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.chat_groups (id, name, class_name, created_by_id, type, created_at) FROM stdin;
\.


--
-- Data for Name: chat_message_reactions; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.chat_message_reactions (id, message_id, user_id, emoji, reacted_at) FROM stdin;
\.


--
-- Data for Name: chat_message_reads; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.chat_message_reads (id, message_id, user_id, read_at) FROM stdin;
\.


--
-- Data for Name: chat_messages; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.chat_messages (id, chat_group_id, sender_id, content, type, attachment_url, attachment_name, reply_to_id, is_deleted, sent_at) FROM stdin;
\.


--
-- Data for Name: class_sections; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.class_sections (class_name, course_id, semester_id, lecturer_id, number_of_slots, max_students, current_enrollment, status, grades_submitted, grades_submitted_at, grades_submitted_by, grades_published, grades_published_at, grades_published_by, resit_grades_published, resit_grades_published_at, resit_grades_published_by, created_at, updated_at) FROM stdin;
IT301	1	1	3	45	30	1	ACTIVE	f	\N	\N	f	\N	\N	f	\N	\N	2026-10-18 15:19:25.346646	2026-10-18 15:20:40.570964
IT301.02	1	1	3	45	45	1	OPEN	f	\N	\N	f	\N	\N	f	\N	\N	2026-10-18 15:25:52.672831	2026-10-18 17:04:01.115958
\.


--
-- Data for Name: course_prerequisites; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.course_prerequisites (course_id, prerequisite_id) FROM stdin;
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.courses (id, code, name, description, credits, number_of_slots, status, is_calculated_in_gpa, created_at, updated_at) FROM stdin;
1	IT301	Lập trình Web	\N	3	45	ACTIVE	t	2026-10-18 15:18:09.728077	2026-10-18 15:18:09.728084
\.


--
-- Data for Name: enrollments; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.enrollments (id, class_name, student_code, student_id, status, created_at, updated_at) FROM stdin;
1	IT301	SV2026001	2	ENROLLED	2026-10-18 15:20:40.550103	2026-10-18 15:20:40.550107
2	IT301.02	SV2026001	2	ENROLLED	2026-10-18 17:04:01.108851	2026-10-18 17:04:01.108853
\.


--
-- Data for Name: face_encodings; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.face_encodings (id, user_id, encoding_data, registered_at, liveness_verified, created_at, updated_at, face_image) FROM stdin;
3	2	\\xdea99cbdb91963bdd93bf7bd2101083d20fa4f3d1031a23de6db3fbd26460d3ee39fa5bdfe158d3d262442bc1aa318bdfbd7733d6615743ce2f09dbc299931bdaec4ccbc3e4e8c3c6cf3e6bd32e4f7ba0bfc80bc28380c3cc7d38c3cf96f6fbd3b1a42bcb6915b3bf0b19cbc53d442bd4e0a1dbc56dba0bb6cb1e13b15d6ecbbca59d83c3eb312baad989bbbd147743ca0ccb5bb5659e9bc0cbf8abd7ad594bc12aebabc5e3b34bc30d1f2bc0fa9083d6b944dbd19a99cbcf7c0b73c8ccaa23c7913a63c3d59c7bbc1b8223d4f3765bc8d0a81bc52667dbcb844c7bab0dc2e3c81728abc51d78fbd2e80b7bc6f82123d36b2debc1c88203d27638ebd1604433d2f93edbc1ac179bdcd9d27ba84f09bbce93518bced0fabbd0e792dbd76083c3dda486a3c394d6ebc2e2ce03c24ec6cbb616b9cbd5a6e13bdff18093dc2af863cabaaf93d1b23d63c2ae142bd2869993ce1a44f3d1a0ec03c867149bd327b923cf49a40bddc29b13d104b3bbdff33a93c4db5063d14c384bc27239ebd57b1853c906511bd4aabefbc124fc0bc6c2a0abdd70033bd9fa64fbd6959153df91321bc90edaebc5489673d2ef8f1bb53527d3a9cb0bf3b4b5154bde188a6bb5a4b98b9236e043c19c2b9bd9de482bc6a2c973ce382b93d012957bd6c67a3bcd8e6103d0af9b6ba448ddebb4629d93cccab363c7ce1a93ca8a631bc3ce3f13ca59acf3cb24b6f3d2c0129bdfd85a83c6632b3bbe8cc47bd2f9de83cdf68b13af7e73f3d820dac3d34ca0dbc73376f3d49a6a9bc3e2d9d3cffaee8bc77bb1abd6f053b3d0f72ee3aba32463dd27f9fbcf320433cd412803bc275963c449550bdbbcf163def4cfe3bc9eadcbc571eaf3d7a190fbda740c93d187f97bdaa383cbc99ec78bb973201bc9a14bbbc16e5b6bdc6a92bbc861804ba298a8bbc8e45a43c5f6c81bc5550043dc56e27bd65e71dbd95d67bbc26fd2a3d41cb213df4aa0abdfd9526bdd2c8e93c8bd19e3bada5b5bda9442c3ddc7fdd3cd079d6bc5533a7bdbbb56e3ae48c033d54127cba2645b93c185631bd9f79b73cdbf7e03ce7aae83c81d6b23d35b6ee3b02de4d3dfe2aff3b2b76e63c7ec5063cbe917f3d377ac03d0ff1aebd8263083d0f624d3d48a1aa3a51f9f03b73adb03ca4a4983db8afdb3b2a539bbc72723dbd8a83aa3df7985b3c819391bb36c4923de0afc9bdb9bbb7bcb873c93acc44833c79b1473d06751dbd4f71b63db4e0d53c624b013df9c22fbb5b64673d483304be584e19bbf6b2a43cb5b3dabaf37a32bc995220bd4c9f1b3c86d0ddbc0694d43deb0b553de8903e3cd1efa33c0bb140bc2878a2bca7b8efbbd5ce193c4ea4313d9af98a3d8f8e48bddd52b6bdb08f273d12f538bd8f6534bd2ae7323c0125e13bbbb2d6bcd4d9bebba00d953bfa541bbdeaaaf8bca43596bd059950bb80a23fbd25aa99bd55701cbde7a5463d3f17683ce9ee7cbb1d81f9bc66cfee3c813764bcea7fcb3d22d4443cfc2863bc338bad3c2a7fadbdf26b6b3cd7c5e8bdd850783def6165bd122dd23bc41c123dc809293dccf59d3caffd1b3d974e9c3df56f01bddd34c43dfa2b203d073a0ebd63ad2cbdefdd473d49a874bcbca0553d2dec77bcf4eaaabc37f81cbd4b1ff93ccb585f3d3ae41dbd7c3a8cbd92ac1e3c4a87103db59a553cb1808ebd616c1c3d65295abb58f7913cd77473bd7f04babc75e29bbdb964a83c3329713dd8a593bd1716963d416a6abccb318abd0219613d01a6383b83e45bbdddbebc3c052acf3b33a9273dbf93bdbba1a5da3c66298b3c991e013c4a62383b7a98a83d53883bbd57bce13a464c40bdb265e53c20f08bbda3db05bc7ee4ca3cdd3d0fbab78fc43d43a92e3c0c1342bdf8edae3d12eedf3c2ec8fabcf1ac1b3d7c9643bbcb9fcbbc3983a7bc9deb783d99d693bce9fcd3bc786840bb90eba8bcdb8dea3c20edc03d6d7e0dbd7a3aa1bdac17983a02fd51bc29bb1abb44b357bc1b24e33b43a1d43d7c5a243d7397e1bc080a3ebc33b3c83d81a76d3dc0c728bdead2213c9be5693d3324283da0284c3df6ccd83bba40adbce42480bcf0b8a93b6ca48ebd84e3fc3cd51840bdd32b3b3dbda7cc3b723130bca6114ebd6042dcbc655c7c3dece6693b948c10bdd572513cb05eb0ba27259a3dd83e543de9b8e6bc39c533bc78d4fe3c36b2243d33ac72bd89e33a3d6871403d34dcdd3cc987943c283c39bc53a7903ddf8ea13d2ccd3abdc0de3fbdc516393ddb0a9dbdafa8243d100603bd0f9731bd4650633d9253a7bca9f0a93c1ad61b3cd104a5bcc6c09ebdd0cda0bc6d8b243d84aac33c61b26cbc76e6613b89baa83c363ba93bd362eebcdbbeba3c614f303df9656a3c930af53cec7a3f3dfcfe973cdf9dd3bc8e7168bddacd5a3d658b53bdba0800bdee668d3d530cda3ba0f3153d952716bc985498bde27ee1bcf786eb3c4b4c83bdc92b253dc9aa903d86f2a93d6f72fcbb5da4823d821197ba9ad05fbdd96748bdaf8609bd8370fbbc0334d7bc19d811bdb54de13bab7eba3bc79caebd80f86e3d602a013d7bbeeebc2f3ca33c889f263c277e63bd39b0693db05bd03dc6eb1c3dfd7da2bbf6a96bbd1031f0bc7ae767bc16aff33ca17caebdc178263d5c9d913d2ced8abc6777f7bc10678cbc1fde443dbcea383d589f3bbdbb2704bd078480bdfa0471bdae7d04bdb084d6bbf63a8ebdea229a3c831964bdb43640bd1980303cb7812b3c62363dbdf9b5e03a064eb23d6a9dcf3cb75d4b3cba628ebd9177dfbbb0da413c8138aebb751e96bd3055733c12ea92bbc38551bc114237bda4ddb9bc735093bd308de1bc0a3633bda9bca8bdefd4523d565c863cc46ab9bd2b4c57bcba63d0bc595be13c4e1ac23b	2026-10-20 09:20:03.262283	f	2026-10-20 08:12:47.685542	2026-10-20 09:20:03.264346	\N
\.


--
-- Data for Name: flyway_schema_history; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success) FROM stdin;
1	1	init academic catalog	SQL	V1__init_academic_catalog.sql	521673728	unicheck_user	2026-10-12 07:16:47.282795	129	t
3	3	init classes attendance and operations	SQL	V3__init_classes_attendance_and_operations.sql	261591654	unicheck_user	2026-10-12 07:16:47.536727	191	t
2	2	init users and profiles	SQL	V2__init_users_and_profiles.sql	216176508	unicheck_user	2026-10-12 07:16:47.445713	78	t
4	4	add enrollment unique and indexes	SQL	V4__add_enrollment_unique_and_indexes.sql	-694355777	unicheck_user	2026-10-16 07:04:32.888595	49	t
5	5	add room wifi indexes and unique	SQL	V5__add_room_wifi_indexes_and_unique.sql	-672912806	unicheck_user	2026-10-16 07:45:29.206283	60	t
6	6	add timetable slots indexes	SQL	V6__add_timetable_slots_indexes.sql	1196551155	unicheck_user	2026-10-16 14:33:10.705402	43	t
7	7	add attendance sessions constraints and indexes	SQL	V7__add_attendance_sessions_constraints_and_indexes.sql	766440291	unicheck_user	2026-10-18 15:38:33.72007	55	t
\.


--
-- Data for Name: grade_components; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.grade_components (id, name, description, type, weight, is_resit, reference_component_id, course_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: holidays; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.holidays (id, semester_id, holiday_date, description, is_recurring) FROM stdin;
\.


--
-- Data for Name: import_jobs; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.import_jobs (id, job_id, type, status, filename, total_records, processed_records, success_count, failed_count, status_message, error_message, created_by, created_at, started_at, completed_at) FROM stdin;
\.


--
-- Data for Name: lecturer_grade_otps; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.lecturer_grade_otps (user_id, otp_hash, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: lecturer_profiles; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.lecturer_profiles (user_id, department, expertise, bio) FROM stdin;
3	Khoa Công nghệ Thông tin		\N
4	Khoa Công nghệ Thông tin		\N
\.


--
-- Data for Name: majors; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.majors (id, code, name, description, program_duration, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: news; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.news (id, title, content, type, priority, sender_id, target_url, target_type, target_class_name, scheduled_at, sent_at, status, thumbnail_image, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: news_attachments; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.news_attachments (id, news_id, url) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.notifications (id, title, content, type, target_url, target_type, sent_at, created_at) FROM stdin;
\.


--
-- Data for Name: room_wifi_access_points; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.room_wifi_access_points (id, room_id, wifi_access_point_id, signal_strength, is_primary, position_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.rooms (id, code, name, capacity, building, description, floor, grid_row, grid_col, grid_row_span, grid_col_span, type, status, created_at, updated_at) FROM stdin;
3	A301	A301	70	Tòa A		3	\N	\N	\N	\N	THEORY	AVAILABLE	2026-10-18 15:22:01.78388	2026-10-18 15:22:01.783885
\.


--
-- Data for Name: schedule_requests; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.schedule_requests (id, requester_id, class_name, original_slot_id, requested_slot_id, requested_room_id, type, requested_date, requested_slot_number, reason, file, status, approver_id, approved_at, approver_note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: semester_configs; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.semester_configs (id, semester_id, max_slot_per_day, slot_per_subject_per_week, slot_duration, is_published, created_at, updated_at) FROM stdin;
1	1	5	2	60	t	2026-10-18 15:17:32.8687	2026-10-18 15:17:32.868713
\.


--
-- Data for Name: semester_weekdays; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.semester_weekdays (id, semester_id, weekday) FROM stdin;
\.


--
-- Data for Name: semesters; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.semesters (id, code, name, start_date, end_date, status, description, created_at, updated_at) FROM stdin;
1	FALL2026	FALL2026	2026-10-18	2027-01-15	ACTIVE	\N	2026-10-18 15:17:32.863834	2026-10-18 15:17:32.863847
\.


--
-- Data for Name: slot_types; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.slot_types (id, name, slot_index, start_time, end_time, description, semester_id, duration, created_at, updated_at) FROM stdin;
1	Ca 1 (Tiết 1-3)	1	07:00:00	09:25:00	Ca sáng 1	1	145m	2026-10-18 15:35:50.696947	2026-10-18 15:35:50.696947
\.


--
-- Data for Name: specialization_courses; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.specialization_courses (id, specialization_id, course_id, order_index, semester, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: specializations; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.specializations (id, code, name, description, status, major_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_attendances; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.student_attendances (id, session_id, student_id, status, method, check_in_time, face_confidence, wifi_bssid, wifi_rssi, note, updated_by_id, attempt_count, failure_reason, requires_manual_verify, manual_verified_by, manual_verified_at, captured_face_url, created_at, updated_at) FROM stdin;
1	38	2	PRESENT	QR_FACE	2026-10-19 07:59:12.226574	\N	AA:BB:CC:DD:EE:FF	\N	Điểm danh đúng giờ qua QR động & Face-ID	\N	1	\N	f	\N	\N	\N	2026-10-19 07:59:12.226958	2026-10-19 07:59:12.226961
\.


--
-- Data for Name: student_grades; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.student_grades (id, enrollment_id, grade_component_id, score, attempt, graded_at, graded_by_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: student_profiles; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.student_profiles (user_id, course, gpa, major_id, specialization_id, sub_specialization_id) FROM stdin;
2	K19	0	\N	\N	\N
\.


--
-- Data for Name: sub_specialization_courses; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.sub_specialization_courses (id, sub_specialization_id, course_id, order_index, semester, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sub_specializations; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.sub_specializations (id, code, name, description, status, specialization_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: system_logs; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.system_logs (id, action, description, type, source, ip_address, user_agent, old_value, new_value, performer_id, created_at) FROM stdin;
1	FACILITY_ROOM_CREATE	Tạo mới phòng học: E2E-R101 - Phong Hoc Thuc Nghiem E101 (Sức chứa: 60)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	E2E-R101	1	2026-10-16 07:51:18.71082
2	FACILITY_WIFI_CREATE	Tạo mới Wi-Fi AP: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	AA:BB:CC:DD:EE:01	1	2026-10-16 07:51:18.762124
3	FACILITY_ROOM_WIFI_ASSIGN	Gán Wi-Fi AP: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01) vào phòng E2E-R101	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	E2E-R101 <-> AA:BB:CC:DD:EE:01	1	2026-10-16 07:51:18.810608
4	FACILITY_ROOM_WIFI_UNASSIGN	Gỡ liên kết Wi-Fi AP: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01) khỏi phòng E2E-R101	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	E2E-R101 <-> AA:BB:CC:DD:EE:01	\N	1	2026-10-16 07:51:19.332299
5	FACILITY_ROOM_DELETE	Xóa phòng học khỏi hệ thống: E2E-R101 - Phong Hoc Thuc Nghiem E101	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	E2E-R101 - Phong Hoc Thuc Nghiem E101	\N	1	2026-10-16 07:51:19.405842
6	FACILITY_WIFI_DELETE	Xóa Wi-Fi AP khỏi hệ thống: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01)	\N	1	2026-10-16 07:51:19.429739
7	FACILITY_ROOM_CREATE	Tạo mới phòng học: E2E-R101 - Phong Hoc Thuc Nghiem E101 (Sức chứa: 60)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	E2E-R101	1	2026-10-16 07:51:42.22925
8	FACILITY_WIFI_CREATE	Tạo mới Wi-Fi AP: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	AA:BB:CC:DD:EE:01	1	2026-10-16 07:51:42.255332
9	FACILITY_ROOM_WIFI_ASSIGN	Gán Wi-Fi AP: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01) vào phòng E2E-R101	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	E2E-R101 <-> AA:BB:CC:DD:EE:01	1	2026-10-16 07:51:42.281686
10	FACILITY_ROOM_WIFI_UNASSIGN	Gỡ liên kết Wi-Fi AP: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01) khỏi phòng E2E-R101	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	E2E-R101 <-> AA:BB:CC:DD:EE:01	\N	1	2026-10-16 07:51:42.75014
11	FACILITY_ROOM_DELETE	Xóa phòng học khỏi hệ thống: E2E-R101 - Phong Hoc Thuc Nghiem E101	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	E2E-R101 - Phong Hoc Thuc Nghiem E101	\N	1	2026-10-16 07:51:42.788271
12	FACILITY_WIFI_DELETE	Xóa Wi-Fi AP khỏi hệ thống: UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	UniCheck_HighSpeed_E101 (AA:BB:CC:DD:EE:01)	\N	1	2026-10-16 07:51:42.809199
13	USER_CREATE	Tạo tài khoản người dùng: student_test (Họ tên: Nguyen Van Sinh Vien, Mã: SV2026001, Vai trò: STUDENT, Trạng thái: ACTIVE)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	User ID: 2, Username: student_test	1	2026-10-16 14:30:28.65173
14	USER_CREATE	Tạo tài khoản người dùng: lecturer_test (Họ tên: Giảng viên Kiểm thử, Mã: GV_TEST_001, Vai trò: LECTURER, Trạng thái: INACTIVE)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	User ID: 3, Username: lecturer_test	1	2026-10-18 15:08:13.360705
15	USER_STATUS_UPDATE	Thay đổi trạng thái người dùng lecturer_test (ID: 3): INACTIVE -> BLOCKED	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	status=INACTIVE	status=BLOCKED	1	2026-10-18 15:09:50.853947
16	USER_STATUS_UPDATE	Thay đổi trạng thái người dùng lecturer_test (ID: 3): BLOCKED -> ACTIVE	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	status=BLOCKED	status=ACTIVE	1	2026-10-18 15:09:53.107786
17	SEMESTER_CREATE	Tạo mới học kỳ: FALL2026 (FALL2026) từ 2026-10-18 đến 2027-01-15	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	code=FALL2026, name=FALL2026, status=ACTIVE	1	2026-10-18 15:17:32.877477
18	COURSE_CREATE	Tạo mới học phần: Lập trình Web (IT301) - 3 tín chỉ	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	code=IT301, name=Lập trình Web, credits=3	1	2026-10-18 15:18:09.738161
19	CLASS_CREATE	Tạo mới lớp học phần: IT301 cho môn Lập trình Web (IT301)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	className=IT301, maxStudents=30	1	2026-10-18 15:19:25.358325
20	ENROLLMENT_CREATE	Ghi danh sinh viên Nguyen Van Sinh Vien (SV2026001) vào lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	className=IT301, studentId=2, studentCode=SV2026001	1	2026-10-18 15:20:40.566964
21	FACILITY_ROOM_CREATE	Tạo mới phòng học: A301 - A301 (Sức chứa: 70)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	A301	1	2026-10-18 15:22:01.793649
22	CLASS_CREATE	Tạo mới lớp học phần: IT301.02 cho môn Lập trình Web (IT301)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	className=IT301.02, maxStudents=45	1	2026-10-18 15:25:52.675725
23	TIMETABLE_CREATE_SLOT	Tạo tiết học cho lớp IT301 vào ngày 2026-10-19 (Tiết 1) tại P. A301	AUDIT	WEB	127.0.0.1	\N	\N	1	1	2026-10-18 15:36:32.616897
24	ATTENDANCE_SESSION_CREATED	Tạo phiên điểm danh #1 cho lớp IT301 (slot #1, ngày 2026-10-19) trạng thái CREATED	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	CREATED	1	2026-10-18 15:38:46.745969
25	ATTENDANCE_SESSION_OPENED	Mở phiên điểm danh #1 cho lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	CREATED	OPEN	1	2026-10-18 15:38:53.166484
26	ATTENDANCE_SESSION_CLOSED	Chốt sổ phiên điểm danh #1 cho lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	OPEN	CLOSED	1	2026-10-18 15:39:03.464821
27	TIMETABLE_UPDATE_SLOT	Cập nhật tiết học ID 1 cho lớp IT301 sang ngày 2026-10-18 (Tiết 1)	AUDIT	WEB	127.0.0.1	\N	\N	1	1	2026-10-18 15:39:52.429417
28	ATTENDANCE_SESSION_CREATED	Tạo phiên điểm danh #2 cho lớp IT301 (slot #1, ngày 2026-10-18) trạng thái CREATED	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	CREATED	1	2026-10-18 16:13:20.183072
29	ATTENDANCE_SESSION_CREATED	Tạo phiên điểm danh #3 cho lớp IT301 (slot #1, ngày 2026-10-18) trạng thái OPEN	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	OPEN	1	2026-10-18 16:26:32.911825
30	ATTENDANCE_SESSION_CLOSED	Chốt sổ phiên điểm danh #3 cho lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	OPEN	CLOSED	1	2026-10-18 16:26:50.641758
31	TIMETABLE_UPDATE_SLOT	Cập nhật tiết học ID 1 cho lớp IT301 sang ngày 2026-10-18 (Tiết 1)	AUDIT	WEB	127.0.0.1	\N	\N	1	1	2026-10-18 17:00:14.225454
32	CLASS_UPDATE	Cập nhật lớp học phần: IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	maxStudents=30, status=ACTIVE, lecturer=Giảng viên Kiểm thử	maxStudents=30, status=ACTIVE, lecturer=Giảng viên Kiểm thử	1	2026-10-18 17:03:19.526131
33	ENROLLMENT_CREATE	Ghi danh sinh viên Nguyen Van Sinh Vien (SV2026001) vào lớp IT301.02	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	className=IT301.02, studentId=2, studentCode=SV2026001	1	2026-10-18 17:04:01.112667
34	TIMETABLE_CREATE_SLOT	Tạo tiết học cho lớp IT301 vào ngày 2026-10-19 (Tiết 1) tại P. A301	AUDIT	WEB	127.0.0.1	\N	\N	2	1	2026-10-18 17:04:30.939246
35	ATTENDANCE_SESSION_CREATED	Tạo phiên điểm danh #4 cho lớp IT301 (slot #1, ngày 2026-10-18) trạng thái OPEN	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	OPEN	3	2026-10-18 17:17:26.103404
36	ATTENDANCE_SESSION_CLOSED	Chốt sổ phiên điểm danh #4 cho lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	OPEN	CLOSED	3	2026-10-18 17:18:01.698773
68	ATTENDANCE_SESSION_CREATED	Tạo phiên điểm danh #37 cho lớp IT301 (slot #2, ngày 2026-10-19) trạng thái OPEN	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	OPEN	3	2026-10-19 06:34:16.740495
69	ATTENDANCE_SESSION_CLOSED	Chốt sổ phiên điểm danh #37 cho lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	OPEN	CLOSED	3	2026-10-19 07:03:09.708637
70	ATTENDANCE_SESSION_CREATED	Tạo phiên điểm danh #38 cho lớp IT301 (slot #3, ngày 2026-10-26) trạng thái CREATED	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	CREATED	3	2026-10-19 07:56:43.568634
71	ATTENDANCE_SESSION_OPENED	Mở phiên điểm danh #38 cho lớp IT301	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	CREATED	OPEN	3	2026-10-19 07:56:43.615791
72	ATTENDANCE_CHECK_IN	Sinh viên SV2026001 điểm danh PRESENT tại phiên #38	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711	\N	PRESENT	2	2026-10-19 07:59:12.233082
73	USER_CREATE	Tạo tài khoản người dùng: lecturer_test2 (Họ tên: Giảng viên 002, Mã: GV_002, Vai trò: LECTURER, Trạng thái: INACTIVE)	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	\N	User ID: 4, Username: lecturer_test2	1	2026-10-20 07:50:09.777175
74	USER_STATUS_UPDATE	Thay đổi trạng thái người dùng lecturer_test2 (ID: 4): INACTIVE -> BLOCKED	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	status=INACTIVE	status=BLOCKED	1	2026-10-20 07:50:41.865362
75	USER_STATUS_UPDATE	Thay đổi trạng thái người dùng lecturer_test2 (ID: 4): BLOCKED -> ACTIVE	AUDIT	WEB	172.19.0.1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36	status=BLOCKED	status=ACTIVE	1	2026-10-20 07:50:44.310782
\.


--
-- Data for Name: teaching_assignments; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.teaching_assignments (id, lecturer_id, course_id, semester_id) FROM stdin;
1	3	1	1
\.


--
-- Data for Name: timetable_slots; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.timetable_slots (id, class_name, room_id, slot_type_id, date, day_of_week, slot_number, status, note, created_at, updated_at) FROM stdin;
1	IT301	3	1	2026-10-18	7	1	SCHEDULED	Buổi học thực hành Lập trình Web - Ca 1	2026-10-18 15:36:32.609476	2026-10-18 15:39:52.431645
2	IT301	3	1	2026-10-19	1	1	SCHEDULED	\N	2026-10-18 17:04:30.836803	2026-10-18 17:04:30.836805
3	IT301	3	1	2026-10-26	1	1	SCHEDULED	\N	2026-10-18 17:04:30.846627	2026-10-18 17:04:30.846628
4	IT301	3	1	2026-11-02	1	1	SCHEDULED	\N	2026-10-18 17:04:30.854612	2026-10-18 17:04:30.854613
5	IT301	3	1	2026-11-09	1	1	SCHEDULED	\N	2026-10-18 17:04:30.863961	2026-10-18 17:04:30.863961
6	IT301	3	1	2026-11-16	1	1	SCHEDULED	\N	2026-10-18 17:04:30.870913	2026-10-18 17:04:30.870914
7	IT301	3	1	2026-11-23	1	1	SCHEDULED	\N	2026-10-18 17:04:30.879195	2026-10-18 17:04:30.879196
8	IT301	3	1	2026-11-30	1	1	SCHEDULED	\N	2026-10-18 17:04:30.885791	2026-10-18 17:04:30.885792
9	IT301	3	1	2026-12-07	1	1	SCHEDULED	\N	2026-10-18 17:04:30.896934	2026-10-18 17:04:30.896934
10	IT301	3	1	2026-12-14	1	1	SCHEDULED	\N	2026-10-18 17:04:30.903625	2026-10-18 17:04:30.903627
11	IT301	3	1	2026-12-21	1	1	SCHEDULED	\N	2026-10-18 17:04:30.912774	2026-10-18 17:04:30.912774
12	IT301	3	1	2026-12-28	1	1	SCHEDULED	\N	2026-10-18 17:04:30.919465	2026-10-18 17:04:30.919466
13	IT301	3	1	2027-01-04	1	1	SCHEDULED	\N	2026-10-18 17:04:30.926663	2026-10-18 17:04:30.926664
14	IT301	3	1	2027-01-11	1	1	SCHEDULED	\N	2026-10-18 17:04:30.933869	2026-10-18 17:04:30.933869
\.


--
-- Data for Name: user_device_tokens; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.user_device_tokens (id, user_id, token, platform, device_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: user_permissions; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.user_permissions (id, user_id, permission, granted_by, granted_at) FROM stdin;
\.


--
-- Data for Name: user_sessions; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.user_sessions (id, user_id, token, ip_address, province, city, latitude, longitude, login_time, last_activity_time, is_active, user_agent) FROM stdin;
1	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNWViMTBmMWEtZjYyNi00ZWI2LWExYWMtOTZlMDMwNTdmMTFiIiwiaWF0IjoxNzkyMTM0NjMwLCJleHAiOjE3OTIyMjEwMzB9.i3UWcsRQKWV33U2ZgfyVj6kWZfEZZpFBK00ixeKOfR8q3CaKcm8_cFkVfz_EbQ6e	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:10:30.175054	2026-10-16 07:10:30.175094	t	curl/8.21.0
2	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMmZjMTlhM2UtYWU4Ni00NDhjLTgwM2QtZDM5ODBkODIzYmJiIiwiaWF0IjoxNzkyMTM0NjM3LCJleHAiOjE3OTIyMjEwMzd9.DovqEP3iYel0ZvJ6mSKzrEZRWwLaYai6n83Bw_WFKpHuRSEFQKZW5HCgo-VOQYSy	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:10:37.594651	2026-10-16 07:10:37.594663	t	curl/8.21.0
3	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYzE2ZmNkZTgtZTI1Mi00MDUxLTgxNjctZjdkYzdhNDIzNThhIiwiaWF0IjoxNzkyMTM0NjQzLCJleHAiOjE3OTIyMjEwNDN9.RVr4q408UtPKwwtjIp-ZDGxbiFb8xkt9aauMm7W0-8Aeb1VCuZ45ulElgQuhUtSR	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:10:43.394223	2026-10-16 07:10:43.394235	t	curl/8.21.0
4	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNDNmMDQxOWItMTQwZC00ZjhjLWIyYTMtY2VhNmUxMzRlYzIxIiwiaWF0IjoxNzkyMTM1NTI2LCJleHAiOjE3OTIyMjE5MjZ9.cAjd6jlX1vtx30xaAyIHCORXWS8aqMNG0MJwxXKCN_6Gv5RTJIEkx91CE7zTa86p	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:25:26.428307	2026-10-16 07:25:26.428324	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
5	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYTgwNjc5ZTQtM2FjZi00ODVhLTk2NzQtOThkODkwMTNiMjJiIiwiaWF0IjoxNzkyMTM2ODU3LCJleHAiOjE3OTIyMjMyNTd9.tAFqh4W1meRs6Ec0gOpM16HO1OqrdX2p8mKJhZ5A0jWK0eubaOcfEcf-_moMzY61	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:47:37.436106	2026-10-16 07:47:37.436122	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
6	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMWU4MjJmNzUtYmY3Yi00NTdhLWIxN2EtMjY5ODI4ZjQ1OGEzIiwiaWF0IjoxNzkyMTM2OTEzLCJleHAiOjE3OTIyMjMzMTN9.Gdo4MQQYo8O9TdAHiflJrfyEvg-P4FHM69CENQaNh4UECa6-ojqXyTzNbkcRUv7e	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:48:33.080542	2026-10-16 07:48:33.080559	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
7	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNjhhYzJkYmMtNDJkOC00MzIyLWFmNDktZTViYWZjZDYzOGZlIiwiaWF0IjoxNzkyMTM2OTI3LCJleHAiOjE3OTIyMjMzMjd9.w-_OBBjLs4cWA-R0gzShC4gPxzkE7ADMDtT8YnmcGq933j8DerG6EtFdYuGthdok	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:48:47.649169	2026-10-16 07:48:47.649182	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
8	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiOTA0YzcxZTMtNTMzYi00NmE0LWEwMzEtOWEyMmIyMzY5MmMwIiwiaWF0IjoxNzkyMTM3MDE3LCJleHAiOjE3OTIyMjM0MTd9.btBc32kwKXqg-uTPiUNVQ99VruTrG0rfgr1XqOw-zq67P6qA8G1_9MOle-gtqrk1	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:50:17.889526	2026-10-16 07:50:17.889541	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
9	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZTY2NmRlNDgtZmIzZC00YzI0LWJiNzgtYmVjZGIwNjgxMTNlIiwiaWF0IjoxNzkyMTM3MDIyLCJleHAiOjE3OTIyMjM0MjJ9.cHAgaJl4OTHqkk9m9J54My_3OzQvDufQbpmOYUrJjXQIr9EbE9uu44rcb2QiZuhu	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:50:22.817757	2026-10-16 07:50:22.81777	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
10	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMDUyZDg0MDItNDA5My00ZTJkLWE2YzktNWE5OWRhNGFhMTRkIiwiaWF0IjoxNzkyMTM3MDQxLCJleHAiOjE3OTIyMjM0NDF9.Zg2v_IurfC5i1AYsSua6sx2zaLyKlJ-L8Syzda6TEkQCsicSfb3H7ArGfr21xVA5	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:50:41.033804	2026-10-16 07:50:41.033817	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
11	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNDRkMWIzMDctNjdhYi00NTlhLWEwYTMtNzZhMjMzZDVhMzBjIiwiaWF0IjoxNzkyMTM3MDUyLCJleHAiOjE3OTIyMjM0NTJ9.-DnR_pZXC5buZzT6RSP0j4HPApX8Ya9uYAF9jG6xLEupcYPV7B8NbktzLsZi2lUp	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:50:52.677815	2026-10-16 07:50:52.677848	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
12	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMTQ4MjlmNDItMDcyMS00ZGYxLWE3ODEtZmUxODI5MDM0YjhhIiwiaWF0IjoxNzkyMTM3MDc4LCJleHAiOjE3OTIyMjM0Nzh9.-OrT_ycT8cS6lvELVMTk-GRvsOshvGvQGHNjCldkDuXw-qPqT_-2qOPyHhy6t-p7	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:51:18.628896	2026-10-16 07:51:18.62891	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
13	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYjA0M2Y4YTQtMDZkMS00NjU0LWE2NjEtMjlmMjNmNWNjNTJkIiwiaWF0IjoxNzkyMTM3MTAyLCJleHAiOjE3OTIyMjM1MDJ9.HujMaGbl1IchjeJtflqs4ffVQf-MBraQkc_RkD80cE2_1f_xEKzIjWF-PNHXgT9J	172.19.0.1	\N	\N	\N	\N	2026-10-16 07:51:42.161664	2026-10-16 07:51:42.161678	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
39	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMzVjZmFlMmMtMjYwNC00MTQ3LTg2MmUtN2M4ZTQyNjczNjc3IiwiaWF0IjoxNzkyMzM3MTQ3LCJleHAiOjE3OTI0MjM1NDd9.aDXC_Ca1StF8HAaVxdMbZc-3UrNJhWMpFLA0-U0m--wsS53zul8FbIfIGQzbv6Ry	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:25:47.694172	2026-10-18 15:25:47.694176	t	curl/8.21.0
79	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjJlMTc3NjMzLTYzYzMtNDBmNS05ZTcyLWRiZjYzNzNlMDQ5OCIsImlhdCI6MTc5MjM5OTEwNCwiZXhwIjoxNzkyNDg1NTA0fQ.-nTPDhDy0e7Wts2UFH6hg1pZ_pGEC2473cf0_-Uq2qMNeq7-lkmog8DEOCxA38-V	172.19.0.1	\N	\N	\N	\N	2026-10-19 08:38:24.649914	2026-10-19 08:38:24.649919	t	Dart/3.13 (dart:io)
15	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMzlhZDI2NjYtN2FkYi00ODZiLTgwOWUtMmMxZmM2MmZlMTYzIiwiaWF0IjoxNzkyMTYwOTgxLCJleHAiOjE3OTIyNDczODF9.PsIIDI4I0nVO5LRJKBYGXCtAXtU93RiP0Yy55qqvMGh5BIMsVocorEztxIMABD21	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:29:41.827185	2026-10-16 14:29:41.8272	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
16	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYzM0YmU0YzEtYTUwYi00MWY3LThkN2EtMzVmOGRhYWYwMjVjIiwiaWF0IjoxNzkyMTYxMDA2LCJleHAiOjE3OTIyNDc0MDZ9.U6SHVmFKnJeNz-Uxu9fZZKt6-e1iy3PPtnou3k3ZrJwwIBpoXKmgOEYvRKeGpA8i	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:30:06.448659	2026-10-16 14:30:06.448671	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
17	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYmNhZmIwYWEtZTMwNi00MDA2LWFjY2ItYTc4YjQyYzRkMjU5IiwiaWF0IjoxNzkyMTYxMDIxLCJleHAiOjE3OTIyNDc0MjF9.nJ8nwMJFfV2ato6qT83SoCr9jO8OrgKRmAcyBS3UCdfdqijwdjbdKFJlZ9l5HufC	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:30:21.366664	2026-10-16 14:30:21.366734	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
18	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYTgzNTU5MzYtYjRkYS00MmUwLTg3YjQtOTBiZmRmYWJjNTViIiwiaWF0IjoxNzkyMTYxMDI4LCJleHAiOjE3OTIyNDc0Mjh9.zWNb7ImacCuzBp9EMGdHbtpInDaxqwlvaOctnVBbLoal7_0YZsM_JhrJlD25ss8y	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:30:28.490583	2026-10-16 14:30:28.490603	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
19	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjljYTBkMTVmLTU3NzAtNGI1Ny04MmRhLTZkMGQzMjJjZGQ4YyIsImlhdCI6MTc5MjE2MTA1MSwiZXhwIjoxNzkyMjQ3NDUxfQ.80Yxhmp0h7a2F8eww1nt_nbhk_WbiDx2p8J_UrRxsGtOeezkrd49rRNRKmhEPdjc	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:30:51.345381	2026-10-16 14:30:51.345411	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
20	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjBkNzE0YmExLTBjYjEtNGU5Ni05NDczLTVhYWI0NDg2OGNmYiIsImlhdCI6MTc5MjE2MTA1MSwiZXhwIjoxNzkyMjQ3NDUxfQ.7vyO8GmxL8FSu-uZ4fBN0uVH1Qg08oEas_fRSB4hXz_2TqsW9Od7wIpsHgwybXjE	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:30:51.438753	2026-10-16 14:30:51.438765	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
21	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjIyYjU0MThhLTZiNDktNGIzZS04MTU3LTkzYWRmN2YzZDQxZSIsImlhdCI6MTc5MjE2MTA2MCwiZXhwIjoxNzkyMjQ3NDYwfQ.laPqvO_heeO5EwadWh-uzWz6V02IXcVVLKO46jx3nWcEVXJFYizQJU78GxFDbANf	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:31:00.703149	2026-10-16 14:31:00.703161	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
22	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjU5MmUyNzU1LWRiMWYtNGMxNi04YzBmLWRkY2E1ZjkyNmNhYyIsImlhdCI6MTc5MjE2MTA3MCwiZXhwIjoxNzkyMjQ3NDcwfQ.qUO6TVec-TaJ4OeiUHCN9AvcQyY_Ls8toIcit1f0MeaLRKQ0WEon5rSflWv7vs4s	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:31:10.380664	2026-10-16 14:31:10.380676	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
23	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjM3MDkxN2ZhLWEwZjUtNGRjMi05MTkxLTRiODlmZTE2MzZiMyIsImlhdCI6MTc5MjE2MTIxMSwiZXhwIjoxNzkyMjQ3NjExfQ.4YZMDNQt_QRHo3NyDF8aezTsmEeaiSJZ2NjQISDak0EsBYeqy4ZjseBaLt-bPLNR	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:33:31.551722	2026-10-16 14:33:31.551738	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
14	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiY2EyMGIxNjEtMWRlYi00YmMxLTk3YWYtZWZiMmYzMWY0NTdjIiwiaWF0IjoxNzkyMTYwNDg3LCJleHAiOjE3OTIyNDY4ODd9.EBXz7rnG8fqi-cJPkFH24U10LYj7_eueIwcGuMpniwqosj17u8Qwg_gQ-ueVLru1	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:21:27.174907	2026-10-16 14:35:22.648496	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
24	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjU3MjVhZGNkLWQzNzItNGIzMS1hMWVhLWNkYTc5MDI5ZDE1NCIsImlhdCI6MTc5MjE2MTMzMiwiZXhwIjoxNzkyMjQ3NzMyfQ.WPUThk59KgThHiAgPPzo0BHmDmqKLdH53FM6vBV3o7gbVKOyQa_lGv3tv7S6B7bW	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:35:32.978641	2026-10-16 14:35:32.978668	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
25	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjY5M2Q5OWFhLTk3Y2EtNGM1OS1hMjQyLTRlNDMzYTc1ODBmNyIsImlhdCI6MTc5MjE2MjQ3MiwiZXhwIjoxNzkyMjQ4ODcyfQ.jSAQDkOBnIyu-X3kuNnQFItrP1jOQLR3BiKtt7JRjyIkiM7lRI6h2FZlTYaQ-_LY	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:54:32.145783	2026-10-16 14:54:32.145798	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
26	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjY1Y2VkM2E0LTM3ZmEtNDc2MS04MzJmLTU2MDNjOGQ1MWQ2ZiIsImlhdCI6MTc5MjE2MjQ4OSwiZXhwIjoxNzkyMjQ4ODg5fQ.lVyt4in9MbYzZbHcVh4W8jhgRGTtfPnlRUCeEgDLO4GuGtnmLfMlIPwGNwt-wW8G	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:54:49.955471	2026-10-16 14:54:49.955485	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
27	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjE4YjAyNjFjLTJjMjEtNGFmMy05NmY0LTAyYzExZjZlNDZhNCIsImlhdCI6MTc5MjE2MjUwMywiZXhwIjoxNzkyMjQ4OTAzfQ.nNrcVziALK1W0uIXDt7REwsdntL8LDSX4XvisG7gID0IFzEkBIaAFasSHBzYzvyZ	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:55:03.057413	2026-10-16 14:55:03.057428	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
28	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjY4MzQzODM4LWZhZWEtNGVlOS1iZTExLTA0MDhhZGVjYTM0NyIsImlhdCI6MTc5MjE2MjU0MiwiZXhwIjoxNzkyMjQ4OTQyfQ.RjQkATGdNQFgbn17aohFwo-uMitFpDzW3qqWGGDuGohTV-z_i0KA06Qso3yGdqLu	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:55:42.236188	2026-10-16 14:55:42.236203	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
29	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjIzODU2N2JhLTc1NTktNDA4OC1iMjgyLTNhYWU3OGY1ZGY3ZSIsImlhdCI6MTc5MjE2MjU1NSwiZXhwIjoxNzkyMjQ4OTU1fQ.X1Ow9LBEdzymR914kbQ8d4ZclSzUyk8aIiYba3g8jq6PxkeWeE_rC3XIY8sb9ty_	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:55:55.218863	2026-10-16 14:55:55.218895	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
30	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImI3N2FlNDE0LTk1MmUtNDMwZS04OGU4LWYxODdlOTFkNjY3ZCIsImlhdCI6MTc5MjE2MjU2NiwiZXhwIjoxNzkyMjQ4OTY2fQ.7z_Al-qLvuu4BlZ2nxVQSEe9wKKjo_cZaFPDtbRtOoBxm4HaMyKtGgDqFXgJpHC8	172.19.0.1	\N	\N	\N	\N	2026-10-16 14:56:06.302366	2026-10-16 14:56:06.30238	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
31	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZGU3ZDljNGItZmUwYi00YTZjLTg4M2ItZWFhNGRlZDA4OTA2IiwiaWF0IjoxNzkyMzM2MDIxLCJleHAiOjE3OTI0MjI0MjF9.Nh6oGRYr9au8vEcArHPnYg7c0VAmvytopL0hhrQXrG-WEl9mYi_9_wkqc5uBUH7u	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:07:01.694696	2026-10-18 15:08:20.938052	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
32	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMGFlY2FlNTgtOGY4OS00MWJjLTllOWItNjYyZjNjNDI5MGE3IiwiaWF0IjoxNzkyMzM2MTMzLCJleHAiOjE3OTI0MjI1MzN9.eUJGObfzLCCZWoM9SwuKF073zImQxwOfxqmGHI6eFVrpbsDTjhyuKhMeg65XWLYN	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:08:53.128367	2026-10-18 15:10:00.154886	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
35	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNDMzNTUxZTAtMTYxMi00N2Y0LThiMWUtZDc4MDEwMWU1NzRhIiwiaWF0IjoxNzkyMzM2Njc3LCJleHAiOjE3OTI0MjMwNzd9._BHmZgWjiS1oNN16AtNMo6bu4oYcZs8cGv7-w-uKS21c1JMuWBE7BMQjGhyMO4Yt	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:17:57.389293	2026-10-18 15:17:57.389338	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
36	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMjYxNTEzMDQtY2VhZC00YTg4LTgwMjEtYjc5YTQxNGNkMTVmIiwiaWF0IjoxNzkyMzM2NjgzLCJleHAiOjE3OTI0MjMwODN9.M8EPR2R7BN1joS6s8Y5UxnhOyGQb12O8kbo6FNFe1ONkYGI8_pghpX8gaOG8e37o	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:18:03.797821	2026-10-18 15:18:03.797834	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
37	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiN2U2YWE1ZWEtZTI3MS00ODY5LWExODUtNTA1OTliYWM3MzBiIiwiaWF0IjoxNzkyMzM2NzY0LCJleHAiOjE3OTI0MjMxNjR9.dfRCf0NUwFu-aCvVVg-Q4Bwd1ZAYKh-HUK94Ykf-ucyJi7Y6rMk4yHw0K9d4czD2	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:19:24.931246	2026-10-18 15:19:24.931252	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
33	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNGYxYjE3YmEtZjkxYy00MWEyLThlZDgtMmEzYzBlMDI3ZDI1IiwiaWF0IjoxNzkyMzM2MjA4LCJleHAiOjE3OTI0MjI2MDh9.T0KG33Me1A8e24OshomLqEGKTqBq7FkdDW5RH5JjuQF1Ln-Si4PzvSM4f0OlU7Y7	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:10:08.866957	2026-10-18 15:20:13.533039	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
34	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYmVhZDVmNDUtMmZjNy00ZjcwLThkNzMtOTg0MzAxYjhmYTE3IiwiaWF0IjoxNzkyMzM2MzMxLCJleHAiOjE3OTI0MjI3MzF9.88BAa2kZj7ucSbdElAZH4bAYPPZpZAuVMtJFIJCUD0lg_saJrNef7axYexrAY_OI	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:12:11.395989	2026-10-18 17:00:59.469255	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
38	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjdkYzcwMjQ0LTMwZjEtNDY0OS04YjI1LThhOGE4ZGE0ZWQ3MiIsImlhdCI6MTc5MjMzNjgxNSwiZXhwIjoxNzkyNDIzMjE1fQ.pzO4rK-gqN2Rorfp66Vl6TaSNcXdoimGRtw2F6XW8ms8upZ7lnSbpHLJ0zhbMfy3	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:20:15.736901	2026-10-18 17:02:42.895525	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
40	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMDAxZTU5Y2EtYjAwYi00NzU0LTg3MmEtNGRkOGM0YzBkZTcxIiwiaWF0IjoxNzkyMzM3NzcxLCJleHAiOjE3OTI0MjQxNzF9.UExZcb-OSMjwG275De6Lor2ubNRDCyBnuHMpUdHgY93OxHskt-6AGF7X2vXS0bBT	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:36:11.869469	2026-10-18 15:36:11.869473	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
41	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNzg5ZWU5YTctNmU2Yi00NTljLThkYTktMDVlYTE5NDA3OGFjIiwiaWF0IjoxNzkyMzM3Nzg1LCJleHAiOjE3OTI0MjQxODV9.EDIyLqleSnCW5jGD_UfLgjqXSTuNWRx97DT7wY3Oj3CjsEe2m3Ob_ttrKZSf9Dgv	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:36:25.703876	2026-10-18 15:36:25.70388	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
42	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMzkwYzI2MDAtNzg5NC00N2E3LWIwZjctMmM5YWZmZWZlNTBjIiwiaWF0IjoxNzkyMzM3NzkyLCJleHAiOjE3OTI0MjQxOTJ9.U-PnCtkTrvbpqyj8YbOUFV1ePbtnSoUl5HOaY9YvDAQhxT-NFL449AxXtBlc4g7h	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:36:32.539372	2026-10-18 15:36:32.539376	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
43	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMTMwZjNkYWUtMjAwMC00ZTZmLWIxMzItNGM3ZGEwYzk1MDYyIiwiaWF0IjoxNzkyMzM3ODEwLCJleHAiOjE3OTI0MjQyMTB9.VtMMBPu4752mO8LzacIGmFk3hYHEgCIy9VVoW1Kf1D6wltEmFAwIJCmv5_3JgSmm	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:36:50.663573	2026-10-18 15:36:50.663577	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
44	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMTJiOWNjOTgtNmJjNy00ZGRjLWI5MzgtYmE3NzhiOWNhMmQwIiwiaWF0IjoxNzkyMzM3ODIwLCJleHAiOjE3OTI0MjQyMjB9.7T73A4fQr1OTyY4w2d7IkYecGdEhDuWXv7hxU25Xlj7Kgh502cTIIJZGgX9CNBUt	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:37:00.051113	2026-10-18 15:37:00.051118	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
45	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMWYwMzg1NjUtY2NiNS00YzYzLWEwMWMtYmNjOGRkNzc3MWE2IiwiaWF0IjoxNzkyMzM3ODMxLCJleHAiOjE3OTI0MjQyMzF9.98VavVkm3xVisEZYoRa86z9viT2mC9Th-tOaPsTN1f4tgkf89HaekXHtjtVU6rdC	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:37:11.618375	2026-10-18 15:37:11.61838	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
46	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYWIxMDNmODYtZWMwZS00M2UwLWI3ZmItZDg5MjlhZjA4MWM1IiwiaWF0IjoxNzkyMzM3ODM3LCJleHAiOjE3OTI0MjQyMzd9.FqOwHEhrvFSH1WUuH5O_6YctvnwWmKuuwdiwYI70Sl4xwhOTTw528X_8QwGhomIH	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:37:17.198169	2026-10-18 15:37:17.198172	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
47	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiODczNmQ3ODUtNmY1My00M2I3LWI5NTYtNTY4NTQ3MDE3NGQ5IiwiaWF0IjoxNzkyMzM3ODQ1LCJleHAiOjE3OTI0MjQyNDV9.sUWAbxLVO_A2UiO8mwb6cVldTfkq7nAb9oLe7k1qpxTZ2v3T0mbcuKJ6sloh71yP	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:37:25.811642	2026-10-18 15:37:25.811648	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
48	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMWQxMWRiMDgtMjNkMi00NzQ1LTk1NGEtOTcyMjc2ZmE4YWJiIiwiaWF0IjoxNzkyMzM3OTI2LCJleHAiOjE3OTI0MjQzMjZ9.wZC_M-SXjgI7BPd20eoMM1fmh1stJ4IzSFQWMIrc-OXFrnJyz9eqpQhsXrdzm8Vb	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:38:46.593287	2026-10-18 15:38:46.5933	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
49	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiOGIyM2ZhZjMtYzVhYS00YWFmLTg5YjctNDEwMmNmZmZiMGZmIiwiaWF0IjoxNzkyMzM3OTMzLCJleHAiOjE3OTI0MjQzMzN9.F3NsCVmNFf9lFNk_gwMbk7jAwfOyujqVoUuRtlxDX2bwFnMVw2n1EPzp-H0qs9kt	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:38:53.126884	2026-10-18 15:38:53.126893	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
50	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMGM0MGM3OGUtMDdiYS00YWYwLWFkZjAtYTE4YjFjNWUwODQxIiwiaWF0IjoxNzkyMzM3OTM4LCJleHAiOjE3OTI0MjQzMzh9.tgiam3hrN4de1QCNEdii4xS-hq5QjNHD54j8mhOotcBGgYNX_QM0HX-2Dj7bgId0	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:38:58.556951	2026-10-18 15:38:58.556958	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
51	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYmE2NzE5MDEtZTFiNC00ZDYyLTlkN2QtOWM4YTllOGY5NGVjIiwiaWF0IjoxNzkyMzM3OTQzLCJleHAiOjE3OTI0MjQzNDN9.7zQw3b5TGjjU1Bi6X6fsNAh241PU812nm-XDD9pIx139hClT50mPUDSqhWGxpfjL	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:39:03.428795	2026-10-18 15:39:03.428809	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
52	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiN2Y1YTdmMDItZTQyYy00MTc1LTk0ZTktY2IzMzY2YzA3ZDZhIiwiaWF0IjoxNzkyMzM3OTY5LCJleHAiOjE3OTI0MjQzNjl9.J0RqkctY7Nl8hT0peSBe_ecy3q_CRCecCFH1tTbQfKljFI2ZSy2gvr3I5iiBLd-x	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:39:29.821903	2026-10-18 15:39:29.821915	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
53	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYWU2YzYzYWMtNjQyNy00MWE3LWJlOTMtZDNlNjMxMGJmMzQ3IiwiaWF0IjoxNzkyMzM3OTc3LCJleHAiOjE3OTI0MjQzNzd9.KrDzzZnTJGsmwuixgzFJmMXquQi8zZDNf3tfBxdzDuuePOi01_1hlFKx336RRJNU	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:39:37.347685	2026-10-18 15:39:37.347691	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
54	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYTVlMjg1NzgtMzdhYi00NjZlLWI0YmMtMWYyZmJjNDViY2NhIiwiaWF0IjoxNzkyMzM3OTg0LCJleHAiOjE3OTI0MjQzODR9.mn-eBPfVrWdn7Ll40SX4TRB6w-AlrOYtFujBLyz-qVwAZ7cGwZw5mnn82VEvCC54	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:39:44.25471	2026-10-18 15:39:44.254715	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
55	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZDRkMDM0NmYtZGU1Yy00YmRkLThkYTItMTQ1ZTRkNDEwNjFiIiwiaWF0IjoxNzkyMzM3OTkyLCJleHAiOjE3OTI0MjQzOTJ9.GYmVSWWbWbGL1OJrZf0Js-NZ6oZaRzvGAtWslOfmmitOHkI3QQPTg_ZJdZwIfrkO	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:39:52.356172	2026-10-18 15:39:52.356183	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
56	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiM2VmYmI4MzQtZDdmYi00ZWQ3LTgxNTctYTk4OWE4NTEwNTU2IiwiaWF0IjoxNzkyMzM3OTk3LCJleHAiOjE3OTI0MjQzOTd9.c4jSZoA1MVOj0so9ffw1eu89B6pijjUiyojfd4NzO3ZXc1SxPCEe7WzkcQvzGZWU	172.19.0.1	\N	\N	\N	\N	2026-10-18 15:39:57.040598	2026-10-18 15:39:57.040601	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
57	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMDhlMzYyYmYtNTYwZi00YWQ3LWJmMGMtZTI0MzBlOGY0YTFjIiwiaWF0IjoxNzkyMzM5NDQ2LCJleHAiOjE3OTI0MjU4NDZ9.vWbB840kG2lEdoIpwjufprY_6GKNhVBkS06oBiusLpZUu54kVxnraIwNn3pzJnUT	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:04:06.278734	2026-10-18 16:04:06.278738	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
58	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNzgxYThlZDQtNWMzYS00ZjY4LWJjMTUtN2I2OTEzODVkNjE3IiwiaWF0IjoxNzkyMzM5OTY0LCJleHAiOjE3OTI0MjYzNjR9.iZiI3YGTlH5Cmtimqt6TirI5zLktDG0syQsUt9LMwe2hMDlbDiUfzCHT6YBKwTyJ	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:12:44.430512	2026-10-18 16:12:44.430524	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
59	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiN2RmZGFlZjUtZmI5MC00YjU3LWFlMDktMTA4MGYxZTE3ODk3IiwiaWF0IjoxNzkyMzM5OTkyLCJleHAiOjE3OTI0MjYzOTJ9.HlEb0CSGMaC1iv7g08IlxJbkElpPo7lgFX2VIUEYPU1BTeBqd3zQv2f13Q1adlMD	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:13:12.137619	2026-10-18 16:13:12.137633	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
60	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiOWIwNzEyMjUtMGI4Ny00MzE0LWEzZGItY2Q4MWViODE4NTJhIiwiaWF0IjoxNzkyMzQwMDAwLCJleHAiOjE3OTI0MjY0MDB9.8bXJcuMFFhOZTZdpXV36hCCsWs1uqkrVwNMNlVDq5ujvUO8tfCfDUYFkpBDifNYI	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:13:20.140852	2026-10-18 16:13:20.140865	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
61	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNWNhM2ZlNzYtYWRjNS00YjljLWI4NzctNDdkZDk5ZjY2YmIzIiwiaWF0IjoxNzkyMzQyMjA5LCJleHAiOjE3OTI0Mjg2MDl9.3r0P97PnJWeVlSmrulQhI61cvPZPOihuEWS06WyN6ECiku1kdibNunJrk6aXG9M4	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:50:09.688844	2026-10-18 16:50:09.688845	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
62	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNDc3MTgzZDgtYTMzYy00NDI5LTgyMTktYjdlYTIzYzg2ZmIxIiwiaWF0IjoxNzkyMzQyMjE2LCJleHAiOjE3OTI0Mjg2MTZ9.yVITvfzD_to6gaTZ-EK4DAnH3irXGq_VaGUzPLz39B_W8jq2H6j2_rdMVRsgkBa5	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:50:16.838764	2026-10-18 16:50:16.838765	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
63	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiN2Y5MTMzNGEtOWQzYi00YWViLTkyZjAtMTE3ZDQ3YTc1OWM0IiwiaWF0IjoxNzkyMzQyNjU0LCJleHAiOjE3OTI0MjkwNTR9.US2sH5Xlky0WHwCUjvF8wYCVfdnuNHfL6Z6_B-C8F268fgeIxijRuW3HqxsMgNB6	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:57:34.164965	2026-10-18 16:57:34.164966	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
64	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMjRkMTk0ODAtY2M1ZC00OGZiLWFhMjYtYWJmMmZjODFkNWZkIiwiaWF0IjoxNzkyMzQyNjk5LCJleHAiOjE3OTI0MjkwOTl9.gmeuxyGjtHhxdD0aNG4Lj9knsXDPiznRZDNQ0pQ4LbvNXf_AsBaEfOstO-oKRwEh	172.19.0.1	\N	\N	\N	\N	2026-10-18 16:58:19.402175	2026-10-18 16:58:19.402203	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
65	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYjUxNDE5MTctN2Y2ZS00N2JmLWE2Y2YtMjJlMWE2MThkODNhIiwiaWF0IjoxNzkyMzQyODYxLCJleHAiOjE3OTI0MjkyNjF9.xzXTfPGZRrLow_NMD3VwpFb1-rlZuDzzJ4SqWeOFkZ4wIQjSdg0GC4CTGZJalBf8	172.19.0.1	\N	\N	\N	\N	2026-10-18 17:01:01.763351	2026-10-18 17:01:35.103419	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
66	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNzU0NzM4NGMtOTFjNi00ODhiLWJlOWMtYWUwNGRkOGEyOGQ0IiwiaWF0IjoxNzkyMzQyODk3LCJleHAiOjE3OTI0MjkyOTd9.fnMxSrzQt_b8GCjVRwhqXrrJs65C_jisq9_O3lrt2hYRg9e3sikIvFp6faRzD7ZK	172.19.0.1	\N	\N	\N	\N	2026-10-18 17:01:37.393976	2026-10-18 17:01:37.393977	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
67	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6Ijc3YTY4MzA1LWY2OGUtNDljYS1iNTgzLTk1YjViMDVjNzcwYiIsImlhdCI6MTc5MjM0Mjk0NiwiZXhwIjoxNzkyNDI5MzQ2fQ.9C1utOWDbTCwW7ou5JL800yH-BP5sBdIib6bIgQMzdozGhy0r35b5Q3kM0idreGf	172.19.0.1	\N	\N	\N	\N	2026-10-18 17:02:26.392486	2026-10-18 17:02:26.392487	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36 Edg/155.0.0.0
68	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiOTk1OGI0N2YtYTM0NC00YzM0LWIyMzQtYjM1OGMyOWVmNDcxIiwiaWF0IjoxNzkyMzQyOTY1LCJleHAiOjE3OTI0MjkzNjV9.VBPGfzAEY1fqjqFzlCdptOPn8J48hJteMHV0bPZh2iGDONW8uvBklD_7qD-49UcV	172.19.0.1	\N	\N	\N	\N	2026-10-18 17:02:45.939454	2026-10-18 17:02:45.939455	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
70	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYTZlMmY0MWItMGE5ZC00YmExLWJiNzItNmU5YWQ3Mzk4OWEwIiwiaWF0IjoxNzkyMzk2NTIyLCJleHAiOjE3OTI0ODI5MjJ9.d5XFwEEPctRxQekobZO4mrk3ZJ7sg0dEp4wzk2C9BPeFDq3gIoXOSJbg5p7cnj0U	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:55:23.011456	2026-10-19 07:55:23.011469	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
71	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImJlYjcyM2JmLWE2NDEtNDIwNi1iZjljLWJmZDIzOTFkMjA1OCIsImlhdCI6MTc5MjM5NjUyOSwiZXhwIjoxNzkyNDgyOTI5fQ.D7Ctc4hkN9wrGrAdZMNmF7bfhuaxEraQ8WazXIBizYD3qzjDuxoV9GbxAMJy4agy	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:55:29.491779	2026-10-19 07:55:29.49179	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
72	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjVlYmVkNDE0LTg1N2EtNGI3OS04NmJiLTNiYmE5N2ZhMDQ2NSIsImlhdCI6MTc5MjM5NjU1OSwiZXhwIjoxNzkyNDgyOTU5fQ.pIi0Shp1T6TZTaJIW7ejtoKFUFEOxtWCAlBXQrdY8l0q-HPw5tnVKqRKZ9Ajk834	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:55:59.271618	2026-10-19 07:55:59.271631	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
73	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjQ0OGExYWQzLTczNjctNGYyNy1hYjMyLTVkYTNmODMzOGFkZiIsImlhdCI6MTc5MjM5NjU4MCwiZXhwIjoxNzkyNDgyOTgwfQ.Lsjoa25fdeR-erfv_ka2mvREeCPuDECYPkuPNx_rkW4b7oCJxP7uaTuTSNDASbCN	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:56:20.592149	2026-10-19 07:56:20.59216	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
74	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNmFlYjQ5ZGYtNjhhYS00NGFhLTgyODUtYTJhNThjOGU1MDYwIiwiaWF0IjoxNzkyMzk2NTgwLCJleHAiOjE3OTI0ODI5ODB9.EyM1k0MM0azZ61ktUI_1ckJvgJoiaz4rLIYkCiWd4ODlTITAf2UqdXftx_LF2eiV	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:56:20.666272	2026-10-19 07:56:20.666283	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
75	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYzI2YzM3MDAtODZjMi00YTEzLTk2MjYtYmE3ZTNmYzE4NWI3IiwiaWF0IjoxNzkyMzk2NjAzLCJleHAiOjE3OTI0ODMwMDN9.51IuvHq6IIrDtlLCEzIgALqp2dtW5VIDVI4CdXbEiQhCY1hvZyfglBxd0MCJTglo	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:56:43.351383	2026-10-19 07:56:43.351394	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
76	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjdkOWE0NDdjLTlmZDMtNDRkZC05ZTBmLWMwY2E1Njk4OGZlMyIsImlhdCI6MTc5MjM5NjYwMywiZXhwIjoxNzkyNDgzMDAzfQ.2ueP1v0OESDNOAFzniwXgaEZMFeJwvB_o_jOzzPa87FftNPkCCplQzA0QsMCaqNv	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:56:43.730465	2026-10-19 07:56:43.730472	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
77	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNzdlZGZiMDctODNhZC00Y2ZkLWFmZWEtNGEzYTc0NGZhNjRlIiwiaWF0IjoxNzkyMzk2NzUxLCJleHAiOjE3OTI0ODMxNTF9.0UIvc28qwG_wlghgxcP1aTfeoYbs1PqytY44pqIijw2-uOQPgOp5HZzEpDoP_w3i	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:59:11.889354	2026-10-19 07:59:11.88936	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
78	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImQwNGVkODE2LTE4ZWMtNGQzZC1iNWYzLWM5OTJmNWE3ZDk2NyIsImlhdCI6MTc5MjM5Njc1MiwiZXhwIjoxNzkyNDgzMTUyfQ.6HwIe7ttR6VsuCRo2GRSEMyvOLiFR4snOiTJgMGNtjNSvEsvQOmJgH1q9Kp7bDn8	172.19.0.1	\N	\N	\N	\N	2026-10-19 07:59:12.009434	2026-10-19 07:59:12.009441	t	Mozilla/5.0 (Windows NT; Windows NT 10.0; en-US) WindowsPowerShell/5.1.26100.9711
69	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNzk1NDdmOGUtNjVjMS00NzZkLWJiNDYtODU2NWU2ODNhMzQyIiwiaWF0IjoxNzkyMzkxNjM1LCJleHAiOjE3OTI0NzgwMzV9.KCG6YgJ9SYzjmcMVXQ0QMLe_OU-wkksdawUK8s0Ohpmdi_-HGUkq1jXkNURmBcwB	172.19.0.1	\N	\N	\N	\N	2026-10-19 06:33:56.065214	2026-10-19 08:38:14.947808	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
80	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMDYyOTUyMzEtNzM3Ni00ODM2LWIxZmMtNDk3ZWI1MDE3NDBjIiwiaWF0IjoxNzkyNDc4NTAxLCJleHAiOjE3OTI1NjQ5MDF9.b3fVxfVOTcqKwKhd5gYsAJypsUorRPe9YbonslGeLBv742zRgOQp2rFvVzYUFOXG	172.19.0.1	\N	\N	\N	\N	2026-10-20 06:41:41.518391	2026-10-20 07:40:20.3799	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
81	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImQ4YTM2NTcxLTU3NmYtNGVmOS04ZDRiLWM3ZTYzZDcxM2QzYSIsImlhdCI6MTc5MjQ4MjA0MSwiZXhwIjoxNzkyNTY4NDQxfQ.X-NdzEPsTyTIJzKvAcZ3uWqXOurkKS_Qox3GT8TZtNENySiFH6_Ggwa-Nwi1bZih	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:40:41.378195	2026-10-20 07:40:41.37821	t	Dart/3.13 (dart:io)
82	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImI2MWU5YTRlLWExOGItNDhmYi05MmIyLTEzZTk4ZGYxOTkzYSIsImlhdCI6MTc5MjQ4MjI2NiwiZXhwIjoxNzkyNTY4NjY2fQ.ivT-IR5WoGbHObBE7kkuSiv2mtfXnfKOox1JINJEMtTxB3ljhZASD13yKsA9eFbX	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:44:26.861003	2026-10-20 07:45:34.232773	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
83	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjFiMDFlNTQxLWNkNzktNDNjZS05OWIzLTU0Zjg4MjU0YjliYyIsImlhdCI6MTc5MjQ4MjMzNSwiZXhwIjoxNzkyNTY4NzM1fQ.UxbRBh0lnW_oK-NC0L-DW209cOh3DbwHji5u7yqdU---PSF8Mlf4mYfu_SDRyjif	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:45:35.931687	2026-10-20 07:45:50.476669	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
84	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMDIwNzA4NjctZGYxMC00ODNmLThlMmUtMDE4MDQ2MDQ5MDc0IiwiaWF0IjoxNzkyNDgyMzY2LCJleHAiOjE3OTI1Njg3NjZ9.AEgqF_Ryj682yihZuZZyrqUpYoVXuOEA96j1gdml8_Ht6PTJuM2mmqCCRSsSn7UV	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:46:06.994688	2026-10-20 07:50:13.829798	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
85	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiMjAzYzBmMWItZGViMy00NmY4LTgzNjEtN2Q1MzE0MzVmODYxIiwiaWF0IjoxNzkyNDgyNjMzLCJleHAiOjE3OTI1NjkwMzN9.DayPjM9ohPtbfTpe1cy9z9Vp20l8N9VCpeWeZ2cZJ67Z68OnyHKci1k0_LBsDuuj	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:50:33.270517	2026-10-20 07:50:47.611119	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
97	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYzYzNWVlY2ItMzRmNC00NDY0LWI5MGEtZGEyY2E3NDZmZGMzIiwiaWF0IjoxNzkyNDg3MTkzLCJleHAiOjE3OTI1NzM1OTN9.6JOuShx02qEjxbDCWT9uaq_kDItOh3p_aKBIkrAA5H34JhRrotAZlnimJ0Raskkq	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:06:33.882088	2026-10-20 09:06:33.882101	t	node
86	4	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0MiIsInVzZXJJZCI6NCwicm9sZSI6IkxFQ1RVUkVSIiwiZW1haWwiOiJsZWN0dXJlckBleGFtcGxlLmNvbSIsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiI4ZWEyYTY1OC0wYTZjLTQxZjAtYTYwYi0wZTRhOWM0ZDYyYjMiLCJpYXQiOjE3OTI0ODI2NjEsImV4cCI6MTc5MjU2OTA2MX0.0nVEWbZNkq7i_PWsb1ZgUlVNV4naYVfre_3x_8ba-phC5NwFFhGOrBezD7wNrdNs	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:51:01.564644	2026-10-20 07:51:57.013753	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
87	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZGM5NDNlZDYtMzM5OC00NmNhLWI0YzItOWNhODg4OWEwY2Y3IiwiaWF0IjoxNzkyNDgyNzE5LCJleHAiOjE3OTI1NjkxMTl9.e_TXAD5-oHyzmtLVQNacPGonhiwtnWu9Jc7t4_wiM9tK4Xid_a9aLnj8KXAyH4u8	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:51:59.685153	2026-10-20 07:52:37.125871	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
89	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjU1ZjAwMjRkLTk3OGQtNDNiNi1hYjZmLTcxZTFhYWM5ZDZiMSIsImlhdCI6MTc5MjQ4MzgxMCwiZXhwIjoxNzkyNTcwMjEwfQ.7A_7ujh2zSpdUMtQY9JBV3YkOBM5CKx2Ae3Kzr5cKfGCXGNRZMhQv0kad703hFg7	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:10:10.779118	2026-10-20 08:10:10.779125	t	Dart/3.13 (dart:io)
88	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjRjN2Q1NzM2LWUwNDctNGU4My1hYWRmLWY3NDhlYjEzOTY2ZiIsImlhdCI6MTc5MjQ4Mjc1OSwiZXhwIjoxNzkyNTY5MTU5fQ.M3pNinw4UziJ5-l-L0gwAY_M3zmeafE_FJd2SPmb_K-tvCrKf5YVLHZ5gEd4CQjv	172.19.0.1	\N	\N	\N	\N	2026-10-20 07:52:39.374362	2026-10-20 08:35:34.887127	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
90	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZmI0NjExODYtOGNjZC00NDUzLWE4MjktMjkzOGI0ZWRhNzVhIiwiaWF0IjoxNzkyNDg1MzQ0LCJleHAiOjE3OTI1NzE3NDR9.F__ueLXUy9GWeHav-Mdw2Bxi4XNhml6lKNGgep3ixWRtw47FkSjCzwSwaA4p_r2s	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:35:44.247667	2026-10-20 08:36:01.483084	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
91	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiN2E4OGMzYmYtYmUwNy00ZjMyLWFlM2EtNGViMDZmN2IzZjJkIiwiaWF0IjoxNzkyNDg1MzY0LCJleHAiOjE3OTI1NzE3NjR9.daeQXTxX5Loi_crIq_VbOrfB396E8j3OxT_iENETyvmE2dHDeCirOvt3oCseAMmo	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:36:04.838734	2026-10-20 08:36:30.670136	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
92	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYzAwZTkzNWMtM2E2ZC00ZWU5LWExMmMtMjE5ZGNkNGI1YzgxIiwiaWF0IjoxNzkyNDg1NDA1LCJleHAiOjE3OTI1NzE4MDV9.ZExtq1XBrt1or_0biMT6wXShWRstWRH8scxMd6B70CwJlbbaPp5Pisp05pDdJhkT	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:36:45.32076	2026-10-20 08:36:47.250267	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
93	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZmMyNGMxOGQtNzc3MC00YmMxLWI2ZWMtYTM2M2Q3NmFjMTNjIiwiaWF0IjoxNzkyNDg1NDI2LCJleHAiOjE3OTI1NzE4MjZ9.RM5-OcndKAgS9QTIO94Lsy5MCTCXRcWPztsBPbxg48gMv50M937SvrqCphUgMRoL	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:37:06.582726	2026-10-20 08:37:06.582731	t	curl/8.21.0
94	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYzhkYzZkZGYtOGJjMC00NGQwLWIzY2ItYmZjZjA4ZDljYWNlIiwiaWF0IjoxNzkyNDg1NDM5LCJleHAiOjE3OTI1NzE4Mzl9.NCLFIr46TZ_mosK-KO44Kzqaf1lKx_UJ8lSC-a5cSv1LfyBVMA9a_2R_hWayWZrn	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:37:19.476421	2026-10-20 08:37:19.476426	t	curl/8.21.0
95	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNTI0YzUwOTctODEzMS00MTNjLTg5MDQtOWQxMDY5YmYxMzBmIiwiaWF0IjoxNzkyNDg1Nzg1LCJleHAiOjE3OTI1NzIxODV9.Np516-eqwrHC3eiFXyvsUxb4v6umDXnoM08Ue9D5Kfts7UQwpTZNU1dXgSSb0Phr	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:43:05.357518	2026-10-20 08:43:05.35753	t	curl/8.21.0
96	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYjIzZTAyMzctZjQ2NS00ZmI3LWJmNmYtM2E1MjMyNDIzZWQ0IiwiaWF0IjoxNzkyNDg1ODM3LCJleHAiOjE3OTI1NzIyMzd9.jqP-l04iVcCdVCdjxZ27K4Rg7xAfNX4Wf3LqR1S1ikikBIouETtK0CWfqFVOXpPZ	172.19.0.1	\N	\N	\N	\N	2026-10-20 08:43:57.815528	2026-10-20 08:43:57.815539	t	curl/8.21.0
98	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImFlMzRkMDY0LWQ2MDgtNGYyNS1iNWZjLWI3Zjg3MjMzZGQ4YSIsImlhdCI6MTc5MjQ4NzE5OSwiZXhwIjoxNzkyNTczNTk5fQ.ARZdk4vz1QCqqKbxW5wQfbJ_Gv0XHSsP-pDbfIXNUoW-xVPiAB1kcTmxK9mafooD	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:06:39.358096	2026-10-20 09:06:39.358111	t	node
99	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYjMwZTQzNDAtZjllNS00ZmZhLTkwOWMtZjY0MjZhMjM2NjMyIiwiaWF0IjoxNzkyNDg3MTk5LCJleHAiOjE3OTI1NzM1OTl9.8P8NTk3pJVlQAR5In9nTWU42zEC1NGisVurRkMEMoRuIt8jG92pNUKw-ajLRk_Sc	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:06:39.467761	2026-10-20 09:06:39.467772	t	node
100	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjY2ZWVmOThmLWY5NzEtNDM5NS1hODBjLTFiNmI3ZTc5MmI3ZiIsImlhdCI6MTc5MjQ4NzM5OSwiZXhwIjoxNzkyNTczNzk5fQ.9ORGDhfQJ7Z6Ser7jo3SBXqxpF7EraFffhob5vBTHuo50lL5H1mJ93sxFsuOYDXs	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:10:00.000512	2026-10-20 09:10:00.000524	t	node
101	1	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJhZG1pbiIsInVzZXJJZCI6MSwicm9sZSI6IkFETUlOIiwiZW1haWwiOiJhZG1pbkB1bmljaGVjay5lZHUudm4iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiYWQzZDk0NzItMjJjOS00MjczLWE1YTEtN2NkYTQwNDQzN2UwIiwiaWF0IjoxNzkyNDg3NDE5LCJleHAiOjE3OTI1NzM4MTl9.vVquIDdzbltAYW3P2rQ4SDbwVEczDHDDQEIcpSdz2YUJNKui0WRUus7ZARVuoJBc	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:10:19.838944	2026-10-20 09:10:19.838957	t	node
102	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImViNjVkMjI2LTIyOTItNDdjNy1hNjFjLTVmMjA4MjViNmU1NCIsImlhdCI6MTc5MjQ4NzQxOSwiZXhwIjoxNzkyNTczODE5fQ.QpYzwqkVx4Bgt5phVJSC5fTGgNhC0oSSmxvn9qdjGhM9qLZFyZEKeS_Sydhhviof	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:10:19.853954	2026-10-20 09:10:19.853968	t	node
103	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNDdmNzM1ZDMtYmM1ZC00OTJjLWIxNDUtYzVkZTUzMzFkZmExIiwiaWF0IjoxNzkyNDg3NDE5LCJleHAiOjE3OTI1NzM4MTl9.VLup3WW-SmwBL2ips9w1NwWZLmgvv2khOVWrBYjS0mWRjf9ihIhzIci2NYEDNo9E	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:10:19.853974	2026-10-20 09:10:19.853981	t	node
104	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjZiNTk2ZTI4LTlkNmEtNGUzYi05ZWE3LWUyYmI5ZDlmMjJmNyIsImlhdCI6MTc5MjQ4NzQzMSwiZXhwIjoxNzkyNTczODMxfQ.AJqzpQT_2bMcOHIUV0luNVu2YAV1UiAtLC-onbKmdh0s4ZGlbfIcEhJBvOgohlkO	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:10:31.607892	2026-10-20 09:10:31.607927	t	node
105	4	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0MiIsInVzZXJJZCI6NCwicm9sZSI6IkxFQ1RVUkVSIiwiZW1haWwiOiJsZWN0dXJlckBleGFtcGxlLmNvbSIsInR5cGUiOiJhY2Nlc3MiLCJqdGkiOiJjN2NhMjExNy1jZWY3LTQyNmItOTU1NS0zNDE1ZWU4MWEzOGIiLCJpYXQiOjE3OTI0ODc0NDAsImV4cCI6MTc5MjU3Mzg0MH0.XpzSDFQAr1Ou7xxLscMq3UxsxowWQKk_Ci4TcNM9yce8tUcVCnp5Hkgi7zE0e4sr	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:10:40.309591	2026-10-20 09:10:40.3096	t	node
106	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6IjNmZGFiNzM5LTE2NjYtNGYzYy1hMmUyLWUyZjU4OWNkYWUwMSIsImlhdCI6MTc5MjQ4NzQ3MywiZXhwIjoxNzkyNTczODczfQ.NYxzwXYFep-hkN69uYK1HEyahZYsloZ0H6TAgI7lPCNtMvIunaJOUFTwrs6zbwQB	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:11:13.639183	2026-10-20 09:12:55.940363	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
107	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiM2MyZDUzYTgtYjA1My00NGE2LWJlYTctYzU3N2FjODYxZjlkIiwiaWF0IjoxNzkyNDg3NjQzLCJleHAiOjE3OTI1NzQwNDN9.FHetaRmTqoTno_0yTEo16ge1WxcYfkB6J4ssfBgSVWilZFImQkJ3z8iCJ-oWgJwA	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:14:03.180585	2026-10-20 09:14:03.180589	t	node
108	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiNzQ0MGI1OTUtOWZhMS00OGU4LTg4M2ItZmZhYTJlODEyMTZjIiwiaWF0IjoxNzkyNDg3NzAxLCJleHAiOjE3OTI1NzQxMDF9.ftWM8GTs8RlsVO7WYRw-wQcZJAiLZGAuBSlQIerHlCFU0s3nikTxjxdZP5UlGpeV	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:15:01.295311	2026-10-20 09:15:01.295315	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
109	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImZhY2NmNGY4LWNlMjgtNDk5Mi04MTQ2LTlhZTg3MWI0YTBlOSIsImlhdCI6MTc5MjQ4Nzk2OCwiZXhwIjoxNzkyNTc0MzY4fQ.BZJHxjmQ_NeoSNom_hzxwOuVJVsoHlrM_uQQcz5dglIQb_jTcvCDPbvIItB6Rm6j	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:19:28.56822	2026-10-20 09:19:28.568225	t	Dart/3.13 (dart:io)
110	2	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJzdHVkZW50X3Rlc3QiLCJ1c2VySWQiOjIsInJvbGUiOiJTVFVERU5UIiwiZW1haWwiOiJzdHVkZW50LnRlc3RAdW5pY2hlY2suZWR1LnZuIiwidHlwZSI6ImFjY2VzcyIsImp0aSI6ImQwZTZjMjU0LTEyYTMtNDZhZi1iNDcyLTY4YjRiNmRlNGNmOSIsImlhdCI6MTc5MjQ4OTExNSwiZXhwIjoxNzkyNTc1NTE1fQ.xmU_jfOPbaECWwrouc022V5JqfYbrbJF8yvQGo8yxaK_PS5xQ9oW3A9yfwmbxzQY	172.19.0.1	\N	\N	\N	\N	2026-10-20 09:38:35.921791	2026-10-20 09:38:35.921795	t	node
111	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiOTQ3NjgzZmQtYzkwNS00ZjZmLWJkNTAtYWQ4MmI4M2QxM2FmIiwiaWF0IjoxNzkyNTg3NjkzLCJleHAiOjE3OTI2NzQwOTN9.FO12Ej9ymgKWOLjRib7MoGVjrIUbW9o4XKKgdmi7GynqhRfgOdrBKbbRbEHEtqcM	172.19.0.1	\N	\N	\N	\N	2026-10-21 13:01:33.294606	2026-10-21 13:51:05.605299	f	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/155.0.0.0 Safari/537.36
112	3	eyJhbGciOiJIUzM4NCJ9.eyJpc3MiOiJ1bmljaGVjay1iYWNrZW5kIiwiYXVkIjpbInVuaWNoZWNrLWNsaWVudCJdLCJzdWIiOiJsZWN0dXJlcl90ZXN0IiwidXNlcklkIjozLCJyb2xlIjoiTEVDVFVSRVIiLCJlbWFpbCI6ImxlY3R1cmVyLnRlc3RAZXhhbXBsZS5jb20iLCJ0eXBlIjoiYWNjZXNzIiwianRpIjoiZGViYjcwM2UtYjk2Zi00ZDU1LWJkNzktYmVlMzBiYWEzMmM3IiwiaWF0IjoxNzkzMjYxNDc0LCJleHAiOjE3OTMzNDc4NzR9.fgA3OUWKodG1r-PB2FlAZP8LBLXnJ3tOAdvgsU2t8ol3cuAeZzDXbHvreuBORbk7	172.19.0.1	\N	\N	\N	\N	2026-10-29 08:11:14.423019	2026-10-29 08:11:14.423032	t	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/156.0.0.0 Safari/537.36
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.users (id, username, password, full_name, email, dob, phone, sex, role, status, face_data_status, avatar, face_registration_attempts, face_registration_blocked_until, is_password_changed, created_at, updated_at, code) FROM stdin;
1	admin	$2a$10$pUNIuVZCn/swQF//srAkL.19uTQQLccDyrgAOXHgSvsiqQ86y/b/.	Quản Trị Viên	admin@unicheck.edu.vn	\N	\N	OTHER	ADMIN	ACTIVE	NOT_REGISTERED	\N	0	\N	t	2026-10-16 07:09:55.359946	2026-10-16 07:09:55.359946	AD_001
4	lecturer_test2	$2a$10$R87Gbk7B8Tv2HfksaUb/J.T3rSgQIZzFWFm25/NB9QFjapOOcQwM2	Giảng viên 002	lecturer@example.com	\N	0978345654	OTHER	LECTURER	ACTIVE	NOT_REGISTERED	\N	0	\N	t	2026-10-20 07:50:09.660714	2026-10-20 07:50:44.32169	GV_002
3	lecturer_test	$2a$10$AQfLVR.mnr/T3euX.QNLEea.pGslSa/0DQKiW1hQPSzWqno4UGjZO	Giảng viên Kiểm thử	lecturer.test@example.com	\N	0987654321	OTHER	LECTURER	ACTIVE	NOT_REGISTERED	\N	0	\N	t	2026-10-18 15:08:13.285389	2026-10-18 15:09:53.11558	GV_TEST_001
2	student_test	$2a$10$CBTiBb8/PszCqGRk0.zkAuptptPpDeO3hdP2dV9vrPGwR1WOtJZ/.	Nguyen Van Sinh Vien	student.test@unicheck.edu.vn	2003-01-01	0901234567	MALE	STUDENT	ACTIVE	REGISTERED	\N	0	\N	t	2026-10-16 14:30:28.557335	2026-10-20 09:20:03.263899	SV2026001
\.


--
-- Data for Name: wifi_access_points; Type: TABLE DATA; Schema: public; Owner: unicheck_user
--

COPY public.wifi_access_points (id, ssid, bssid, name, location, status, created_at, updated_at) FROM stdin;
\.


--
-- Name: academic_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.academic_requests_id_seq', 1, false);


--
-- Name: access_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.access_logs_id_seq', 137, true);


--
-- Name: ai_chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.ai_chat_messages_id_seq', 1, false);


--
-- Name: ai_chat_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.ai_chat_sessions_id_seq', 1, false);


--
-- Name: alerts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.alerts_id_seq', 1, false);


--
-- Name: assignment_submissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.assignment_submissions_id_seq', 1, false);


--
-- Name: assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.assignments_id_seq', 1, false);


--
-- Name: attendance_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.attendance_configs_id_seq', 1, true);


--
-- Name: attendance_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.attendance_sessions_id_seq', 38, true);


--
-- Name: chat_group_members_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.chat_group_members_id_seq', 1, false);


--
-- Name: chat_groups_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.chat_groups_id_seq', 1, false);


--
-- Name: chat_message_reactions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.chat_message_reactions_id_seq', 1, false);


--
-- Name: chat_message_reads_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.chat_message_reads_id_seq', 1, false);


--
-- Name: chat_messages_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.chat_messages_id_seq', 1, false);


--
-- Name: courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.courses_id_seq', 1, true);


--
-- Name: enrollments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.enrollments_id_seq', 2, true);


--
-- Name: face_encodings_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.face_encodings_id_seq', 3, true);


--
-- Name: grade_components_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.grade_components_id_seq', 1, false);


--
-- Name: holidays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.holidays_id_seq', 1, true);


--
-- Name: import_jobs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.import_jobs_id_seq', 1, false);


--
-- Name: majors_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.majors_id_seq', 1, false);


--
-- Name: news_attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.news_attachments_id_seq', 1, false);


--
-- Name: news_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.news_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: room_wifi_access_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.room_wifi_access_points_id_seq', 2, true);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.rooms_id_seq', 3, true);


--
-- Name: schedule_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.schedule_requests_id_seq', 1, false);


--
-- Name: semester_configs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.semester_configs_id_seq', 1, true);


--
-- Name: semester_weekdays_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.semester_weekdays_id_seq', 1, false);


--
-- Name: semesters_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.semesters_id_seq', 1, true);


--
-- Name: slot_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.slot_types_id_seq', 1, true);


--
-- Name: specialization_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.specialization_courses_id_seq', 1, false);


--
-- Name: specializations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.specializations_id_seq', 1, false);


--
-- Name: student_attendances_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.student_attendances_id_seq', 1, true);


--
-- Name: student_grades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.student_grades_id_seq', 1, false);


--
-- Name: sub_specialization_courses_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.sub_specialization_courses_id_seq', 1, false);


--
-- Name: sub_specializations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.sub_specializations_id_seq', 1, false);


--
-- Name: system_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.system_logs_id_seq', 75, true);


--
-- Name: teaching_assignments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.teaching_assignments_id_seq', 1, true);


--
-- Name: timetable_slots_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.timetable_slots_id_seq', 14, true);


--
-- Name: user_device_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.user_device_tokens_id_seq', 1, false);


--
-- Name: user_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.user_permissions_id_seq', 1, false);


--
-- Name: user_sessions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.user_sessions_id_seq', 112, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.users_id_seq', 4, true);


--
-- Name: wifi_access_points_id_seq; Type: SEQUENCE SET; Schema: public; Owner: unicheck_user
--

SELECT pg_catalog.setval('public.wifi_access_points_id_seq', 2, true);


--
-- Name: academic_requests academic_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_pkey PRIMARY KEY (id);


--
-- Name: access_logs access_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_messages ai_chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.ai_chat_messages
    ADD CONSTRAINT ai_chat_messages_pkey PRIMARY KEY (id);


--
-- Name: ai_chat_sessions ai_chat_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.ai_chat_sessions
    ADD CONSTRAINT ai_chat_sessions_pkey PRIMARY KEY (id);


--
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- Name: assignment_submissions assignment_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_pkey PRIMARY KEY (id);


--
-- Name: assignments assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_pkey PRIMARY KEY (id);


--
-- Name: attendance_configs attendance_configs_config_key_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_configs
    ADD CONSTRAINT attendance_configs_config_key_key UNIQUE (config_key);


--
-- Name: attendance_configs attendance_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_configs
    ADD CONSTRAINT attendance_configs_pkey PRIMARY KEY (id);


--
-- Name: attendance_sessions attendance_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_pkey PRIMARY KEY (id);


--
-- Name: chat_group_members chat_group_members_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_group_members
    ADD CONSTRAINT chat_group_members_pkey PRIMARY KEY (id);


--
-- Name: chat_groups chat_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_groups
    ADD CONSTRAINT chat_groups_pkey PRIMARY KEY (id);


--
-- Name: chat_message_reactions chat_message_reactions_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reactions
    ADD CONSTRAINT chat_message_reactions_pkey PRIMARY KEY (id);


--
-- Name: chat_message_reads chat_message_reads_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reads
    ADD CONSTRAINT chat_message_reads_pkey PRIMARY KEY (id);


--
-- Name: chat_messages chat_messages_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_pkey PRIMARY KEY (id);


--
-- Name: class_sections class_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_pkey PRIMARY KEY (class_name);


--
-- Name: course_prerequisites course_prerequisites_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_pkey PRIMARY KEY (course_id, prerequisite_id);


--
-- Name: courses courses_code_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_code_key UNIQUE (code);


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: enrollments enrollments_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_pkey PRIMARY KEY (id);


--
-- Name: face_encodings face_encodings_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.face_encodings
    ADD CONSTRAINT face_encodings_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history flyway_schema_history_pk; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.flyway_schema_history
    ADD CONSTRAINT flyway_schema_history_pk PRIMARY KEY (installed_rank);


--
-- Name: grade_components grade_components_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.grade_components
    ADD CONSTRAINT grade_components_pkey PRIMARY KEY (id);


--
-- Name: holidays holidays_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_pkey PRIMARY KEY (id);


--
-- Name: import_jobs import_jobs_job_id_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.import_jobs
    ADD CONSTRAINT import_jobs_job_id_key UNIQUE (job_id);


--
-- Name: import_jobs import_jobs_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.import_jobs
    ADD CONSTRAINT import_jobs_pkey PRIMARY KEY (id);


--
-- Name: lecturer_grade_otps lecturer_grade_otps_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.lecturer_grade_otps
    ADD CONSTRAINT lecturer_grade_otps_pkey PRIMARY KEY (user_id);


--
-- Name: lecturer_profiles lecturer_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.lecturer_profiles
    ADD CONSTRAINT lecturer_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: majors majors_code_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.majors
    ADD CONSTRAINT majors_code_key UNIQUE (code);


--
-- Name: majors majors_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.majors
    ADD CONSTRAINT majors_pkey PRIMARY KEY (id);


--
-- Name: news_attachments news_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.news_attachments
    ADD CONSTRAINT news_attachments_pkey PRIMARY KEY (id);


--
-- Name: news news_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: room_wifi_access_points room_wifi_access_points_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.room_wifi_access_points
    ADD CONSTRAINT room_wifi_access_points_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_code_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_code_key UNIQUE (code);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: schedule_requests schedule_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_pkey PRIMARY KEY (id);


--
-- Name: semester_configs semester_configs_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semester_configs
    ADD CONSTRAINT semester_configs_pkey PRIMARY KEY (id);


--
-- Name: semester_weekdays semester_weekdays_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semester_weekdays
    ADD CONSTRAINT semester_weekdays_pkey PRIMARY KEY (id);


--
-- Name: semesters semesters_code_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_code_key UNIQUE (code);


--
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- Name: slot_types slot_types_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.slot_types
    ADD CONSTRAINT slot_types_pkey PRIMARY KEY (id);


--
-- Name: specialization_courses specialization_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specialization_courses
    ADD CONSTRAINT specialization_courses_pkey PRIMARY KEY (id);


--
-- Name: specializations specializations_code_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_code_key UNIQUE (code);


--
-- Name: specializations specializations_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_pkey PRIMARY KEY (id);


--
-- Name: student_attendances student_attendances_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_pkey PRIMARY KEY (id);


--
-- Name: student_grades student_grades_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_pkey PRIMARY KEY (id);


--
-- Name: student_profiles student_profiles_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_pkey PRIMARY KEY (user_id);


--
-- Name: sub_specialization_courses sub_specialization_courses_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specialization_courses
    ADD CONSTRAINT sub_specialization_courses_pkey PRIMARY KEY (id);


--
-- Name: sub_specializations sub_specializations_code_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specializations
    ADD CONSTRAINT sub_specializations_code_key UNIQUE (code);


--
-- Name: sub_specializations sub_specializations_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specializations
    ADD CONSTRAINT sub_specializations_pkey PRIMARY KEY (id);


--
-- Name: system_logs system_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_pkey PRIMARY KEY (id);


--
-- Name: teaching_assignments teaching_assignments_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_pkey PRIMARY KEY (id);


--
-- Name: timetable_slots timetable_slots_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_pkey PRIMARY KEY (id);


--
-- Name: user_device_tokens user_device_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_device_tokens
    ADD CONSTRAINT user_device_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_permissions user_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_pkey PRIMARY KEY (id);


--
-- Name: user_sessions user_sessions_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: wifi_access_points wifi_access_points_bssid_key; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.wifi_access_points
    ADD CONSTRAINT wifi_access_points_bssid_key UNIQUE (bssid);


--
-- Name: wifi_access_points wifi_access_points_pkey; Type: CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.wifi_access_points
    ADD CONSTRAINT wifi_access_points_pkey PRIMARY KEY (id);


--
-- Name: flyway_schema_history_s_idx; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX flyway_schema_history_s_idx ON public.flyway_schema_history USING btree (success);


--
-- Name: idx_access_logs_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_access_logs_user_id ON public.access_logs USING btree (user_id);


--
-- Name: idx_attendance_sessions_created_at; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_attendance_sessions_created_at ON public.attendance_sessions USING btree (created_at);


--
-- Name: idx_attendance_sessions_lecturer_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_attendance_sessions_lecturer_id ON public.attendance_sessions USING btree (lecturer_id);


--
-- Name: idx_attendance_sessions_slot_unique; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE UNIQUE INDEX idx_attendance_sessions_slot_unique ON public.attendance_sessions USING btree (timetable_slot_id);


--
-- Name: idx_attendance_sessions_status; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_attendance_sessions_status ON public.attendance_sessions USING btree (status);


--
-- Name: idx_class_sections_course_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_class_sections_course_id ON public.class_sections USING btree (course_id);


--
-- Name: idx_class_sections_lecturer_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_class_sections_lecturer_id ON public.class_sections USING btree (lecturer_id);


--
-- Name: idx_class_sections_semester_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_class_sections_semester_id ON public.class_sections USING btree (semester_id);


--
-- Name: idx_enrollments_class_name; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_enrollments_class_name ON public.enrollments USING btree (class_name);


--
-- Name: idx_enrollments_class_student_unique; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE UNIQUE INDEX idx_enrollments_class_student_unique ON public.enrollments USING btree (class_name, student_id);


--
-- Name: idx_enrollments_student_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_enrollments_student_id ON public.enrollments USING btree (student_id);


--
-- Name: idx_face_encodings_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_face_encodings_user_id ON public.face_encodings USING btree (user_id);


--
-- Name: idx_holidays_semester_date; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_holidays_semester_date ON public.holidays USING btree (semester_id, holiday_date);


--
-- Name: idx_lecturer_profiles_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_lecturer_profiles_user_id ON public.lecturer_profiles USING btree (user_id);


--
-- Name: idx_room_wifi_ap_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_room_wifi_ap_id ON public.room_wifi_access_points USING btree (wifi_access_point_id);


--
-- Name: idx_room_wifi_room_ap_unique; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE UNIQUE INDEX idx_room_wifi_room_ap_unique ON public.room_wifi_access_points USING btree (room_id, wifi_access_point_id);


--
-- Name: idx_room_wifi_room_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_room_wifi_room_id ON public.room_wifi_access_points USING btree (room_id);


--
-- Name: idx_rooms_building_status; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_rooms_building_status ON public.rooms USING btree (building, status);


--
-- Name: idx_rooms_type; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_rooms_type ON public.rooms USING btree (type);


--
-- Name: idx_semester_weekdays_semester_weekday; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_semester_weekdays_semester_weekday ON public.semester_weekdays USING btree (semester_id, weekday);


--
-- Name: idx_slot_types_semester_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_slot_types_semester_id ON public.slot_types USING btree (semester_id);


--
-- Name: idx_slot_types_slot_index; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_slot_types_slot_index ON public.slot_types USING btree (slot_index);


--
-- Name: idx_student_attendances_session_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_student_attendances_session_id ON public.student_attendances USING btree (session_id);


--
-- Name: idx_student_attendances_session_student; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_student_attendances_session_student ON public.student_attendances USING btree (session_id, student_id);


--
-- Name: idx_student_attendances_student_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_student_attendances_student_id ON public.student_attendances USING btree (student_id);


--
-- Name: idx_student_profiles_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_student_profiles_user_id ON public.student_profiles USING btree (user_id);


--
-- Name: idx_teaching_assignments_composite; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_teaching_assignments_composite ON public.teaching_assignments USING btree (lecturer_id, course_id, semester_id);


--
-- Name: idx_timetable_slots_class_name; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_timetable_slots_class_name ON public.timetable_slots USING btree (class_name);


--
-- Name: idx_timetable_slots_date; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_timetable_slots_date ON public.timetable_slots USING btree (date);


--
-- Name: idx_timetable_slots_room_date_slot; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_timetable_slots_room_date_slot ON public.timetable_slots USING btree (room_id, date, slot_number);


--
-- Name: idx_timetable_slots_slot_type_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_timetable_slots_slot_type_id ON public.timetable_slots USING btree (slot_type_id);


--
-- Name: idx_timetable_slots_status; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_timetable_slots_status ON public.timetable_slots USING btree (status);


--
-- Name: idx_user_device_tokens_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_user_device_tokens_user_id ON public.user_device_tokens USING btree (user_id);


--
-- Name: idx_user_permissions_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_user_permissions_user_id ON public.user_permissions USING btree (user_id);


--
-- Name: idx_user_sessions_token; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_user_sessions_token ON public.user_sessions USING btree (token);


--
-- Name: idx_user_sessions_user_id; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_user_sessions_user_id ON public.user_sessions USING btree (user_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: idx_users_status; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_users_status ON public.users USING btree (status);


--
-- Name: idx_users_username; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_users_username ON public.users USING btree (username);


--
-- Name: idx_wifi_ap_ssid; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_wifi_ap_ssid ON public.wifi_access_points USING btree (ssid);


--
-- Name: idx_wifi_ap_status; Type: INDEX; Schema: public; Owner: unicheck_user
--

CREATE INDEX idx_wifi_ap_status ON public.wifi_access_points USING btree (status);


--
-- Name: academic_requests academic_requests_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: academic_requests academic_requests_class_section_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_class_section_id_fkey FOREIGN KEY (class_section_id) REFERENCES public.class_sections(class_name);


--
-- Name: academic_requests academic_requests_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: academic_requests academic_requests_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id);


--
-- Name: academic_requests academic_requests_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.academic_requests
    ADD CONSTRAINT academic_requests_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: access_logs access_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.access_logs
    ADD CONSTRAINT access_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: ai_chat_messages ai_chat_messages_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.ai_chat_messages
    ADD CONSTRAINT ai_chat_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.ai_chat_sessions(id) ON DELETE CASCADE;


--
-- Name: ai_chat_sessions ai_chat_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.ai_chat_sessions
    ADD CONSTRAINT ai_chat_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: alerts alerts_resolved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_resolved_by_fkey FOREIGN KEY (resolved_by) REFERENCES public.users(id);


--
-- Name: alerts alerts_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: assignment_submissions assignment_submissions_assignment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_assignment_id_fkey FOREIGN KEY (assignment_id) REFERENCES public.assignments(id) ON DELETE CASCADE;


--
-- Name: assignment_submissions assignment_submissions_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id);


--
-- Name: assignment_submissions assignment_submissions_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignment_submissions
    ADD CONSTRAINT assignment_submissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: assignments assignments_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE CASCADE;


--
-- Name: assignments assignments_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: assignments assignments_timetable_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.assignments
    ADD CONSTRAINT assignments_timetable_slot_id_fkey FOREIGN KEY (timetable_slot_id) REFERENCES public.timetable_slots(id);


--
-- Name: attendance_sessions attendance_sessions_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id);


--
-- Name: attendance_sessions attendance_sessions_timetable_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.attendance_sessions
    ADD CONSTRAINT attendance_sessions_timetable_slot_id_fkey FOREIGN KEY (timetable_slot_id) REFERENCES public.timetable_slots(id) ON DELETE CASCADE;


--
-- Name: chat_group_members chat_group_members_chat_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_group_members
    ADD CONSTRAINT chat_group_members_chat_group_id_fkey FOREIGN KEY (chat_group_id) REFERENCES public.chat_groups(id) ON DELETE CASCADE;


--
-- Name: chat_group_members chat_group_members_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_group_members
    ADD CONSTRAINT chat_group_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_groups chat_groups_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_groups
    ADD CONSTRAINT chat_groups_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE SET NULL;


--
-- Name: chat_groups chat_groups_created_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_groups
    ADD CONSTRAINT chat_groups_created_by_id_fkey FOREIGN KEY (created_by_id) REFERENCES public.users(id);


--
-- Name: chat_message_reactions chat_message_reactions_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reactions
    ADD CONSTRAINT chat_message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat_messages(id) ON DELETE CASCADE;


--
-- Name: chat_message_reactions chat_message_reactions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reactions
    ADD CONSTRAINT chat_message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_message_reads chat_message_reads_message_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reads
    ADD CONSTRAINT chat_message_reads_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.chat_messages(id) ON DELETE CASCADE;


--
-- Name: chat_message_reads chat_message_reads_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_message_reads
    ADD CONSTRAINT chat_message_reads_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_chat_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_chat_group_id_fkey FOREIGN KEY (chat_group_id) REFERENCES public.chat_groups(id) ON DELETE CASCADE;


--
-- Name: chat_messages chat_messages_reply_to_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.chat_messages(id);


--
-- Name: chat_messages chat_messages_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.chat_messages
    ADD CONSTRAINT chat_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: class_sections class_sections_grades_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_grades_published_by_fkey FOREIGN KEY (grades_published_by) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_grades_submitted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_grades_submitted_by_fkey FOREIGN KEY (grades_submitted_by) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_resit_grades_published_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_resit_grades_published_by_fkey FOREIGN KEY (resit_grades_published_by) REFERENCES public.users(id);


--
-- Name: class_sections class_sections_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.class_sections
    ADD CONSTRAINT class_sections_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id);


--
-- Name: course_prerequisites course_prerequisites_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: course_prerequisites course_prerequisites_prerequisite_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.course_prerequisites
    ADD CONSTRAINT course_prerequisites_prerequisite_id_fkey FOREIGN KEY (prerequisite_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: enrollments enrollments_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE CASCADE;


--
-- Name: enrollments enrollments_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.enrollments
    ADD CONSTRAINT enrollments_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: face_encodings face_encodings_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.face_encodings
    ADD CONSTRAINT face_encodings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: grade_components grade_components_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.grade_components
    ADD CONSTRAINT grade_components_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: grade_components grade_components_reference_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.grade_components
    ADD CONSTRAINT grade_components_reference_component_id_fkey FOREIGN KEY (reference_component_id) REFERENCES public.grade_components(id);


--
-- Name: holidays holidays_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.holidays
    ADD CONSTRAINT holidays_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: lecturer_grade_otps lecturer_grade_otps_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.lecturer_grade_otps
    ADD CONSTRAINT lecturer_grade_otps_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: lecturer_profiles lecturer_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.lecturer_profiles
    ADD CONSTRAINT lecturer_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: news_attachments news_attachments_news_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.news_attachments
    ADD CONSTRAINT news_attachments_news_id_fkey FOREIGN KEY (news_id) REFERENCES public.news(id) ON DELETE CASCADE;


--
-- Name: news news_sender_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.news
    ADD CONSTRAINT news_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(id);


--
-- Name: room_wifi_access_points room_wifi_access_points_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.room_wifi_access_points
    ADD CONSTRAINT room_wifi_access_points_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id) ON DELETE CASCADE;


--
-- Name: room_wifi_access_points room_wifi_access_points_wifi_access_point_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.room_wifi_access_points
    ADD CONSTRAINT room_wifi_access_points_wifi_access_point_id_fkey FOREIGN KEY (wifi_access_point_id) REFERENCES public.wifi_access_points(id) ON DELETE CASCADE;


--
-- Name: schedule_requests schedule_requests_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id);


--
-- Name: schedule_requests schedule_requests_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name);


--
-- Name: schedule_requests schedule_requests_original_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_original_slot_id_fkey FOREIGN KEY (original_slot_id) REFERENCES public.timetable_slots(id);


--
-- Name: schedule_requests schedule_requests_requested_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_requested_room_id_fkey FOREIGN KEY (requested_room_id) REFERENCES public.rooms(id);


--
-- Name: schedule_requests schedule_requests_requested_slot_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_requested_slot_id_fkey FOREIGN KEY (requested_slot_id) REFERENCES public.timetable_slots(id);


--
-- Name: schedule_requests schedule_requests_requester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.schedule_requests
    ADD CONSTRAINT schedule_requests_requester_id_fkey FOREIGN KEY (requester_id) REFERENCES public.users(id);


--
-- Name: semester_configs semester_configs_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semester_configs
    ADD CONSTRAINT semester_configs_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: semester_weekdays semester_weekdays_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.semester_weekdays
    ADD CONSTRAINT semester_weekdays_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: slot_types slot_types_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.slot_types
    ADD CONSTRAINT slot_types_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: specialization_courses specialization_courses_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specialization_courses
    ADD CONSTRAINT specialization_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: specialization_courses specialization_courses_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specialization_courses
    ADD CONSTRAINT specialization_courses_specialization_id_fkey FOREIGN KEY (specialization_id) REFERENCES public.specializations(id) ON DELETE CASCADE;


--
-- Name: specializations specializations_major_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.specializations
    ADD CONSTRAINT specializations_major_id_fkey FOREIGN KEY (major_id) REFERENCES public.majors(id) ON DELETE CASCADE;


--
-- Name: student_attendances student_attendances_manual_verified_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_manual_verified_by_fkey FOREIGN KEY (manual_verified_by) REFERENCES public.users(id);


--
-- Name: student_attendances student_attendances_session_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.attendance_sessions(id) ON DELETE CASCADE;


--
-- Name: student_attendances student_attendances_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.users(id);


--
-- Name: student_attendances student_attendances_updated_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_attendances
    ADD CONSTRAINT student_attendances_updated_by_id_fkey FOREIGN KEY (updated_by_id) REFERENCES public.users(id);


--
-- Name: student_grades student_grades_enrollment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_enrollment_id_fkey FOREIGN KEY (enrollment_id) REFERENCES public.enrollments(id) ON DELETE CASCADE;


--
-- Name: student_grades student_grades_grade_component_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_grade_component_id_fkey FOREIGN KEY (grade_component_id) REFERENCES public.grade_components(id);


--
-- Name: student_grades student_grades_graded_by_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_grades
    ADD CONSTRAINT student_grades_graded_by_id_fkey FOREIGN KEY (graded_by_id) REFERENCES public.users(id);


--
-- Name: student_profiles student_profiles_major_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_major_id_fkey FOREIGN KEY (major_id) REFERENCES public.majors(id) ON DELETE SET NULL;


--
-- Name: student_profiles student_profiles_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_specialization_id_fkey FOREIGN KEY (specialization_id) REFERENCES public.specializations(id) ON DELETE SET NULL;


--
-- Name: student_profiles student_profiles_sub_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_sub_specialization_id_fkey FOREIGN KEY (sub_specialization_id) REFERENCES public.sub_specializations(id) ON DELETE SET NULL;


--
-- Name: student_profiles student_profiles_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.student_profiles
    ADD CONSTRAINT student_profiles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: sub_specialization_courses sub_specialization_courses_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specialization_courses
    ADD CONSTRAINT sub_specialization_courses_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: sub_specialization_courses sub_specialization_courses_sub_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specialization_courses
    ADD CONSTRAINT sub_specialization_courses_sub_specialization_id_fkey FOREIGN KEY (sub_specialization_id) REFERENCES public.sub_specializations(id) ON DELETE CASCADE;


--
-- Name: sub_specializations sub_specializations_specialization_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.sub_specializations
    ADD CONSTRAINT sub_specializations_specialization_id_fkey FOREIGN KEY (specialization_id) REFERENCES public.specializations(id) ON DELETE CASCADE;


--
-- Name: system_logs system_logs_performer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.system_logs
    ADD CONSTRAINT system_logs_performer_id_fkey FOREIGN KEY (performer_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: teaching_assignments teaching_assignments_course_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_course_id_fkey FOREIGN KEY (course_id) REFERENCES public.courses(id);


--
-- Name: teaching_assignments teaching_assignments_lecturer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_lecturer_id_fkey FOREIGN KEY (lecturer_id) REFERENCES public.users(id);


--
-- Name: teaching_assignments teaching_assignments_semester_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.teaching_assignments
    ADD CONSTRAINT teaching_assignments_semester_id_fkey FOREIGN KEY (semester_id) REFERENCES public.semesters(id);


--
-- Name: timetable_slots timetable_slots_class_name_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_class_name_fkey FOREIGN KEY (class_name) REFERENCES public.class_sections(class_name) ON DELETE CASCADE;


--
-- Name: timetable_slots timetable_slots_room_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms(id);


--
-- Name: timetable_slots timetable_slots_slot_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.timetable_slots
    ADD CONSTRAINT timetable_slots_slot_type_id_fkey FOREIGN KEY (slot_type_id) REFERENCES public.slot_types(id);


--
-- Name: user_device_tokens user_device_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_device_tokens
    ADD CONSTRAINT user_device_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_permissions user_permissions_granted_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: user_permissions user_permissions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_permissions
    ADD CONSTRAINT user_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_sessions user_sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: unicheck_user
--

ALTER TABLE ONLY public.user_sessions
    ADD CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict bith0XsQcvAmveJahMSc37LNDNB0sVg5e1IEs9CefAvF4GDhmCUdb7QaTSWtSYB

