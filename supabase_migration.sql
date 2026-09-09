--
-- PostgreSQL database dump
--


-- Dumped from database version 16.11
-- Dumped by pg_dump version 16.11

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

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE OR REPLACE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.audit_log (
    id integer NOT NULL,
    user_id integer,
    action character varying(100) NOT NULL,
    resource character varying(255) NOT NULL,
    parameters jsonb,
    ip_address character varying(45),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.audit_log_id_seq OWNED BY public.audit_log.id;


--
-- Name: maintenance_tasks; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.maintenance_tasks (
    id integer NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    priority character varying(20) DEFAULT 'medium'::character varying,
    category character varying(100) DEFAULT 'General'::character varying,
    sede character varying(100) DEFAULT 'Todas'::character varying,
    assigned_to integer,
    status character varying(50) DEFAULT 'pending'::character varying,
    due_date timestamp without time zone,
    is_recurring boolean DEFAULT false,
    recurrence_interval character varying(50) DEFAULT 'none'::character varying,
    checklist jsonb DEFAULT '[]'::jsonb,
    completed_at timestamp without time zone,
    completed_by integer,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    department character varying(100) DEFAULT 'Mantenimiento'::character varying,
    assigned_technician character varying(100)
);


--
-- Name: maintenance_tasks_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.maintenance_tasks_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: maintenance_tasks_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.maintenance_tasks_id_seq OWNED BY public.maintenance_tasks.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.notifications (
    id integer NOT NULL,
    ticket_id integer,
    department character varying(255) NOT NULL,
    title character varying(500) NOT NULL,
    message text NOT NULL,
    ticket_tracking_id character varying(50),
    created_by_name character varying(255),
    is_read boolean DEFAULT false,
    read_by integer,
    read_at timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.notifications_id_seq
    AS integer
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
-- Name: push_metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.push_metrics (
    id integer NOT NULL,
    notification_id integer,
    subscription_id integer,
    action character varying(50),
    delivered boolean DEFAULT false,
    clicked boolean DEFAULT false,
    closed boolean DEFAULT false,
    error text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: push_metrics_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.push_metrics_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_metrics_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.push_metrics_id_seq OWNED BY public.push_metrics.id;


--
-- Name: push_subscriptions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.push_subscriptions (
    id integer NOT NULL,
    user_id integer,
    endpoint text NOT NULL,
    keys_p256dh text NOT NULL,
    keys_auth text NOT NULL,
    department character varying(255),
    preferences jsonb DEFAULT '{"sound": true, "newTickets": true, "urgentOnly": false, "ticketUpdates": true}'::jsonb,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    last_used timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.push_subscriptions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.push_subscriptions_id_seq OWNED BY public.push_subscriptions.id;


--
-- Name: report_cache; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.report_cache (
    cache_key character varying(255) NOT NULL,
    cache_value jsonb NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone NOT NULL
);


--
-- Name: shared_reports; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.shared_reports (
    id integer NOT NULL,
    token character varying(64) NOT NULL,
    title character varying(255) NOT NULL,
    period character varying(50) DEFAULT '7d'::character varying,
    department character varying(255) DEFAULT 'all'::character varying,
    created_by integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    expires_at timestamp without time zone,
    is_active boolean DEFAULT true,
    views_count integer DEFAULT 0,
    last_viewed_at timestamp without time zone
);


--
-- Name: shared_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.shared_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shared_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shared_reports_id_seq OWNED BY public.shared_reports.id;


--
-- Name: shared_tasks_boards; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.shared_tasks_boards (
    id integer NOT NULL,
    token character varying(64) NOT NULL,
    title character varying(255) NOT NULL,
    department character varying(100) NOT NULL,
    created_by integer,
    expires_at timestamp without time zone,
    is_active boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


--
-- Name: shared_tasks_boards_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.shared_tasks_boards_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: shared_tasks_boards_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.shared_tasks_boards_id_seq OWNED BY public.shared_tasks_boards.id;


--
-- Name: system_config; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.system_config (
    key character varying(255) NOT NULL,
    value text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: ticket_updates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.ticket_updates (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    user_id integer,
    update_type character varying(50) DEFAULT 'comment'::character varying,
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: ticket_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.ticket_updates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ticket_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ticket_updates_id_seq OWNED BY public.ticket_updates.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.tickets (
    id integer NOT NULL,
    tracking_id character varying(50) NOT NULL,
    title character varying(500) NOT NULL,
    description text NOT NULL,
    status character varying(50) DEFAULT 'open'::character varying,
    priority character varying(20) DEFAULT 'medium'::character varying,
    department character varying(255),
    created_by_name character varying(255),
    created_by_email character varying(255),
    assigned_to integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    attachments jsonb DEFAULT '[]'::jsonb,
    affected_area character varying(255),
    sede character varying(50)
);


--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE IF NOT EXISTS public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'support'::character varying NOT NULL,
    department character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    active boolean DEFAULT true NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE IF NOT EXISTS public.users_id_seq
    AS integer
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
-- Name: audit_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log ALTER COLUMN id SET DEFAULT nextval('public.audit_log_id_seq'::regclass);


--
-- Name: maintenance_tasks id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tasks ALTER COLUMN id SET DEFAULT nextval('public.maintenance_tasks_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: push_metrics id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_metrics ALTER COLUMN id SET DEFAULT nextval('public.push_metrics_id_seq'::regclass);


--
-- Name: push_subscriptions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions ALTER COLUMN id SET DEFAULT nextval('public.push_subscriptions_id_seq'::regclass);


--
-- Name: shared_reports id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_reports ALTER COLUMN id SET DEFAULT nextval('public.shared_reports_id_seq'::regclass);


--
-- Name: shared_tasks_boards id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_tasks_boards ALTER COLUMN id SET DEFAULT nextval('public.shared_tasks_boards_id_seq'::regclass);


--
-- Name: ticket_updates id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_updates ALTER COLUMN id SET DEFAULT nextval('public.ticket_updates_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: audit_log; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.audit_log VALUES (1, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-01-16 13:36:26.617491') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (2, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 13:36:26.641214') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (3, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 13:36:26.641898') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (4, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 13:36:26.642499') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (5, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 13:56:45.36087') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (6, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-01-16 13:56:45.383361') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (7, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 13:56:45.383581') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (8, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 13:56:45.38378') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (9, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 14:07:13.634581') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (10, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-01-16 14:07:13.640356') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (11, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 14:07:13.646494') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (12, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-16 14:07:13.649083') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (13, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-19 08:44:40.854041') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (14, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-19 08:44:40.853179') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (15, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-01-19 08:44:40.872012') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (16, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-19 08:44:40.872858') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (17, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-21 11:06:56.081621') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (18, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-21 11:06:56.104378') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (19, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-01-21 11:06:56.106611') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (20, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-21 11:06:56.110562') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (21, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-29 09:11:29.895998') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (22, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-01-29 09:11:29.89645') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (23, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-29 09:11:29.901128') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (24, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-01-29 09:11:29.914661') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (25, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-09 11:27:08.051764') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (26, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-02-09 11:27:08.05127') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (27, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-09 11:27:08.068215') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (28, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-09 11:27:08.071493') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (30, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-21 09:34:04.947486') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (29, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-21 09:34:04.946839') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (31, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-21 09:34:04.949788') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (32, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-02-21 09:34:04.957345') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (33, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-21 09:39:05.217167') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (34, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-02-21 09:39:05.240828') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (35, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-21 09:39:05.242867') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (36, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-21 09:39:05.243621') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (37, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-24 11:53:29.264468') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (38, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-02-24 11:53:29.27399') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (39, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-24 11:53:29.274193') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (40, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-24 11:53:29.290495') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (41, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-02-24 11:54:54.236686') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (42, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-24 11:54:54.261178') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (43, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-24 11:54:54.261773') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (44, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-02-24 11:54:54.262022') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (45, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:18:25.490873') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (47, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:18:25.491395') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (46, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:18:25.491204') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (48, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:18:25.496041') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (49, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:23:25.618873') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (50, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:23:25.63222') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (51, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:23:25.634657') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (52, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:23:25.634889') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (53, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:28:25.607639') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (54, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:28:25.621951') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (55, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:28:25.624065') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (56, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:28:25.624375') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (57, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:33:25.611789') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (58, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:38:25.607327') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (59, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:38:25.621421') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (60, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:38:25.622424') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (61, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:43:25.619071') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (62, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:43:25.629391') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (63, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:48:25.667717') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (64, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:48:25.684142') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (65, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:48:25.685859') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (66, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:48:25.686354') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (67, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:58:25.645748') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (68, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:58:25.660853') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (69, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 08:58:25.661964') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (70, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 08:58:25.662122') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (71, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:08:25.609905') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (72, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:08:25.633752') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (73, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 09:08:25.634007') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (74, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:08:25.634181') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (75, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:13:25.656133') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (76, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:13:25.670994') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (77, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 09:13:25.674743') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (78, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:13:25.675223') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (79, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:23:25.60712') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (80, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:23:25.621993') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (81, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:23:25.623248') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (82, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 09:23:25.623566') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (83, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 09:33:25.619422') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (84, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:33:25.63551') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (85, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:33:25.635903') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (86, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:33:25.636985') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (87, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:43:25.639128') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (88, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:43:25.6563') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (89, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 09:43:25.656733') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (90, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:43:25.656886') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (91, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:53:25.611187') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (92, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 09:53:25.624159') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (93, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:53:25.625873') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (94, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:53:25.626037') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (95, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 09:58:25.617651') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (96, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:03:25.606506') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (97, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:03:25.619427') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (98, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 10:03:25.619606') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (99, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:08:25.60562') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (100, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:13:25.607983') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (101, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:13:25.62049') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (102, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 10:13:25.62069') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (103, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:18:25.605799') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (104, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:45:51.335529') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (105, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 10:45:51.349728') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (106, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:45:51.351807') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (107, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:45:51.352097') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (108, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:53:25.6104') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (109, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 10:53:25.62673') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (110, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:53:25.628348') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (111, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 10:53:25.629141') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (112, 2, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 11:54:23.79348') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (113, 2, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 11:54:23.871209') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (114, 2, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-03-10 11:54:23.892448') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (115, 2, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-03-10 11:54:23.904069') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (116, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 09:50:06.371761') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (117, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 09:50:06.38167') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (118, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 09:50:06.38199') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (119, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 09:50:06.393832') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (120, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 09:55:06.356981') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (121, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 09:55:06.375508') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (122, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 09:55:06.375777') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (123, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 09:55:06.375973') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (124, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 10:00:07.209313') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (125, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:00:07.227016') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (126, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:00:07.227565') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (127, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:00:07.228021') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (128, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 10:05:07.218914') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (129, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:10:07.221845') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (130, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:10:07.238146') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (131, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:10:07.238406') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (132, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 10:15:07.224675') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (133, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:15:07.236434') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (134, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:20:07.211604') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (135, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:20:07.22373') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (136, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 10:25:07.211981') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (137, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:25:07.228134') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (138, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:30:07.215904') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (139, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 10:30:07.230263') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (140, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 10:30:07.230477') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (141, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 11:57:13.424149') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (142, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 11:57:13.487875') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (143, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-23 11:57:13.516902') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (144, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-23 11:57:13.518758') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (145, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:03:27.032553') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (146, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-24 08:03:27.032783') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (147, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-24 08:19:22.227074') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (148, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:19:22.236515') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (149, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:19:22.242624') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (150, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:19:22.247044') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (151, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:26:52.125762') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (152, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:26:52.147411') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (153, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-04-24 08:26:52.147667') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (154, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-04-24 08:26:52.148228') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (156, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:19:37.761074') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (155, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:19:37.760766') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (157, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 09:19:37.760296') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (158, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:19:37.777097') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (159, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Compras e Insumos"}', '172.20.0.1', '2026-08-29 09:21:08.331366') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (160, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Compras e Insumos"}', '172.20.0.1', '2026-08-29 09:21:08.343899') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (161, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Compras e Insumos"}', '172.20.0.1', '2026-08-29 09:21:08.344178') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (162, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 09:21:09.782368') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (163, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 09:21:09.782631') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (164, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 09:21:09.784171') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (165, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 09:21:11.890262') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (166, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 09:21:11.890705') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (167, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 09:21:11.891484') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (168, 1, 'view_report', '/api/reports/trends', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 09:21:17.178581') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (169, 1, 'view_report', '/api/reports/by-department', '{"period": "180d"}', '172.20.0.1', '2026-08-29 09:21:17.218658') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (170, 1, 'view_report', '/api/reports/stats', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 09:21:17.219117') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (171, 1, 'view_report', '/api/reports/kpis', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 09:21:17.231591') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (172, 1, 'view_report', '/api/reports/trends', '{"period": "180d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 09:21:36.825844') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (173, 1, 'view_report', '/api/reports/kpis', '{"period": "180d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 09:21:36.826393') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (174, 1, 'view_report', '/api/reports/stats', '{"period": "180d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 09:21:36.826854') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (175, 1, 'view_report', '/api/reports/trends', '{"period": "180d", "department": "all"}', '172.20.0.1', '2026-08-29 09:21:43.996357') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (176, 1, 'view_report', '/api/reports/kpis', '{"period": "180d", "department": "all"}', '172.20.0.1', '2026-08-29 09:21:43.996579') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (177, 1, 'view_report', '/api/reports/stats', '{"period": "180d", "department": "all"}', '172.20.0.1', '2026-08-29 09:21:43.997421') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (178, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 09:25:26.359819') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (179, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:25:26.385764') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (180, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:25:26.387135') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (181, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:25:26.38843') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (182, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:27:53.509269') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (183, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:27:53.545612') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (184, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:27:53.546017') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (185, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 09:27:53.546615') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (186, 1, 'create_shared_report', '/api/reports/share', '{"token": "bcf457afe0c0f27bebf2cbe78d9efc19248386d04eef21b9", "period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:30:21.146695') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (187, 1, 'revoke_shared_report', '/api/reports/share/dd33bb6372548b34e7008497c890d0218ae70bf712c1f9e4', NULL, '172.20.0.1', '2026-08-29 09:31:10.811335') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (188, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:32:53.502657') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (189, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:32:53.513609') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (190, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 09:32:53.517723') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (191, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:32:53.518632') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (192, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:39:41.89761') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (193, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:39:41.931355') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (194, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 09:39:41.94909') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (195, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 09:39:41.949437') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (196, 1, 'create_maintenance_task', '/api/maintenance/tasks/1', '{"title": "Revisión y Prueba de Grupo Electrógeno"}', '172.20.0.1', '2026-08-29 09:42:05.46012') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (197, 1, 'delete_maintenance_task', '/api/maintenance/tasks/1', '{"title": "Revisión y Prueba de Grupo Electrógeno"}', '172.20.0.1', '2026-08-29 09:42:05.590213') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (198, 1, 'delete_maintenance_task', '/api/maintenance/tasks/2', '{"title": "Revisión y Prueba de Grupo Electrógeno"}', '172.20.0.1', '2026-08-29 09:42:05.631927') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (199, 10, 'create_maintenance_task', '/api/maintenance/tasks/3', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:43:31.347276') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (200, 1, 'create_maintenance_task', '/api/maintenance/tasks/4', '{"title": "Tarea en Sede Ciudad"}', '172.20.0.1', '2026-08-29 09:44:26.593999') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (201, 1, 'create_maintenance_task', '/api/maintenance/tasks/5', '{"title": "Tarea en Sede Maipú"}', '172.20.0.1', '2026-08-29 09:44:26.644037') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (202, 1, 'create_maintenance_task', '/api/maintenance/tasks/6', '{"title": "Tarea en Sede San Martín"}', '172.20.0.1', '2026-08-29 09:44:26.694491') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (203, 1, 'delete_maintenance_task', '/api/maintenance/tasks/4', '{"title": "Tarea en Sede Ciudad"}', '172.20.0.1', '2026-08-29 09:44:26.743547') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (204, 1, 'delete_maintenance_task', '/api/maintenance/tasks/5', '{"title": "Tarea en Sede Maipú"}', '172.20.0.1', '2026-08-29 09:44:26.7858') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (205, 1, 'delete_maintenance_task', '/api/maintenance/tasks/6', '{"title": "Tarea en Sede San Martín"}', '172.20.0.1', '2026-08-29 09:44:26.836027') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (206, 10, 'delete_maintenance_task', '/api/maintenance/tasks/3', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:48:11.068069') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (207, 10, 'delete_maintenance_task', '/api/maintenance/tasks/7', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:48:13.314802') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (208, 10, 'create_maintenance_task', '/api/maintenance/tasks/8', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:48:23.085799') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (209, 10, 'delete_maintenance_task', '/api/maintenance/tasks/9', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:48:42.639892') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (210, 10, 'delete_maintenance_task', '/api/maintenance/tasks/8', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:48:44.5953') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (211, 1, 'create_maintenance_task', '/api/maintenance/tasks/10', '{"title": "Limpieza de Filtros de Aire Acondicionado"}', '172.20.0.1', '2026-08-29 09:50:37.192999') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (212, 1, 'delete_maintenance_task', '/api/maintenance/tasks/10', '{"title": "Limpieza de Filtros de Aire Acondicionado"}', '172.20.0.1', '2026-08-29 09:50:37.289033') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (213, 10, 'create_maintenance_task', '/api/maintenance/tasks/11', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 09:51:20.114892') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (214, 1, 'create_maintenance_task', '/api/maintenance/tasks/12', '{"title": "Control de Presión en Tomógrafo"}', '172.20.0.1', '2026-08-29 09:55:41.931646') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (215, 1, 'delete_maintenance_task', '/api/maintenance/tasks/12', '{"title": "Control de Presión en Tomógrafo"}', '172.20.0.1', '2026-08-29 09:55:42.495328') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (216, 10, 'create_maintenance_task', '/api/maintenance/tasks/13', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 10:19:40.158949') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (217, 1, 'create_maintenance_task', '/api/maintenance/tasks/14', '{"title": "Tarea Test Eliminacion"}', '172.20.0.1', '2026-08-29 10:38:57.177899') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (218, 1, 'delete_maintenance_task', '/api/maintenance/tasks/14', '{"title": "Tarea Test Eliminacion"}', '172.20.0.1', '2026-08-29 10:38:57.235963') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (219, 10, 'delete_maintenance_task', '/api/maintenance/tasks/13', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 10:39:57.994614') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (220, 10, 'delete_maintenance_task', '/api/maintenance/tasks/11', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 10:40:03.735066') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (221, 10, 'create_maintenance_task', '/api/maintenance/tasks/15', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-29 10:41:09.68296') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (222, 10, 'create_maintenance_task', '/api/maintenance/tasks/16', '{"title": "Molestar a Matias"}', '172.20.0.1', '2026-08-29 10:41:50.568132') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (223, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 10:46:05.705048') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (224, 10, 'create_shared_report', '/api/reports/share', '{"token": "6c86914342ca3b71c0a8122eca686e7979f360715fc97075", "period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-29 10:46:05.760276') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (225, 10, 'delete_shared_report', '/api/reports/share/6c86914342ca3b71c0a8122eca686e7979f360715fc97075', NULL, '172.20.0.1', '2026-08-29 10:46:05.849955') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (226, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 10:56:23.069364') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (227, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 10:56:23.075358') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (228, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 10:56:23.087671') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (229, 3, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 10:56:23.094365') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (230, 3, 'create_maintenance_task', '/api/maintenance/tasks/17', '{"title": "Verificación mensual de Servidor NAS y Copias de Seguridad"}', '172.20.0.1', '2026-08-29 10:56:41.876511') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (231, 3, 'create_shared_report', '/api/reports/share', '{"token": "bd63ad11c32b8a890fb0afe6130f888e46bd87c895d7ae84", "period": "7d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 10:56:41.977287') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (232, 3, 'delete_shared_report', '/api/reports/share/bd63ad11c32b8a890fb0afe6130f888e46bd87c895d7ae84', NULL, '172.20.0.1', '2026-08-29 10:56:42.027359') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (233, 3, 'delete_maintenance_task', '/api/maintenance/tasks/17', '{"title": "Verificación mensual de Servidor NAS y Copias de Seguridad"}', '172.20.0.1', '2026-08-29 10:56:42.077527') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (234, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 11:01:23.413793') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (235, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 11:01:23.435641') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (236, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 11:01:23.435927') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (237, 3, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 11:01:23.436143') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (238, 3, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 11:07:34.667447') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (239, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-29 11:07:34.671125') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (240, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 11:20:07.460492') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (241, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 11:20:07.477981') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (242, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 11:20:07.481419') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (243, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 11:20:07.495801') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (244, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 11:57:51.239145') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (245, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 11:57:51.247964') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (246, 1, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-29 11:57:51.252946') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (247, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-29 11:57:51.253191') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (248, 3, 'create_maintenance_task', '/api/maintenance/tasks/18', '{"title": "Verificación mensual de Servidor NAS y Copias de Seguridad"}', '172.20.0.1', '2026-08-29 11:59:35.621131') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (249, 10, 'delete_maintenance_task', '/api/maintenance/tasks/16', '{"title": "Molestar a Rodolfo"}', '172.20.0.1', '2026-08-31 08:51:23.117196') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (250, 10, 'delete_maintenance_task', '/api/maintenance/tasks/15', '{"title": "Molestar a Matias"}', '172.20.0.1', '2026-08-31 08:51:25.567446') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (251, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:33.965935') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (252, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:33.994859') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (253, 10, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-31 08:51:33.995789') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (254, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:33.998928') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (255, 10, 'view_report', '/api/reports/kpis', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:49.125678') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (256, 10, 'view_report', '/api/reports/trends', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:49.125825') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (257, 10, 'view_report', '/api/reports/stats', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:49.127409') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (258, 10, 'view_report', '/api/reports/by-department', '{"period": "1d"}', '172.20.0.1', '2026-08-31 08:51:49.128396') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (259, 10, 'view_report', '/api/reports/kpis', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:50.574531') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (260, 10, 'view_report', '/api/reports/trends', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:50.574773') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (261, 10, 'view_report', '/api/reports/by-department', '{"period": "7d"}', '172.20.0.1', '2026-08-31 08:51:50.575531') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (262, 10, 'view_report', '/api/reports/stats', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:50.57587') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (263, 10, 'view_report', '/api/reports/trends', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:51.87803') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (264, 10, 'view_report', '/api/reports/kpis', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:51.878249') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (265, 10, 'view_report', '/api/reports/by-department', '{"period": "90d"}', '172.20.0.1', '2026-08-31 08:51:51.878634') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (266, 10, 'view_report', '/api/reports/stats', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:51.909503') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (267, 10, 'view_report', '/api/reports/by-department', '{"period": "365d"}', '172.20.0.1', '2026-08-31 08:51:53.785079') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (268, 10, 'view_report', '/api/reports/kpis', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:53.785342') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (269, 10, 'view_report', '/api/reports/trends', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:53.787483') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (270, 10, 'view_report', '/api/reports/stats', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:51:53.788244') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (271, 10, 'create_shared_report', '/api/reports/share', '{"token": "f2f716b56a118f43a2d5c824013f2dfd43ce89107f6e4e44", "period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:52:31.572734') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (272, 10, 'create_shared_report', '/api/reports/share', '{"token": "22c0f865da329b542207dd991196388934c54d197579efc2", "period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:53:05.92642') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (273, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:57:03.585726') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (274, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:57:03.591934') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (278, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:57:59.165781') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (277, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:57:59.166484') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (275, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 08:57:59.165151') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (276, 10, 'view_report', '/api/reports/by-department', '{"period": "30d"}', '172.20.0.1', '2026-08-31 08:57:59.166243') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (279, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:06:03.27831') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (280, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-31 09:06:03.318288') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (281, 1, 'create_shared_report', '/api/reports/share', '{"token": "867b032fef8564020aee26b708819223b171426208b82838", "period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:06:03.395487') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (282, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:07:59.630676') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (283, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:07:59.643106') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (284, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:07:59.646054') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (285, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:07:59.646313') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (287, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:46:45.335037') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (286, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:46:45.334559') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (288, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:46:45.351114') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (289, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:46:45.352608') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (290, 10, 'create_shared_report', '/api/reports/share', '{"token": "002cebdfa4819b19e68dceeae6e255155516300125bd9191", "period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:46:51.742124') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (291, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:51:45.650208') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (292, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:51:45.659348') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (293, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:51:45.66378') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (294, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 09:51:45.664038') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (295, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:01:45.640145') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (296, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:01:45.655101') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (297, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:01:45.655381') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (298, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:01:45.655777') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (299, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:06:46.319491') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (300, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:06:46.319894') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (301, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:06:46.331548') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (302, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:06:46.334499') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (303, 10, 'delete_shared_report', '/api/reports/share/22c0f865da329b542207dd991196388934c54d197579efc2', NULL, '172.20.0.1', '2026-08-31 10:07:12.415399') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (304, 10, 'delete_shared_report', '/api/reports/share/002cebdfa4819b19e68dceeae6e255155516300125bd9191', NULL, '172.20.0.1', '2026-08-31 10:07:13.873426') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (305, 10, 'delete_shared_report', '/api/reports/share/f2f716b56a118f43a2d5c824013f2dfd43ce89107f6e4e44', NULL, '172.20.0.1', '2026-08-31 10:07:15.779887') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (306, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:08:51.141727') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (307, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:08:51.155528') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (308, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:08:51.156932') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (309, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:08:51.192546') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (310, 10, 'view_report', '/api/reports/trends', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:02.243445') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (311, 10, 'view_report', '/api/reports/by-department', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:02.243819') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (312, 10, 'view_report', '/api/reports/stats', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:02.244304') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (313, 10, 'view_report', '/api/reports/kpis', '{"period": "365d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:02.24455') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (314, 10, 'view_report', '/api/reports/by-department', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:07.185918') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (315, 10, 'view_report', '/api/reports/trends', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:07.187172') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (316, 10, 'view_report', '/api/reports/stats', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:07.192503') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (317, 10, 'view_report', '/api/reports/kpis', '{"period": "180d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:07.195357') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (318, 10, 'view_report', '/api/reports/trends', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:09.313692') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (319, 10, 'view_report', '/api/reports/kpis', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:09.314141') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (320, 10, 'view_report', '/api/reports/by-department', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:09.314851') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (321, 10, 'view_report', '/api/reports/stats', '{"period": "90d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:09.315274') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (322, 10, 'view_report', '/api/reports/kpis', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:12.480312') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (323, 10, 'view_report', '/api/reports/by-department', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:12.48054') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (324, 10, 'view_report', '/api/reports/trends', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:12.48086') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (325, 10, 'view_report', '/api/reports/stats', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:12.482201') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (326, 10, 'view_report', '/api/reports/trends', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:16.733828') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (327, 10, 'view_report', '/api/reports/by-department', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:16.734055') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (328, 10, 'view_report', '/api/reports/kpis', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:16.734397') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (329, 10, 'view_report', '/api/reports/stats', '{"period": "1d", "department": "Mantenimiento"}', '172.20.0.1', '2026-08-31 10:09:16.735087') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (330, 3, 'delete_maintenance_task', '/api/maintenance/tasks/18', '{"title": "Verificación mensual de Servidor NAS y Copias de Seguridad"}', '172.20.0.1', '2026-08-31 10:35:07.931499') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (331, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 10:56:03.65795') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (332, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 10:56:03.676148') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (333, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 10:56:03.676724') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (334, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 10:56:03.678543') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (335, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 11:02:59.631217') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (336, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 11:02:59.644447') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (337, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 11:02:59.645907') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (338, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-08-31 11:02:59.646766') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (339, 10, 'create_maintenance_task', '/api/maintenance/tasks/19', '{"title": "Sepi"}', '172.20.0.1', '2026-08-31 12:01:18.988423') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (340, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-31 13:58:53.953841') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (341, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-31 13:58:53.955737') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (342, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-31 13:58:53.974136') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (343, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-08-31 13:58:53.974552') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (344, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:04:38.426045') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (345, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:04:38.428871') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (346, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:04:38.451447') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (347, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:04:38.454897') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (348, 3, 'view_report', '/api/reports/kpis', '{"period": "1d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:05:03.993523') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (349, 3, 'view_report', '/api/reports/trends', '{"period": "1d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:05:03.994641') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (350, 3, 'view_report', '/api/reports/stats', '{"period": "1d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:05:03.995247') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (351, 3, 'view_report', '/api/reports/by-department', '{"period": "1d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:05:03.996797') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (352, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:48:40.115196') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (354, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:48:40.13431') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (353, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:48:40.131531') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (355, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 08:48:40.138331') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (356, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:05:00.862655') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (357, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:05:00.885255') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (358, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:05:00.887111') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (359, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:05:00.887413') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (360, 3, 'create_maintenance_task', '/api/maintenance/tasks/20', '{"title": "Actualización de Drivers, analisis con antivirus, verificar configuraciones."}', '172.20.0.1', '2026-09-02 09:10:32.559089') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (361, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:15:44.086116') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (362, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:15:44.103858') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (364, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:15:44.111412') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (363, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:15:44.110732') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (365, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:29:25.48442') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (366, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:29:25.518326') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (367, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:29:25.518764') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (368, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:29:25.523355') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (369, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:45:06.552966') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (370, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:45:06.554544') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (371, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:45:06.577799') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (372, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 09:45:06.580201') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (373, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:45:32.781858') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (374, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:45:32.785562') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (375, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:45:32.789442') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (376, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:45:32.790503') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (377, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:50:33.640703') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (378, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:50:33.660518') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (379, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:50:33.660998') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (380, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 09:50:33.66128') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (381, 3, 'create_maintenance_task', '/api/maintenance/tasks/21', '{"title": "Gestión de inventario, computadoras, monitores, impresoras"}', '172.20.0.1', '2026-09-02 10:17:35.027329') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (382, 1, 'create_maintenance_task', '/api/maintenance/tasks/22', '{"title": "Mantenimiento Preventivo de Aire Acondicionado"}', '172.20.0.1', '2026-09-02 10:22:52.076785') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (383, 1, 'create_maintenance_task', '/api/maintenance/tasks/23', '{"title": "Actualización de Sistema Operativo en Servidor Principal"}', '172.20.0.1', '2026-09-02 10:22:52.145806') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (384, 3, 'create_maintenance_task', '/api/maintenance/tasks/24', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:24:46.245557') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (385, 3, 'delete_maintenance_task', '/api/maintenance/tasks/24', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:24:51.84169') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (386, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:25:30.845823') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (387, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:25:30.88514') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (388, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:25:30.888105') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (389, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:25:30.889601') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (390, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:30:52.542409') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (391, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:30:52.544426') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (392, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:30:52.565755') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (393, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:30:52.568058') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (394, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:31:41.883623') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (395, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:31:41.906491') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (396, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:31:41.907776') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (397, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:31:41.91558') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (398, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:33:04.095833') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (399, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:33:04.113716') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (400, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:33:04.114058') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (401, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:33:34.160518') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (402, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:34:40.125368') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (403, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Compras e Insumos"}', '172.20.0.1', '2026-09-02 10:35:41.71884') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (404, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Compras e Insumos"}', '172.20.0.1', '2026-09-02 10:35:41.720131') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (405, 3, 'create_maintenance_task', '/api/maintenance/tasks/25', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:37:31.293278') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (406, 3, 'delete_maintenance_task', '/api/maintenance/tasks/25', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:37:37.235038') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (407, 1, 'create_maintenance_task', '/api/maintenance/tasks/26', '{"title": "Calibración de Sensor Único"}', '172.20.0.1', '2026-09-02 10:42:17.020923') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (408, 1, 'create_maintenance_task', '/api/maintenance/tasks/27', '{"title": "Inspección Semanal de Tableros Eléctricos"}', '172.20.0.1', '2026-09-02 10:42:17.111906') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (409, 1, 'delete_maintenance_task', '/api/maintenance/tasks/19', '{"title": "Sepi"}', '172.20.0.1', '2026-09-02 10:47:00.282547') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (410, 1, 'delete_maintenance_task', '/api/maintenance/tasks/29', '{"title": "Sepi"}', '172.20.0.1', '2026-09-02 10:47:04.351037') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (411, 1, 'create_maintenance_task', '/api/maintenance/tasks/30', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:47:12.46701') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (412, 1, 'delete_maintenance_task', '/api/maintenance/tasks/31', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:47:25.973151') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (413, 1, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:47:27.329553') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (414, 1, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:47:27.332614') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (415, 1, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:47:27.332382') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (416, 1, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "all"}', '172.20.0.1', '2026-09-02 10:47:27.332957') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (417, 1, 'delete_maintenance_task', '/api/maintenance/tasks/34', '{"title": "asd"}', '172.20.0.1', '2026-09-02 10:47:38.582605') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (418, 1, 'create_shared_tasks_board', '/api/maintenance/tasks/share', '{"token": "55999ec2c99f25f5eb2af1668072485263e08dd57338079e", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-02 10:51:08.728974') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (419, 1, 'delete_shared_tasks_board', '/api/maintenance/tasks/share/55999ec2c99f25f5eb2af1668072485263e08dd57338079e', NULL, '172.20.0.1', '2026-09-02 10:51:08.803663') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (620, 3, 'delete_maintenance_task', '/api/maintenance/tasks/176', '{"title": "asdasdsa"}', '172.20.0.1', '2026-09-08 11:16:53.190198') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (420, 1, 'create_shared_tasks_board', '/api/maintenance/tasks/share', '{"token": "b185899dc1a0d69b323dc1dd0ea8ecae41c12885d95bc5e8", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-02 10:52:18.382768') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (421, 3, 'create_shared_tasks_board', '/api/maintenance/tasks/share', '{"token": "3d107d49e3729b25ab4ec4291faf5172ac7fd203a2a8b083", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 10:57:48.556272') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (422, 10, 'delete_maintenance_task', '/api/maintenance/tasks/30', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:14:52.884755') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (423, 10, 'delete_maintenance_task', '/api/maintenance/tasks/32', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:14:57.069744') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (424, 10, 'delete_maintenance_task', '/api/maintenance/tasks/33', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:14:59.78072') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (425, 10, 'delete_maintenance_task', '/api/maintenance/tasks/35', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:15:02.390488') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (426, 3, 'create_maintenance_task', '/api/maintenance/tasks/36', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:16:24.123973') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (427, 10, 'create_maintenance_task', '/api/maintenance/tasks/39', '{"title": "Sepi"}', '172.20.0.1', '2026-09-02 11:19:58.226949') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (428, 3, 'delete_maintenance_task', '/api/maintenance/tasks/36', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:21:07.337836') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (429, 3, 'delete_maintenance_task', '/api/maintenance/tasks/37', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:21:09.509522') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (430, 3, 'delete_maintenance_task', '/api/maintenance/tasks/38', '{"title": "asd"}', '172.20.0.1', '2026-09-02 11:21:15.095841') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (431, 10, 'create_maintenance_task', '/api/maintenance/tasks/42', '{"title": "Sepi Limpieza y lavado"}', '172.20.0.1', '2026-09-02 11:21:56.739543') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (432, 10, 'delete_maintenance_task', '/api/maintenance/tasks/44', '{"title": "Sepi control"}', '172.20.0.1', '2026-09-02 11:23:26.97682') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (433, 10, 'delete_maintenance_task', '/api/maintenance/tasks/45', '{"title": "Sepi control"}', '172.20.0.1', '2026-09-02 11:23:35.447857') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (434, 10, 'create_maintenance_task', '/api/maintenance/tasks/46', '{"title": "SEPI bombas"}', '172.20.0.1', '2026-09-02 11:28:26.316143') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (435, 10, 'delete_maintenance_task', '/api/maintenance/tasks/43', '{"title": "Sepi Limpieza y lavado"}', '172.20.0.1', '2026-09-02 11:34:44.819703') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (436, 10, 'delete_maintenance_task', '/api/maintenance/tasks/40', '{"title": "Sepi"}', '172.20.0.1', '2026-09-02 11:47:39.676053') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (437, 10, 'delete_maintenance_task', '/api/maintenance/tasks/41', '{"title": "Sepi control"}', '172.20.0.1', '2026-09-02 11:47:43.46392') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (438, 3, 'create_maintenance_task', '/api/maintenance/tasks/50', '{"title": "afdf"}', '172.20.0.1', '2026-09-02 11:55:29.951492') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (439, 3, 'delete_maintenance_task', '/api/maintenance/tasks/50', '{"title": "afdf"}', '172.20.0.1', '2026-09-02 11:55:33.40106') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (440, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 11:57:35.18413') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (441, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 11:57:35.186884') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (442, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 11:57:35.211279') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (443, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-02 11:57:35.212862') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (444, 10, 'create_maintenance_task', '/api/maintenance/tasks/51', '{"title": "Aire Acond. Alto/Bajo campo"}', '172.20.0.1', '2026-09-02 11:57:45.660686') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (445, 10, 'create_maintenance_task', '/api/maintenance/tasks/53', '{"title": "Aire Acond. Alto/Bajo campo"}', '172.20.0.1', '2026-09-02 12:08:06.799223') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (446, 10, 'create_maintenance_task', '/api/maintenance/tasks/55', '{"title": "Aire Acond. Central"}', '172.20.0.1', '2026-09-02 12:11:00.013278') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (447, 10, 'create_maintenance_task', '/api/maintenance/tasks/59', '{"title": "Aire Acond. Central"}', '172.20.0.1', '2026-09-02 12:15:20.268479') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (448, 3, 'create_maintenance_task', '/api/maintenance/tasks/60', '{"title": "asds"}', '172.20.0.1', '2026-09-03 08:04:21.486293') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (449, 10, 'create_maintenance_task', '/api/maintenance/tasks/62', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-03 14:59:33.254101') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (450, 10, 'create_maintenance_task', '/api/maintenance/tasks/65', '{"title": "SEPI Limpieza y lavado"}', '172.20.0.1', '2026-09-03 15:06:51.855015') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (451, 10, 'create_maintenance_task', '/api/maintenance/tasks/67', '{"title": "SEPI rotacion de bombas"}', '172.20.0.1', '2026-09-03 15:12:36.313116') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (452, 10, 'delete_maintenance_task', '/api/maintenance/tasks/57', '{"title": "Control y Mantenimiento de Bombas y SEPI"}', '172.20.0.1', '2026-09-03 15:15:49.262006') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (453, 10, 'delete_maintenance_task', '/api/maintenance/tasks/58', '{"title": "Revisión y Limpieza de Equipos de Aire Acondicionado"}', '172.20.0.1', '2026-09-03 15:16:13.770645') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (454, 3, 'delete_maintenance_task', '/api/maintenance/tasks/60', '{"title": "asds"}', '172.20.0.1', '2026-09-04 08:20:11.104829') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (455, 3, 'delete_maintenance_task', '/api/maintenance/tasks/61', '{"title": "asds"}', '172.20.0.1', '2026-09-04 08:20:13.777929') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (456, 3, 'create_maintenance_task', '/api/maintenance/tasks/69', '{"title": "bcvb"}', '172.20.0.1', '2026-09-04 08:29:26.210277') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (457, 3, 'delete_maintenance_task', '/api/maintenance/tasks/69', '{"title": "bcvb"}', '172.20.0.1', '2026-09-04 08:29:59.264098') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (458, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:34:37.333762') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (459, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:34:37.353003') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (460, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:34:37.356846') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (461, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:34:37.389828') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (462, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:39:56.758347') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (463, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:39:56.77725') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (464, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:39:56.778836') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (465, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 10:39:56.780058') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (466, 10, 'create_maintenance_task', '/api/maintenance/tasks/71', '{"title": "Aire Acond. Alto/Bajo campo"}', '172.20.0.1', '2026-09-04 11:09:59.580552') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (467, 10, 'delete_maintenance_task', '/api/maintenance/tasks/77', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-04 11:10:38.672033') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (468, 10, 'create_maintenance_task', '/api/maintenance/tasks/78', '{"title": "Aire Acond. Alto/Bajo limpieza"}', '172.20.0.1', '2026-09-04 11:18:07.572399') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (469, 10, 'create_maintenance_task', '/api/maintenance/tasks/79', '{"title": "CONTROL Aire Acond. Central"}', '172.20.0.1', '2026-09-04 11:19:49.715162') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (470, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 11:20:10.775683') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (471, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 11:20:10.778492') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (472, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 11:20:10.787278') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (473, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-04 11:20:10.788448') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (474, 10, 'create_maintenance_task', '/api/maintenance/tasks/84', '{"title": "lavado Aire Acond. Central"}', '172.20.0.1', '2026-09-04 11:21:35.67059') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (475, 10, 'delete_maintenance_task', '/api/maintenance/tasks/84', '{"title": "lavado Aire Acond. Central"}', '172.20.0.1', '2026-09-04 13:09:25.420641') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (476, 10, 'create_maintenance_task', '/api/maintenance/tasks/85', '{"title": "control Grupo Electrógeno"}', '172.20.0.1', '2026-09-04 13:10:14.441882') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (477, 10, 'create_maintenance_task', '/api/maintenance/tasks/90', '{"title": "Grupo Electrógeno arranque"}', '172.20.0.1', '2026-09-04 13:11:35.746072') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (478, 10, 'create_maintenance_task', '/api/maintenance/tasks/92', '{"title": "Grupo Electrógeno limpieza"}', '172.20.0.1', '2026-09-04 13:12:36.588071') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (479, 10, 'create_maintenance_task', '/api/maintenance/tasks/93', '{"title": "Grupo Electrógeno"}', '172.20.0.1', '2026-09-04 13:13:16.029528') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (480, 10, 'create_maintenance_task', '/api/maintenance/tasks/95', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-04 13:15:23.624254') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (481, 10, 'delete_maintenance_task', '/api/maintenance/tasks/100', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 07:54:03.464009') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (482, 10, 'delete_maintenance_task', '/api/maintenance/tasks/104', '{"title": "Aire Acond. Alto/Bajo campo"}', '172.20.0.1', '2026-09-07 07:54:06.90833') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (483, 10, 'delete_maintenance_task', '/api/maintenance/tasks/103', '{"title": "control Grupo Electrógeno"}', '172.20.0.1', '2026-09-07 07:54:10.010574') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (484, 10, 'delete_maintenance_task', '/api/maintenance/tasks/102', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 07:54:14.242577') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (485, 10, 'delete_maintenance_task', '/api/maintenance/tasks/101', '{"title": "CONTROL Aire Acond. Central"}', '172.20.0.1', '2026-09-07 07:54:17.055495') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (486, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:07:20.251195') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (487, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:07:20.253686') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (488, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:07:20.276081') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (489, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:07:20.325577') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (490, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:12:20.952291') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (491, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:12:20.976993') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (492, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:12:20.978196') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (493, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:12:20.978881') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (494, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:17:44.937899') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (495, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:17:44.966584') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (496, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:17:44.970471') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (497, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 08:17:44.970742') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (498, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 09:53:25.954433') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (499, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 09:53:25.967181') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (500, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 09:53:25.967466') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (501, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 09:53:25.968415') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (502, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:00:31.208575') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (503, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:00:31.227214') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (504, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:00:31.227452') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (505, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:00:31.228334') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (506, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:07:20.935922') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (507, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:07:20.953246') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (508, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:07:20.953733') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (509, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:07:20.954379') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (510, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:12:20.952455') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (511, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:17:20.948462') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (512, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:17:20.959974') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (513, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:17:20.960269') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (514, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:22:20.945389') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (515, 3, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:33:06.973846') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (516, 3, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:33:07.000726') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (517, 3, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:33:07.002254') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (518, 3, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Sistemas"}', '172.20.0.1', '2026-09-07 10:33:07.002589') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (519, 10, 'delete_maintenance_task', '/api/maintenance/tasks/119', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 10:56:00.616945') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (520, 10, 'delete_maintenance_task', '/api/maintenance/tasks/118', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 10:56:05.143659') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (521, 10, 'delete_maintenance_task', '/api/maintenance/tasks/115', '{"title": "Aire Acond. Alto/Bajo campo"}', '172.20.0.1', '2026-09-07 10:56:13.540827') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (522, 10, 'delete_maintenance_task', '/api/maintenance/tasks/114', '{"title": "control Grupo Electrógeno"}', '172.20.0.1', '2026-09-07 10:56:15.909081') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (523, 10, 'delete_maintenance_task', '/api/maintenance/tasks/113', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 10:56:18.932328') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (524, 10, 'delete_maintenance_task', '/api/maintenance/tasks/112', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 10:56:23.875771') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (525, 10, 'delete_maintenance_task', '/api/maintenance/tasks/111', '{"title": "CONTROL Aire Acond. Central"}', '172.20.0.1', '2026-09-07 10:56:26.984195') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (526, 10, 'delete_maintenance_task', '/api/maintenance/tasks/117', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 10:56:29.316257') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (527, 3, 'create_maintenance_task', '/api/maintenance/tasks/121', '{"title": "sdasd"}', '172.20.0.1', '2026-09-07 10:58:11.018699') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (528, 10, 'create_maintenance_task', '/api/maintenance/tasks/127', '{"title": "dasdsadasdasd"}', '172.20.0.1', '2026-09-07 11:05:26.633489') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (529, 10, 'delete_maintenance_task', '/api/maintenance/tasks/123', '{"title": "Aire Acond. Alto/Bajo campo"}', '172.20.0.1', '2026-09-07 11:05:50.364255') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (530, 10, 'delete_maintenance_task', '/api/maintenance/tasks/126', '{"title": "CONTROL Aire Acond. Central"}', '172.20.0.1', '2026-09-07 11:05:55.806393') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (621, 3, 'delete_maintenance_task', '/api/maintenance/tasks/175', '{"title": "asdasdsa"}', '172.20.0.1', '2026-09-08 11:16:57.636623') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (531, 10, 'delete_maintenance_task', '/api/maintenance/tasks/129', '{"title": "dasdsadasdasd"}', '172.20.0.1', '2026-09-07 11:06:38.146251') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (532, 10, 'delete_maintenance_task', '/api/maintenance/tasks/131', '{"title": "dasdsadasdasd"}', '172.20.0.1', '2026-09-07 11:06:46.002421') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (533, 10, 'delete_maintenance_task', '/api/maintenance/tasks/128', '{"title": "dasdsadasdasd"}', '172.20.0.1', '2026-09-07 11:06:48.409555') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (534, 10, 'delete_maintenance_task', '/api/maintenance/tasks/130', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 11:08:12.989296') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (535, 10, 'delete_maintenance_task', '/api/maintenance/tasks/132', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 11:08:15.062139') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (536, 10, 'delete_maintenance_task', '/api/maintenance/tasks/133', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 11:08:29.323783') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (537, 10, 'delete_maintenance_task', '/api/maintenance/tasks/134', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 11:08:47.570408') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (538, 10, 'delete_maintenance_task', '/api/maintenance/tasks/120', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 11:11:53.112616') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (539, 10, 'delete_maintenance_task', '/api/maintenance/tasks/136', '{"title": "SEPI control"}', '172.20.0.1', '2026-09-07 11:12:32.912964') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (540, 10, 'delete_maintenance_task', '/api/maintenance/tasks/137', '{"title": "Sala de máquinas (Alto campo)"}', '172.20.0.1', '2026-09-07 11:12:40.611406') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (541, 10, 'create_maintenance_task', '/api/maintenance/tasks/143', '{"title": "sala de maquina brivo"}', '172.20.0.1', '2026-09-07 11:15:47.336386') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (542, 10, 'create_maintenance_task', '/api/maintenance/tasks/150', '{"title": "UPS"}', '172.20.0.1', '2026-09-07 11:18:29.4724') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (543, 10, 'create_maintenance_task', '/api/maintenance/tasks/151', '{"title": "UPS Limpieza"}', '172.20.0.1', '2026-09-07 11:19:15.734291') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (544, 10, 'create_maintenance_task', '/api/maintenance/tasks/152', '{"title": "Aires Split General"}', '172.20.0.1', '2026-09-07 11:24:09.438903') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (545, 10, 'create_maintenance_task', '/api/maintenance/tasks/153', '{"title": "Aires Patio 2° piso limpieza"}', '172.20.0.1', '2026-09-07 11:25:20.907674') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (546, 10, 'create_maintenance_task', '/api/maintenance/tasks/154', '{"title": "Luces de emergencia control"}', '172.20.0.1', '2026-09-07 11:26:26.564963') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (547, 10, 'delete_maintenance_task', '/api/maintenance/tasks/127', '{"title": "dasdsadasdasd"}', '172.20.0.1', '2026-09-07 11:26:56.677661') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (548, 10, 'create_maintenance_task', '/api/maintenance/tasks/156', '{"title": "Puesta a tierra"}', '172.20.0.1', '2026-09-07 11:27:24.034632') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (549, 10, 'create_maintenance_task', '/api/maintenance/tasks/157', '{"title": "Tanques de agua"}', '172.20.0.1', '2026-09-07 11:28:25.51676') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (550, 10, 'create_maintenance_task', '/api/maintenance/tasks/158', '{"title": "Tanques de agua flotante"}', '172.20.0.1', '2026-09-07 11:29:12.416841') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (551, 10, 'create_maintenance_task', '/api/maintenance/tasks/159', '{"title": "cloacas limpeza"}', '172.20.0.1', '2026-09-07 11:30:47.629416') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (552, 10, 'delete_maintenance_task', '/api/maintenance/tasks/110', '{"title": "Aire Acond. Alto/Bajo limpieza"}', '172.20.0.1', '2026-09-07 11:32:50.006166') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (553, 10, 'delete_maintenance_task', '/api/maintenance/tasks/116', '{"title": "Aire Acond. Alto/Bajo limpieza"}', '172.20.0.1', '2026-09-07 11:32:54.914083') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (554, 10, 'delete_maintenance_task', '/api/maintenance/tasks/124', '{"title": "Aire Acond. Alto/Bajo limpieza"}', '172.20.0.1', '2026-09-07 11:32:57.051816') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (555, 10, 'delete_maintenance_task', '/api/maintenance/tasks/125', '{"title": "Aire Acond. Alto/Bajo limpieza"}', '172.20.0.1', '2026-09-07 11:32:59.655708') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (556, 10, 'create_maintenance_task', '/api/maintenance/tasks/161', '{"title": "tablero general"}', '172.20.0.1', '2026-09-07 11:36:32.2372') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (557, 10, 'create_maintenance_task', '/api/maintenance/tasks/162', '{"title": "dasd"}', '172.20.0.1', '2026-09-07 11:58:42.865519') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (558, 10, 'delete_maintenance_task', '/api/maintenance/tasks/162', '{"title": "dasd"}', '172.20.0.1', '2026-09-07 11:58:54.573689') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (559, 10, 'delete_maintenance_task', '/api/maintenance/tasks/163', '{"title": "dasd"}', '172.20.0.1', '2026-09-07 11:58:56.724221') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (560, 10, 'create_maintenance_task', '/api/maintenance/tasks/164', '{"title": "fsdf"}', '172.20.0.1', '2026-09-07 11:59:04.636167') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (561, 10, 'delete_maintenance_task', '/api/maintenance/tasks/164', '{"title": "fsdf"}', '172.20.0.1', '2026-09-07 11:59:15.663994') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (562, 10, 'delete_maintenance_task', '/api/maintenance/tasks/165', '{"title": "fsdf"}', '172.20.0.1', '2026-09-07 11:59:20.056058') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (563, 10, 'delete_maintenance_task', '/api/maintenance/tasks/166', '{"title": "fsdf"}', '172.20.0.1', '2026-09-07 11:59:21.873727') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (564, 10, 'create_shared_tasks_board', '/api/maintenance/tasks/share', '{"token": "436b1ecbb198e12ccee30c05a0ec203eba980223fe18c95c", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-07 11:59:49.722423') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (597, 3, 'delete_maintenance_task', '/api/maintenance/tasks/121', '{"title": "sdasd"}', '172.20.0.1', '2026-09-08 07:58:19.278544') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (598, 3, 'delete_maintenance_task', '/api/maintenance/tasks/122', '{"title": "sdasd"}', '172.20.0.1', '2026-09-08 07:58:21.662043') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (599, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:33:02.685046') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (600, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:33:02.696453') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (601, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:33:02.696715') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (602, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:33:02.700523') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (603, 10, 'view_report', '/api/reports/stats', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:34:27.170059') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (604, 10, 'view_report', '/api/reports/kpis', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:34:27.200392') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (605, 10, 'view_report', '/api/reports/by-department', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:34:27.20065') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (606, 10, 'view_report', '/api/reports/trends', '{"period": "7d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:34:27.200837') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (607, 10, 'view_report', '/api/reports/stats', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:38:17.809547') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (608, 10, 'view_report', '/api/reports/trends', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:38:17.824626') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (609, 10, 'view_report', '/api/reports/by-department', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:38:17.825231') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (610, 10, 'view_report', '/api/reports/kpis', '{"period": "30d", "department": "Mantenimiento"}', '172.20.0.1', '2026-09-08 08:38:17.82752') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (611, 3, 'create_maintenance_task', '/api/maintenance/tasks/167', '{"title": "n8n odonto"}', '172.20.0.1', '2026-09-08 09:14:32.931949') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (612, 3, 'create_maintenance_task', '/api/maintenance/tasks/169', '{"title": "Actualizaciones Docker"}', '172.20.0.1', '2026-09-08 10:04:55.693186') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (613, 3, 'create_maintenance_task', '/api/maintenance/tasks/171', '{"title": "Control de Tóners"}', '172.20.0.1', '2026-09-08 10:06:40.088901') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (614, 3, 'create_maintenance_task', '/api/maintenance/tasks/173', '{"title": "sadasd"}', '172.20.0.1', '2026-09-08 10:15:28.39181') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (615, 3, 'delete_maintenance_task', '/api/maintenance/tasks/173', '{"title": "sadasd"}', '172.20.0.1', '2026-09-08 10:15:34.068123') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (616, 3, 'delete_maintenance_task', '/api/maintenance/tasks/174', '{"title": "sadasd"}', '172.20.0.1', '2026-09-08 10:15:36.314819') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (617, 3, 'create_maintenance_task', '/api/maintenance/tasks/175', '{"title": "asdasdsa"}', '172.20.0.1', '2026-09-08 11:16:22.923779') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (618, 3, 'delete_maintenance_task', '/api/maintenance/tasks/178', '{"title": "asdasdsa"}', '172.20.0.1', '2026-09-08 11:16:48.005855') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (619, 3, 'delete_maintenance_task', '/api/maintenance/tasks/177', '{"title": "asdasdsa"}', '172.20.0.1', '2026-09-08 11:16:50.497555') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (622, 3, 'create_maintenance_task', '/api/maintenance/tasks/179', '{"title": "asd"}', '172.20.0.1', '2026-09-08 11:29:10.148706') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (623, 3, 'delete_maintenance_task', '/api/maintenance/tasks/182', '{"title": "asd"}', '172.20.0.1', '2026-09-08 11:29:21.552158') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (624, 3, 'delete_maintenance_task', '/api/maintenance/tasks/181', '{"title": "asd"}', '172.20.0.1', '2026-09-08 11:29:23.324007') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (625, 3, 'delete_maintenance_task', '/api/maintenance/tasks/180', '{"title": "asd"}', '172.20.0.1', '2026-09-08 11:29:25.410405') ON CONFLICT DO NOTHING;
INSERT INTO public.audit_log VALUES (626, 3, 'delete_maintenance_task', '/api/maintenance/tasks/179', '{"title": "asd"}', '172.20.0.1', '2026-09-08 11:29:27.268546') ON CONFLICT DO NOTHING;


--
-- Data for Name: maintenance_tasks; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.maintenance_tasks VALUES (76, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-05 12:00:00', true, 'daily', '[]', '2026-09-07 10:53:21.59', 10, 10, '2026-09-04 11:10:15.280025', '2026-09-07 07:53:21.590787', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (75, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-05 12:00:00', true, 'daily', '[]', '2026-09-07 10:53:24.912', 10, 10, '2026-09-04 11:10:13.027129', '2026-09-07 07:53:24.913002', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (20, 'Actualización de Drivers, analisis con antivirus, verificar configuraciones.', 'Tarea de Rodolfo, mantenimiento de computadoras', 'medium', 'General', 'Ciudad', NULL, 'pending', '2026-09-26 00:00:00', true, 'biweekly', '[{"id": "chk_1788350990613_724", "done": false, "text": "Drivers", "done_at": null, "done_by": null}, {"id": "chk_1788350994830_358", "done": false, "text": "Antivirus", "done_at": null, "done_by": null}, {"id": "chk_1788351002205_219", "done": false, "text": "Accesos directos a sistemas", "done_at": null, "done_by": null}, {"id": "chk_1788351019382_412", "done": false, "text": "Limpieza ( si es requerido )", "done_at": null, "done_by": null}, {"id": "chk_1788351029702_325", "done": false, "text": "Verificar cableados y periféricos", "done_at": null, "done_by": null}]', NULL, NULL, 3, '2026-09-02 09:10:32.510755', '2026-09-08 07:59:11.985292', 'Sistemas', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (78, 'Aire Acond. Alto/Bajo limpieza', 'lavar las unidad exterior de los aires acondicionado de bajo campo y alto campo.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-07 00:00:00', true, 'monthly', '[]', '2026-09-07 14:13:10.173', 10, 10, '2026-09-04 11:18:07.52891', '2026-09-07 11:13:10.174078', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (59, 'Aire Acond. Central', 'Lavado y limpieza de filtros

--Mejorar la eficiencia: Permite que el aire circule libremente, haciendo que el equipo enfríe más rápido y gaste menos electricidad.

--Proteger el compresor: Evita que el sistema trabaje forzado por falta de flujo de aire, lo que previene sobrecalentamientos y averías costosas.', 'medium', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-15 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-02 12:15:20.198291', '2026-09-02 12:15:20.198291', 'Mantenimiento', NULL);
INSERT INTO public.maintenance_tasks VALUES (62, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'daily', '[]', '2026-09-03 17:59:38.07', 10, 10, '2026-09-03 14:59:33.185741', '2026-09-03 14:59:38.070343', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (63, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-02 03:00:00', true, 'daily', '[]', '2026-09-03 17:59:40.376', 10, 10, '2026-09-03 14:59:38.092829', '2026-09-03 14:59:40.376442', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (65, 'SEPI Limpieza y lavado', 'lavado y limpieza de los modulos del sepi para mantener eficiente y sin sobrecalentamiento el sistema', 'medium', 'General', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'monthly', '[]', '2026-09-03 18:06:54.651', 10, 10, '2026-09-03 15:06:51.835842', '2026-09-03 15:06:54.652142', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (66, 'SEPI Limpieza y lavado', 'lavado y limpieza de los modulos del sepi para mantener eficiente y sin sobrecalentamiento el sistema', 'medium', 'General', 'Ciudad', NULL, 'pending', '2026-10-01 03:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-03 15:06:54.675884', '2026-09-03 15:06:54.675884', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (67, 'SEPI rotacion de bombas', 'intercambiar el uso del funcionamiento de las bombas cada 15 dias
para prevenir 
--Desgaste equitativo: Distribuye las horas de uso por igual entre la bomba principal y la de reserva, evitando que una trabaje de más y la otra sufra por inactividad.
--Detección temprana de fallas: Permite identificar anomalías, ruidos o problemas en la bomba de respaldo antes de que se necesite usar en una emergencia.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'biweekly', '[]', '2026-09-03 18:13:40.864', 10, 10, '2026-09-03 15:12:36.279728', '2026-09-03 15:13:40.864403', 'Mantenimiento', NULL);
INSERT INTO public.maintenance_tasks VALUES (68, 'SEPI rotacion de bombas', 'intercambiar el uso del funcionamiento de las bombas cada 15 dias
para prevenir 
--Desgaste equitativo: Distribuye las horas de uso por igual entre la bomba principal y la de reserva, evitando que una trabaje de más y la otra sufra por inactividad.
--Detección temprana de fallas: Permite identificar anomalías, ruidos o problemas en la bomba de respaldo antes de que se necesite usar en una emergencia.', 'medium', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-15 03:00:00', true, 'biweekly', '[]', NULL, NULL, 10, '2026-09-03 15:13:40.890085', '2026-09-03 15:13:40.890085', 'Mantenimiento', NULL);
INSERT INTO public.maintenance_tasks VALUES (64, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-03 06:00:00', true, 'daily', '[]', '2026-09-04 13:58:42.649', 10, 10, '2026-09-03 14:59:40.406367', '2026-09-04 10:58:42.651038', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (71, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'daily', '[]', '2026-09-04 14:10:02.846', 10, 10, '2026-09-04 11:09:59.557819', '2026-09-04 11:10:02.846672', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (72, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-02 03:00:00', true, 'daily', '[]', '2026-09-04 14:10:08.791', 10, 10, '2026-09-04 11:10:02.906626', '2026-09-04 11:10:08.7913', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (73, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-03 06:00:00', true, 'daily', '[]', '2026-09-04 14:10:10.552', 10, 10, '2026-09-04 11:10:08.848907', '2026-09-04 11:10:10.552829', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (74, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-04 09:00:00', true, 'daily', '[]', '2026-09-04 14:10:12.999', 10, 10, '2026-09-04 11:10:10.571201', '2026-09-04 11:10:12.999417', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (70, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-04 09:00:00', true, 'daily', '[]', '2026-09-04 14:10:15.261', 10, 10, '2026-09-04 10:58:42.686759', '2026-09-04 11:10:15.262059', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (79, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'low', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'daily', '[]', '2026-09-04 14:19:59.347', 10, 10, '2026-09-04 11:19:49.686784', '2026-09-04 11:19:59.348169', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (80, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'low', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-02 03:00:00', true, 'daily', '[]', '2026-09-04 14:20:17.148', 10, 10, '2026-09-04 11:19:59.380077', '2026-09-04 11:20:17.148905', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (92, 'Grupo Electrógeno limpieza', 'Limpieza', 'low', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-11 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-04 13:12:36.560289', '2026-09-04 13:12:36.560289', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (81, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'low', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-03 06:00:00', true, 'daily', '[]', '2026-09-04 14:20:21.649', 10, 10, '2026-09-04 11:20:17.166959', '2026-09-04 11:20:21.649826', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (82, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'low', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-04 09:00:00', true, 'daily', '[]', '2026-09-04 14:20:27.926', 10, 10, '2026-09-04 11:20:21.681415', '2026-09-04 11:20:27.92658', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (93, 'Grupo Electrógeno', 'Control líquido refrigerante y aceite', 'medium', 'General', 'Todas', NULL, 'completed', '2026-09-02 00:00:00', true, 'biweekly', '[]', '2026-09-04 16:13:20.056', 10, 10, '2026-09-04 13:13:15.997632', '2026-09-04 13:13:20.056778', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (94, 'Grupo Electrógeno', 'Control líquido refrigerante y aceite', 'medium', 'General', 'Todas', NULL, 'pending', '2026-09-16 03:00:00', true, 'biweekly', '[]', NULL, NULL, 10, '2026-09-04 13:13:20.082498', '2026-09-04 13:13:20.082498', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (97, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas', 'medium', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-03 06:00:00', true, 'daily', '[]', '2026-09-04 16:15:59.186', 10, 10, '2026-09-04 13:15:52.420995', '2026-09-04 13:15:59.18666', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (83, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común.', 'low', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-05 12:00:00', true, 'daily', '[]', '2026-09-07 10:53:20.093', 10, 10, '2026-09-04 11:20:27.948148', '2026-09-07 07:53:20.093423', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (107, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-07 00:00:00', true, 'daily', '[]', '2026-09-07 14:12:29.514', 10, 10, '2026-09-07 07:53:32.907457', '2026-09-07 11:12:29.515021', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (139, 'Aire Acond. Alto/Bajo limpieza', 'lavar las unidad exterior de los aires acondicionado de bajo campo y alto campo.', 'medium', 'Climatización', 'Ciudad', NULL, 'pending', '2026-10-07 03:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:13:10.200804', '2026-09-07 11:13:10.200804', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (140, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común..', 'low', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-08 03:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:13:21.551627', '2026-09-07 11:13:21.551627', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (105, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común..', 'medium', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-07 00:00:00', true, 'daily', '[]', '2026-09-07 14:13:43.507', 10, 10, '2026-09-07 07:53:28.724266', '2026-09-07 11:13:43.507545', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (146, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-04 09:00:00', true, 'daily', '[]', '2026-09-07 14:16:17.211', 10, 10, '2026-09-07 11:16:15.734642', '2026-09-07 11:16:17.211158', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (147, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-05 12:00:00', true, 'daily', '[]', '2026-09-07 14:16:19.121', 10, 10, '2026-09-07 11:16:17.234707', '2026-09-07 11:16:19.122488', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (149, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'pending', '2026-09-08 18:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:16:25.330101', '2026-09-07 11:16:25.330101', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (152, 'Aires Split General', 'limpieza de los filtros de todos los split del edificio.', 'low', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-21 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:24:09.417271', '2026-09-07 11:24:09.417271', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (153, 'Aires Patio 2° piso limpieza', 'lavado de las unidades del segundo piso que son de brivo', 'medium', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-19 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:25:20.879584', '2026-09-07 11:25:20.879584', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (154, 'Luces de emergencia control', 'controla mensual de luces de emergencia para controlar que estén funcionando o remplazar las que estén falladas', 'low', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-04 00:00:00', true, 'monthly', '[]', '2026-09-07 14:26:30.682', 10, 10, '2026-09-07 11:26:26.543804', '2026-09-07 11:26:30.682385', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (155, 'Luces de emergencia control', 'controla mensual de luces de emergencia para controlar que estén funcionando o remplazar las que estén falladas', 'low', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-10-04 03:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:26:30.705124', '2026-09-07 11:26:30.705124', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (157, 'Tanques de agua', 'control de los tanques y cisterna', 'low', 'Infraestructura', 'Ciudad', NULL, 'pending', '2026-09-23 00:00:00', true, 'biweekly', '[]', NULL, NULL, 10, '2026-09-07 11:28:25.488967', '2026-09-07 11:28:25.488967', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (158, 'Tanques de agua flotante', 'control de las bombas de sistema de agua', 'low', 'Infraestructura', 'Ciudad', NULL, 'pending', '2026-09-23 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:29:12.396791', '2026-09-07 11:29:12.396791', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (159, 'cloacas limpeza', 'limpieza de camara', 'low', 'Infraestructura', 'Ciudad', NULL, 'completed', '2026-09-02 00:00:00', true, 'weekly', '[]', '2026-09-07 14:30:50.404', 10, 10, '2026-09-07 11:30:47.603644', '2026-09-07 11:30:50.40431', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (160, 'cloacas limpeza', 'limpieza de camara', 'low', 'Infraestructura', 'Ciudad', NULL, 'pending', '2026-09-09 03:00:00', true, 'weekly', '[]', NULL, NULL, 10, '2026-09-07 11:30:50.425354', '2026-09-07 11:30:50.425354', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (142, 'Aire Acond. Alto/Bajo campo', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común..', 'low', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-08 00:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:13:43.529642', '2026-09-07 11:31:51.868663', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (141, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal..', 'low', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-08 00:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:13:34.340967', '2026-09-07 11:31:59.527724', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (161, 'tablero general', 'control de consumo', 'medium', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-14 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:36:32.206946', '2026-09-07 11:36:32.206946', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (21, 'Gestión de inventario, computadoras, monitores, impresoras', 'Tarea de Rodolfo', 'medium', 'General', 'Ciudad', NULL, 'pending', '2026-09-26 00:00:00', true, 'biweekly', '[{"id": "chk_1788355016367_507", "done": false, "text": "Verificar ubicaciones de PC", "done_at": null, "done_by": null}, {"id": "chk_1788355020831_844", "done": false, "text": "Componentes", "done_at": null, "done_by": null}, {"id": "chk_1788355026111_35", "done": false, "text": "Licencias", "done_at": null, "done_by": null}]', NULL, NULL, 3, '2026-09-02 10:17:34.99196', '2026-09-08 07:59:01.357505', 'Sistemas', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (167, 'n8n odonto', 'Actualización de token de sesión', 'medium', 'General', 'Todas', NULL, 'completed', '2026-09-08 00:00:00', true, 'weekly', '[]', '2026-09-08 12:14:35.796', 3, 3, '2026-09-08 09:14:32.827065', '2026-09-08 09:14:35.796961', 'Sistemas', 'Rodolfo') ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (168, 'n8n odonto', 'Actualización de token de sesión', 'medium', 'General', 'Todas', NULL, 'pending', '2026-09-15 12:00:00', true, 'weekly', '[]', NULL, NULL, 3, '2026-09-08 09:14:35.824306', '2026-09-08 09:14:35.824306', 'Sistemas', 'Rodolfo') ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (169, 'Actualizaciones Docker', 'Revisar actualizaciones y changelog de Docker para mantener el sistema de contenedores actalizado', 'medium', 'General', 'Todas', NULL, 'completed', '2026-09-08 00:00:00', true, 'daily', '[]', '2026-09-08 13:04:59.39', 3, 3, '2026-09-08 10:04:55.65577', '2026-09-08 10:04:59.391206', 'Sistemas', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (85, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal.', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'daily', '[]', '2026-09-04 16:10:29.591', 10, 10, '2026-09-04 13:10:14.412089', '2026-09-04 13:10:29.591562', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (95, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas', 'medium', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'daily', '[]', '2026-09-04 16:15:50.591', 10, 10, '2026-09-04 13:15:23.59965', '2026-09-04 13:15:50.591524', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (86, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal.', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-02 03:00:00', true, 'daily', '[]', '2026-09-04 16:10:32.286', 10, 10, '2026-09-04 13:10:29.649076', '2026-09-04 13:10:32.286211', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (87, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal.', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-03 06:00:00', true, 'daily', '[]', '2026-09-04 16:10:34.171', 10, 10, '2026-09-04 13:10:32.310751', '2026-09-04 13:10:34.171853', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (96, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas', 'medium', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-02 03:00:00', true, 'daily', '[]', '2026-09-04 16:15:52.386', 10, 10, '2026-09-04 13:15:50.622476', '2026-09-04 13:15:52.386805', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (88, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal.', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-04 09:00:00', true, 'daily', '[]', '2026-09-04 16:10:35.956', 10, 10, '2026-09-04 13:10:34.192475', '2026-09-04 13:10:35.956562', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (90, 'Grupo Electrógeno arranque', 'control de Control arranque automático los martes', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'weekly', '[]', '2026-09-04 16:11:40.065', 10, 10, '2026-09-04 13:11:35.714562', '2026-09-04 13:11:40.065924', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (98, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas', 'medium', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-04 09:00:00', true, 'daily', '[]', '2026-09-04 16:16:01.262', 10, 10, '2026-09-04 13:15:59.215159', '2026-09-04 13:16:01.26278', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (99, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas', 'medium', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-05 12:00:00', true, 'daily', '[]', '2026-09-07 10:53:17.792', 10, 10, '2026-09-04 13:16:01.357047', '2026-09-07 07:53:17.794148', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (144, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-02 03:00:00', true, 'daily', '[]', '2026-09-07 14:16:14.062', 10, 10, '2026-09-07 11:16:12.408237', '2026-09-07 11:16:14.063122', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (89, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal.', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-05 12:00:00', true, 'daily', '[]', '2026-09-07 10:53:23.064', 10, 10, '2026-09-04 13:10:35.976169', '2026-09-07 07:53:23.064604', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (109, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas.', 'medium', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-07 00:00:00', true, 'daily', '[]', '2026-09-07 14:12:56.513', 10, 10, '2026-09-07 07:53:37.37405', '2026-09-07 11:12:56.513944', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (106, 'control Grupo Electrógeno', 'Control diario de grupo electrógeno: Inspección general del equipo para verificar que todo se encuentre en orden, sin fugas, sin alarmas en el tablero y libre de cualquier condición extraña o fuera de lo normal..', 'medium', 'Electricidad', 'Ciudad', NULL, 'completed', '2026-09-07 00:00:00', true, 'daily', '[]', '2026-09-07 14:13:34.315', 10, 10, '2026-09-07 07:53:30.782627', '2026-09-07 11:13:34.315322', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (108, 'CONTROL Aire Acond. Central', '--Control de ruidos y vibraciones: Escuchar el funcionamiento de los compresores y motores para detectar ruidos metálicos, zumbidos extraños o vibraciones fuera de lo común..', 'low', 'Climatización', 'Ciudad', NULL, 'completed', '2026-09-07 00:00:00', true, 'daily', '[]', '2026-09-07 14:13:21.518', 10, 10, '2026-09-07 07:53:35.064014', '2026-09-07 11:13:21.51831', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (143, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-01 00:00:00', true, 'daily', '[]', '2026-09-07 14:16:12.387', 10, 10, '2026-09-07 11:15:47.304254', '2026-09-07 11:16:12.38808', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (145, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-03 06:00:00', true, 'daily', '[]', '2026-09-07 14:16:15.712', 10, 10, '2026-09-07 11:16:14.089376', '2026-09-07 11:16:15.712829', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (148, 'sala de maquina brivo', 'inspiccion de sala de maquina de brivo por posibles fallas', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'completed', '2026-09-07 15:00:00', true, 'daily', '[]', '2026-09-07 14:16:25.306', 10, 10, '2026-09-07 11:16:19.165124', '2026-09-07 11:16:25.306345', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (150, 'UPS', 'Control diario de temperatura e inspección rutinaria de sala y banco de baterías UPS.', 'medium', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-01 00:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:18:29.441561', '2026-09-07 11:18:29.441561', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (151, 'UPS Limpieza', 'Limpieza y limpieza filtro AA', 'medium', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-25 00:00:00', true, 'quarterly', '[]', NULL, NULL, 10, '2026-09-07 11:19:15.709931', '2026-09-07 11:19:15.709931', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (156, 'Puesta a tierra', 'humedecer las puesta tierra', 'low', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-12 00:00:00', true, 'monthly', '[]', NULL, NULL, 10, '2026-09-07 11:27:24.011168', '2026-09-07 11:27:24.011168', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (138, 'Sala de máquinas (Alto campo)', 'Control general en busca de fallas.', 'low', 'Equipos Médicos', 'Ciudad', NULL, 'pending', '2026-09-08 00:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:12:56.547219', '2026-09-07 11:32:09.638554', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (135, 'SEPI control', 'Revisión periódica de bombas de agua, tablero y filtro de agua', 'low', 'Climatización', 'Ciudad', NULL, 'pending', '2026-09-08 00:00:00', true, 'daily', '[]', NULL, NULL, 10, '2026-09-07 11:11:58.725316', '2026-09-07 11:32:16.439712', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (91, 'Grupo Electrógeno arranque', 'control de Control arranque automático los martes', 'medium', 'Electricidad', 'Ciudad', NULL, 'pending', '2026-09-08 00:00:00', true, 'weekly', '[]', NULL, NULL, 10, '2026-09-04 13:11:40.094122', '2026-09-07 11:32:22.791961', 'Mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (170, 'Actualizaciones Docker', 'Revisar actualizaciones y changelog de Docker para mantener el sistema de contenedores actalizado', 'medium', 'General', 'Todas', NULL, 'pending', '2026-09-09 12:00:00', true, 'daily', '[]', NULL, NULL, 3, '2026-09-08 10:04:59.448056', '2026-09-08 10:04:59.448056', 'Sistemas', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (171, 'Control de Tóners', 'Control de stock de toners', 'medium', 'General', 'Todas', NULL, 'completed', '2026-09-07 00:00:00', true, 'weekly', '[]', '2026-09-08 13:06:43.126', 3, 3, '2026-09-08 10:06:40.022716', '2026-09-08 10:06:43.126342', 'Sistemas', 'Rodolfo') ON CONFLICT DO NOTHING;
INSERT INTO public.maintenance_tasks VALUES (172, 'Control de Tóners', 'Control de stock de toners', 'medium', 'General', 'Todas', NULL, 'pending', '2026-09-14 15:00:00', true, 'weekly', '[]', NULL, NULL, 3, '2026-09-08 10:06:43.150289', '2026-09-08 13:13:22.554641', 'Sistemas', 'Rodolfo') ON CONFLICT DO NOTHING;


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.notifications VALUES (271, 178, 'Mantenimiento', 'Nuevo ticket: No cierra el locker de uno de los cambiadores.', 'Alejandro Monterop ha creado un nuevo ticket', 'TKT-MLFD62NR-34B5', 'Alejandro Monterop', true, 10, '2026-02-09 14:41:29.526293', '2026-02-09 13:05:50.210617') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (95, 71, 'Mantenimiento', 'Nuevo ticket: aire acondicionado', 'franco ha creado un nuevo ticket', 'TKT-MKWJKTMF-MPRP', 'franco', true, 10, '2026-01-27 09:37:34.21497', '2026-01-27 08:57:38.685799') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (421, 253, 'Mantenimiento', 'Nuevo ticket: pintura aire acondicionado', 'franco ha creado un nuevo ticket', 'TKT-MM1ZX2LD-T35F', 'franco', true, 10, '2026-02-25 09:13:44.519397', '2026-02-25 09:13:37.258978') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (841, 483, 'Mantenimiento', 'Nuevo ticket: aire de tomo', 'franco ha creado un nuevo ticket', 'TKT-MOBHEJO0-3XI6', 'franco', true, 10, '2026-04-23 09:56:58.028477', '2026-04-23 09:52:26.262448') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (875, 501, 'Mantenimiento', 'Nuevo ticket: colocar camara en el ascensor', 'franco ha creado un nuevo ticket', 'TKT-MOIQRW97-WN9M', 'franco', true, 10, '2026-04-30 11:51:49.837012', '2026-04-28 11:49:08.884321') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (431, 258, 'Mantenimiento', 'Nuevo ticket: enchufe', 'franco ha creado un nuevo ticket', 'TKT-MM2ENS8W-ISV8', 'franco', true, 10, '2026-02-27 11:59:00.753264', '2026-02-25 16:06:18.195967') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (98, 72, 'Administrador', 'Nuevo ticket: disparador del equipo', 'MARIELA ha creado un nuevo ticket', 'TKT-MKWK8OUH-15UI', 'MARIELA', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 09:16:12.250143') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (106, 76, 'Administrador', 'Nuevo ticket: Puerta del patio pb', 'Fernando ha creado un nuevo ticket', 'TKT-MKWRMPLG-1FDR', 'Fernando', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 12:43:03.717728') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (112, 79, 'Administrador', 'Nuevo ticket: se pausa equipo por aumento de temperatura', 'gimena ha creado un nuevo ticket', 'TKT-MKWY8CWO-7Q1V', 'gimena', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 15:47:51.40903') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (311, 198, 'Sistemas', 'Nuevo ticket: Camara', 'Matias ha creado un nuevo ticket', 'TKT-MLJCX1EV-DYL4', 'Matias', true, 3, '2026-02-12 10:26:56.414869', '2026-02-12 08:09:53.399355') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (441, 263, 'Mantenimiento', 'Nuevo ticket: BIDON AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MM4VKGV1-YYWK', 'TERESA ROMO', true, 10, '2026-02-27 11:59:00.753264', '2026-02-27 09:35:09.298928') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (321, 203, 'Mantenimiento', 'Nuevo ticket: Mantenimiento y limpieza de aires en sala de maqui...', 'emmanuel muñoz ha creado un nuevo ticket', 'TKT-MLJMVVNU-VIM3', 'emmanuel muñoz', true, 10, '2026-02-12 14:46:25.17627', '2026-02-12 12:48:55.468484') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (891, 509, 'Mantenimiento', 'Nuevo ticket: bacha', 'franco ha creado un nuevo ticket', 'TKT-MOLQ3TS5-H5AS', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-04-30 13:53:44.47076') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (2, 23, 'Administrador', 'Nuevo ticket: Estante flotante', 'Rodolfo Vigon ha creado un nuevo ticket', 'TKT-MKL7S29C-C498', 'Rodolfo Vigon', true, 1, '2026-01-19 11:21:11.712346', '2026-01-19 10:41:53.15788') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (909, 518, 'Mantenimiento', 'Nuevo ticket: canilla', 'franco ha creado un nuevo ticket', 'TKT-MOX6NWJ4-9ITU', 'franco', true, 10, '2026-05-08 14:55:23.287835', '2026-05-08 14:22:42.934471') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (337, 211, 'Sistemas', 'Nuevo ticket: No funciona el sistema', 'Monica ha creado un nuevo ticket', 'TKT-MLKUK4XV-E8M8', 'Monica', true, 3, '2026-02-13 11:16:14.219224', '2026-02-13 09:11:30.699475') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (331, 208, 'Mantenimiento', 'Nuevo ticket: AIRES', 'jonatan ha creado un nuevo ticket', 'TKT-MLKRSL2E-T2G1', 'jonatan', true, 10, '2026-02-13 15:16:51.492853', '2026-02-13 07:54:07.49236') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (440, 262, 'Administrador', 'Nuevo ticket: No se puede ingresar al sistema de Mendoza.', 'Gerardo ha creado un nuevo ticket', 'TKT-MM4T9184-ROXF', 'Gerardo', true, 1, '2026-04-23 09:51:05.481381', '2026-02-27 08:30:16.591813') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (353, 219, 'Sistemas', 'Nuevo ticket: ERROR 500', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MLRWRQ77-631I', 'GASTON RENALIAS', true, 3, '2026-02-18 08:11:11.234935', '2026-02-18 07:47:47.343786') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1004, 569, 'Sistemas', 'Nuevo ticket: Computadora', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MRT8PQ60-8LH0', 'Lorena Menegon', true, 3, '2026-07-21 07:57:48.230812', '2026-07-20 10:08:09.598184') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (278, 181, 'Administrador', 'Nuevo ticket: plafón y cortina roller.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MLFISGK9-WWIP', 'pablo estrella', true, 1, '2026-02-24 11:53:28.652128', '2026-02-09 15:43:12.750481') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1, 23, 'Mantenimiento', 'Nuevo ticket: Estante flotante', 'Rodolfo Vigon ha creado un nuevo ticket', 'TKT-MKL7S29C-C498', 'Rodolfo Vigon', true, 10, '2026-01-21 08:22:16.087918', '2026-01-19 10:41:53.144915') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (17, 31, 'Mantenimiento', 'Nuevo ticket: SEPI', 'franco ha creado un nuevo ticket', 'TKT-MKLG52DO-MVZH', 'franco', true, 10, '2026-01-21 08:22:16.087918', '2026-01-19 14:35:56.754388') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (19, 32, 'Mantenimiento', 'Nuevo ticket: luces del frente', 'franco ha creado un nuevo ticket', 'TKT-MKLG6HD7-GSKE', 'franco', true, 10, '2026-01-21 08:22:16.087918', '2026-01-19 14:37:02.834223') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (25, 35, 'Mantenimiento', 'Nuevo ticket: UPS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMT9X1D-YMEJ', 'CLAUDIO', true, 10, '2026-01-21 08:22:16.087918', '2026-01-20 13:31:24.29369') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (33, 39, 'Sistemas', 'Nuevo ticket: IMPRESORA', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKO2G2Y3-K4X5', 'CLAUDIO', true, 3, '2026-01-21 10:37:13.312681', '2026-01-21 10:35:54.610588') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (21, 33, 'Sistemas', 'Nuevo ticket: CAMARA EN SALA DE MANTENIMIENTO', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMT4P7U-NZLM', 'CLAUDIO', true, 3, '2026-01-21 10:53:37.810577', '2026-01-20 13:27:20.881033') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (23, 34, 'Sistemas', 'Nuevo ticket: IMPRESORA ATADA CON ELASTIQUIN', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMT64RO-U8A4', 'CLAUDIO', true, 3, '2026-01-21 10:53:37.810577', '2026-01-20 13:28:27.689088') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (27, 36, 'Sistemas', 'Nuevo ticket: UPS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMX3ZW7-ICQY', 'CLAUDIO', true, 3, '2026-01-21 10:53:37.810577', '2026-01-20 15:18:46.53316') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (29, 37, 'Sistemas', 'Nuevo ticket: Solicitud de carpeta con clave', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MKNXSFWW-8I85', 'Guadalupe Sanchez', true, 3, '2026-01-21 10:53:37.810577', '2026-01-21 08:25:33.206693') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (31, 38, 'Sistemas', 'Nuevo ticket: Computadora Maipú', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MKNYAKEV-J8XU', 'Guadalupe Sanchez', true, 3, '2026-01-21 10:53:37.810577', '2026-01-21 08:39:38.84663') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (18, 31, 'Administrador', 'Nuevo ticket: SEPI', 'franco ha creado un nuevo ticket', 'TKT-MKLG52DO-MVZH', 'franco', true, 1, '2026-01-21 11:55:00.966154', '2026-01-19 14:35:56.763891') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (20, 32, 'Administrador', 'Nuevo ticket: luces del frente', 'franco ha creado un nuevo ticket', 'TKT-MKLG6HD7-GSKE', 'franco', true, 1, '2026-01-21 11:55:00.966154', '2026-01-19 14:37:02.84586') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (22, 33, 'Administrador', 'Nuevo ticket: CAMARA EN SALA DE MANTENIMIENTO', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMT4P7U-NZLM', 'CLAUDIO', true, 1, '2026-01-21 11:55:00.966154', '2026-01-20 13:27:20.891549') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (24, 34, 'Administrador', 'Nuevo ticket: IMPRESORA ATADA CON ELASTIQUIN', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMT64RO-U8A4', 'CLAUDIO', true, 1, '2026-01-21 11:55:00.966154', '2026-01-20 13:28:27.699309') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (26, 35, 'Administrador', 'Nuevo ticket: UPS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMT9X1D-YMEJ', 'CLAUDIO', true, 1, '2026-01-21 11:55:00.966154', '2026-01-20 13:31:24.304755') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (28, 36, 'Administrador', 'Nuevo ticket: UPS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKMX3ZW7-ICQY', 'CLAUDIO', true, 1, '2026-01-21 11:55:00.966154', '2026-01-20 15:18:46.543634') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (30, 37, 'Administrador', 'Nuevo ticket: Solicitud de carpeta con clave', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MKNXSFWW-8I85', 'Guadalupe Sanchez', true, 1, '2026-01-21 11:55:00.966154', '2026-01-21 08:25:33.220443') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (32, 38, 'Administrador', 'Nuevo ticket: Computadora Maipú', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MKNYAKEV-J8XU', 'Guadalupe Sanchez', true, 1, '2026-01-21 11:55:00.966154', '2026-01-21 08:39:38.860181') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (34, 39, 'Administrador', 'Nuevo ticket: IMPRESORA', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKO2G2Y3-K4X5', 'CLAUDIO', true, 1, '2026-01-21 11:55:00.966154', '2026-01-21 10:35:54.62389') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (43, 44, 'Mantenimiento', 'Nuevo ticket: cambiar el foco', 'mariela ha creado un nuevo ticket', 'TKT-MKPG4KNY-HYFE', 'mariela', true, 10, '2026-01-23 11:55:06.859214', '2026-01-22 09:46:38.501998') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (45, 45, 'Mantenimiento', 'Nuevo ticket: sacar cable canal', 'mariela ha creado un nuevo ticket', 'TKT-MKPG6J4F-SMWL', 'mariela', true, 10, '2026-01-23 11:55:06.859214', '2026-01-22 09:48:09.812671') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (49, 47, 'Mantenimiento', 'Nuevo ticket: pintura', 'MARIELA ha creado un nuevo ticket', 'TKT-MKPLNSJN-O43M', 'MARIELA', true, 10, '2026-01-23 11:55:06.859214', '2026-01-22 12:21:33.264535') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (51, 48, 'Mantenimiento', 'Nuevo ticket: pegar los socalos', 'MARIELA ha creado un nuevo ticket', 'TKT-MKPLQ0E2-8JFH', 'MARIELA', true, 10, '2026-01-23 11:55:06.859214', '2026-01-22 12:23:16.73365') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (53, 49, 'Mantenimiento', 'Nuevo ticket: TEMPERATURA ELEVADA', 'JORGELINA ARAYA ha creado un nuevo ticket', 'TKT-MKPNYVX7-O6I0', 'JORGELINA ARAYA', true, 10, '2026-01-23 11:55:06.859214', '2026-01-22 13:26:10.081864') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (55, 50, 'Mantenimiento', 'Nuevo ticket: picaporte', 'franco ha creado un nuevo ticket', 'TKT-MKPPF1XJ-5VR9', 'franco', true, 10, '2026-01-23 11:55:06.859214', '2026-01-22 14:06:43.987923') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (39, 42, 'Sistemas', 'Nuevo ticket: TELEFONO SIN FUNCIONAR', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MKOH4NTE-G541', 'Marcelo Castro', true, 3, '2026-01-23 11:45:16.669551', '2026-01-21 17:26:56.024354') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (41, 43, 'Sistemas', 'Nuevo ticket: REEMPLZAO DE ECOGRAFO', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKPEI33C-WFNA', 'CLAUDIO', true, 3, '2026-01-23 11:45:16.669551', '2026-01-22 09:01:09.686693') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (47, 46, 'Sistemas', 'Nuevo ticket: Obras sociales', 'Rodolfo ha creado un nuevo ticket', 'TKT-MKPI7Q7Y-G9MV', 'Rodolfo', true, 3, '2026-01-23 11:45:16.669551', '2026-01-22 10:45:04.901326') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (57, 51, 'Sistemas', 'Nuevo ticket: NO SE PUEDE INGRESAR A MAIPU', 'Monica ha creado un nuevo ticket', 'TKT-MKQQOJHP-GRD5', 'Monica', true, 3, '2026-01-23 11:45:16.669551', '2026-01-23 07:29:52.444847') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (63, 54, 'Sistemas', 'Nuevo ticket: Informe de tareas', 'Rodolfo ha creado un nuevo ticket', 'TKT-MKQZ09DU-3A26', 'Rodolfo', true, 3, '2026-01-23 11:45:16.669551', '2026-01-23 11:22:56.138998') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (65, 55, 'Sistemas', 'Nuevo ticket: NO ANDAN LOS TELEFONOS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKQZ8N7K-26WW', 'CLAUDIO', true, 3, '2026-01-23 11:45:16.669551', '2026-01-23 11:29:27.300023') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (69, 57, 'Compras e Insumos', 'Nuevo ticket: Solicitud de compra', 'Rodolfo ha creado un nuevo ticket', 'TKT-MKQZVTHS-4APK', 'Rodolfo', false, NULL, NULL, '2026-01-23 11:47:28.53408') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (279, 182, 'Mantenimiento', 'Nuevo ticket: PEDIDO BIDON AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MLGJJCZC-BXOW', 'TERESA ROMO', true, 10, '2026-02-10 11:12:04.857191', '2026-02-10 08:51:53.9995') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1119, 635, 'Sistemas', 'Nuevo ticket: No carga work list en resonador abierto', 'Javier Rios ha creado un nuevo ticket', 'TKT-MTLFM2GR-U5H8', 'Javier Rios', true, 3, '2026-09-03 09:29:45.10205', '2026-09-03 08:18:31.493755') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (59, 52, 'Mantenimiento', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MKQTBLNU-VKUV', 'franco', true, 10, '2026-01-23 11:55:06.859214', '2026-01-23 08:43:47.567893') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (61, 53, 'Mantenimiento', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MKQVOYXP-IEQX', 'franco', true, 10, '2026-01-23 11:55:06.859214', '2026-01-23 09:50:10.53058') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (67, 56, 'Mantenimiento', 'Nuevo ticket: PERDIDA DE AGUA', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKQZA7F0-X1EO', 'CLAUDIO', true, 10, '2026-01-23 11:55:06.859214', '2026-01-23 11:30:40.143516') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (72, 59, 'Compras e Insumos', 'Nuevo ticket: Compra de router', 'Rodolfo ha creado un nuevo ticket', 'TKT-MKR0DRCG-NYG6', 'Rodolfo', false, NULL, NULL, '2026-01-23 12:01:25.559235') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (285, 185, 'Mantenimiento', 'Nuevo ticket: se salio un soporte de escalera que usan pacientes...', 'gimena ha creado un nuevo ticket', 'TKT-MLGUV18S-ADWX', 'gimena', true, 10, '2026-02-10 15:32:20.069665', '2026-02-10 14:08:54.423746') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (842, 483, 'Administrador', 'Nuevo ticket: aire de tomo', 'franco ha creado un nuevo ticket', 'TKT-MOBHEJO0-3XI6', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 09:52:26.27653') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (289, 187, 'Sistemas', 'Nuevo ticket: No anda el sistema HUB', 'Monica ha creado un nuevo ticket', 'TKT-MLHYS35B-VYR9', 'Monica', true, 3, '2026-02-11 08:46:33.240638', '2026-02-11 08:46:21.563752') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (75, 61, 'Mantenimiento', 'Nuevo ticket: luz de un consultorio, baño personal', 'Fernando ha creado un nuevo ticket', 'TKT-MKR7QRA5-JQ0F', 'Fernando', true, 10, '2026-01-24 10:05:12.663809', '2026-01-23 15:27:29.31341') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (287, 186, 'Sistemas', 'Nuevo ticket: visualizador MZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MLHY6TME-77WS', 'GASTON RENALIAS', true, 3, '2026-02-11 08:49:59.413608', '2026-02-11 08:29:49.456168') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (449, 267, 'Mantenimiento', 'Nuevo ticket: CLAVO SOBRESALE LA MESA', 'VERONICA BRASILI ha creado un nuevo ticket', 'TKT-MM566Y24-R7ZM', 'VERONICA BRASILI', true, 10, '2026-03-02 09:09:32.875179', '2026-02-27 14:32:34.168811') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (301, 193, 'Mantenimiento', 'Nuevo ticket: problema de luces', 'cecilia belen alfaro ha creado un nuevo ticket', 'TKT-MLIAG8GU-Y3HL', 'cecilia belen alfaro', true, 10, '2026-02-11 15:53:09.496737', '2026-02-11 14:13:03.977437') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (422, 253, 'Administrador', 'Nuevo ticket: pintura aire acondicionado', 'franco ha creado un nuevo ticket', 'TKT-MM1ZX2LD-T35F', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-25 09:13:37.270552') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (432, 258, 'Administrador', 'Nuevo ticket: enchufe', 'franco ha creado un nuevo ticket', 'TKT-MM2ENS8W-ISV8', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-25 16:06:18.205965') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (295, 190, 'Sistemas', 'Nuevo ticket: URGENTE - GRILLA PERDIDA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MLI3VH3B-O9LQ', 'GASTON RENALIAS', true, 3, '2026-02-12 10:26:56.414869', '2026-02-11 11:08:57.682077') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (299, 192, 'Sistemas', 'Nuevo ticket: RX PANORAMICA', 'ANDREA DURAN ha creado un nuevo ticket', 'TKT-MLI7DQNC-WM71', 'ANDREA DURAN', true, 3, '2026-02-12 10:26:56.414869', '2026-02-11 12:47:08.721446') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (307, 196, 'Sistemas', 'Nuevo ticket: cambio de tonner', 'lujan claudia ha creado un nuevo ticket', 'TKT-MLJC4UQG-S71K', 'lujan claudia', true, 3, '2026-02-12 10:26:56.414869', '2026-02-12 07:47:58.383489') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (101, 74, 'Mantenimiento', 'Nuevo ticket: aires', 'franco ha creado un nuevo ticket', 'TKT-MKWOSJ6D-B8EF', 'franco', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 11:23:36.472904') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (313, 199, 'Sistemas', 'Nuevo ticket: REVISAR MAIL y CAMBIAR IDIOMA DE OFFICE', 'Orellano Lautaro ha creado un nuevo ticket', 'TKT-MLJDNFZJ-DFNC', 'Orellano Lautaro', true, 3, '2026-02-12 10:26:56.414869', '2026-02-12 08:30:25.339331') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (107, 77, 'Mantenimiento', 'Nuevo ticket: Sucursal Maipu', 'Fernando ha creado un nuevo ticket', 'TKT-MKWRON2L-TM9T', 'Fernando', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 12:44:33.747579') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (113, 80, 'Mantenimiento', 'Nuevo ticket: Dipenser', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MKXYU924-ZLOT', 'Vargas Aldana Noelia', true, 10, '2026-01-28 09:46:51.152265', '2026-01-28 08:52:39.099044') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (317, 201, 'Sistemas', 'Nuevo ticket: UPS', 'Matias ha creado un nuevo ticket', 'TKT-MLJK4HBH-6FE3', 'Matias', true, 3, '2026-02-12 11:31:54.263986', '2026-02-12 11:31:38.102581') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (115, 81, 'Mantenimiento', 'Nuevo ticket: Problemas con la luz del cambiador', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MKXZRJV3-R8MG', 'David Gutiérrez', true, 10, '2026-01-28 09:46:51.152265', '2026-01-28 09:18:32.661923') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (73, 60, 'Sistemas', 'Nuevo ticket: NO FUNCIONA WEB DE SAN MARTIN', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MKR7ORMI-PBRR', 'GASTON RENALIAS', true, 3, '2026-01-27 08:12:48.045961', '2026-01-23 15:25:56.445323') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (77, 62, 'Sistemas', 'Nuevo ticket: Sistema de San Martín', 'Gerardo ha creado un nuevo ticket', 'TKT-MKSD86IS-O01U', 'Gerardo', true, 3, '2026-01-27 08:12:48.045961', '2026-01-24 10:48:46.473575') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (79, 63, 'Sistemas', 'Nuevo ticket: Ingreso a San Martín.', 'Gerardo ha creado un nuevo ticket', 'TKT-MKSDKYUL-IW2Z', 'Gerardo', true, 3, '2026-01-27 08:12:48.045961', '2026-01-24 10:58:43.066082') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (81, 64, 'Sistemas', 'Nuevo ticket: NO PODEMOS INGRESAR A SAN MARTIN', 'Monica ha creado un nuevo ticket', 'TKT-MKV15P4B-CJNY', 'Monica', true, 3, '2026-01-27 08:12:48.045961', '2026-01-26 07:34:13.754469') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (83, 65, 'Sistemas', 'Nuevo ticket: VISUALIZADOR SAN MARTIN', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MKV1CUBW-3T6Z', 'GASTON RENALIAS', true, 3, '2026-01-27 08:12:48.045961', '2026-01-26 07:39:47.099586') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (85, 66, 'Sistemas', 'Nuevo ticket: Ingreso a San Martin', 'Gerardo ha creado un nuevo ticket', 'TKT-MKV3L277-H7PX', 'Gerardo', true, 3, '2026-01-27 08:12:48.045961', '2026-01-26 08:42:09.774227') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (87, 67, 'Sistemas', 'Nuevo ticket: Error apartado "Novedades" en la web', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MKV4PZ39-P6PO', 'Lorena Andrea Menegon', true, 3, '2026-01-27 08:12:48.045961', '2026-01-26 09:13:58.638514') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (91, 69, 'Sistemas', 'Nuevo ticket: SAN MARTIN NO SE PUEDE INGRESAR', 'Monica ha creado un nuevo ticket', 'TKT-MKWGY0VW-CHIR', 'Monica', true, 3, '2026-01-27 08:12:48.045961', '2026-01-27 07:43:55.787075') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (327, 206, 'Sistemas', 'Nuevo ticket: tenemos muchos reclamos de informes y sobre todo d...', 'facundo benito ha creado un nuevo ticket', 'TKT-MLK18LQV-CEN1', 'facundo benito', true, 3, '2026-02-13 08:14:15.512714', '2026-02-12 19:30:43.778072') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (125, 86, 'Compras e Insumos', 'Nuevo ticket: Compra de tapones de oídos  descartables para reso...', 'Estefania Gervilla ha creado un nuevo ticket', 'TKT-MKYB7H4I-BOEP', 'Estefania Gervilla', false, NULL, NULL, '2026-01-28 14:38:51.398683') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (119, 83, 'Mantenimiento', 'Nuevo ticket: poner la zapatilla de enchufes', 'mariela ha creado un nuevo ticket', 'TKT-MKY2WX3T-7Q37', 'mariela', true, 10, '2026-01-29 08:54:49.810612', '2026-01-28 10:46:41.963415') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (126, 87, 'Compras e Insumos', 'Nuevo ticket: Compra nueva PC', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MKZEXCT9-NEQT', 'Rodolfo VIgon', false, NULL, NULL, '2026-01-29 09:10:43.878762') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (343, 214, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MLL8EA8N-RO1Q', 'franco', true, 10, '2026-02-14 09:27:33.704181', '2026-02-13 15:38:52.274827') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (89, 68, 'Sistemas', 'Nuevo ticket: problema en sistema de mendoza maquina segundo pis...', 'lorena cataldo ha creado un nuevo ticket', 'TKT-MKVKFZ9C-1PF1', 'lorena cataldo', true, 3, '2026-01-27 08:12:48.045961', '2026-01-26 16:34:06.161371') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (93, 70, 'Sistemas', 'Nuevo ticket: WEB SAN MARTIN', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MKWHS4KH-W2IM', 'GASTON RENALIAS', true, 3, '2026-01-27 08:12:48.045961', '2026-01-27 08:07:20.240561') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1118, 634, 'Administrador', 'Nuevo ticket: pala', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTKDNNFE-3S9W', 'franco ortiz', false, NULL, NULL, '2026-09-02 14:35:59.925013') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (97, 72, 'Mantenimiento', 'Nuevo ticket: disparador del equipo', 'MARIELA ha creado un nuevo ticket', 'TKT-MKWK8OUH-15UI', 'MARIELA', true, 10, '2026-01-27 09:37:34.21497', '2026-01-27 09:16:12.239491') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (273, 179, 'Sistemas', 'Nuevo ticket: CONECCION A LA RED DE WORKSTATION', 'jonatan ha creado un nuevo ticket', 'TKT-MLFF45RV-3CCO', 'jonatan', true, 3, '2026-02-10 08:11:57.089687', '2026-02-09 14:00:20.161876') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (423, 254, 'Mantenimiento', 'Nuevo ticket: negatoscopio', 'franco ha creado un nuevo ticket', 'TKT-MM263P6Y-SJ4Z', 'franco', true, 10, '2026-02-25 13:56:58.111401', '2026-02-25 12:06:44.18583') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (843, 484, 'Mantenimiento', 'Nuevo ticket: Colocar tacos de goma en la camilla del eco 4', 'Federico Dalla Torre ha creado un nuevo ticket', 'TKT-MOBJ223H-1UPP', 'Federico Dalla Torre', true, 10, '2026-04-24 11:32:28.125647', '2026-04-23 10:38:42.851809') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (433, 259, 'Mantenimiento', 'Nuevo ticket: tiras led', 'franco ha creado un nuevo ticket', 'TKT-MM3DZRCN-A0DE', 'franco', true, 10, '2026-02-27 11:59:00.753264', '2026-02-26 08:35:23.465971') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1120, 635, 'Administrador', 'Nuevo ticket: No carga work list en resonador abierto', 'Javier Rios ha creado un nuevo ticket', 'TKT-MTLFM2GR-U5H8', 'Javier Rios', false, NULL, NULL, '2026-09-03 08:18:31.527298') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (443, 264, 'Mantenimiento', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MM521EZ7-9ESW', 'franco', true, 10, '2026-02-27 12:36:25.279618', '2026-02-27 12:36:17.714893') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (860, 493, 'Mantenimiento', 'Nuevo ticket: calor', 'franco ha creado un nuevo ticket', 'TKT-MOHA2T7G-1X05', 'franco', true, 10, '2026-04-27 11:16:12.854478', '2026-04-27 11:13:58.550053') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (99, 73, 'Mantenimiento', 'Nuevo ticket: lluvia agua', 'cristian ha creado un nuevo ticket', 'TKT-MKWOR9QL-HJGU', 'cristian', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 11:22:37.593123') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (103, 75, 'Mantenimiento', 'Nuevo ticket: aire central', 'franco ha creado un nuevo ticket', 'TKT-MKWQVMYU-E68F', 'franco', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 12:22:00.591178') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (109, 78, 'Mantenimiento', 'Nuevo ticket: equipo pausado por temperatura', 'gimena ha creado un nuevo ticket', 'TKT-MKWXE2BM-2DU9', 'gimena', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 15:24:17.99301') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (117, 82, 'Mantenimiento', 'Nuevo ticket: aires de patio', 'franco ha creado un nuevo ticket', 'TKT-MKY0PWOF-J0LY', 'franco', true, 10, '2026-01-28 09:46:51.152265', '2026-01-28 09:45:15.573641') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (105, 76, 'Mantenimiento', 'Nuevo ticket: Puerta del patio pb', 'Fernando ha creado un nuevo ticket', 'TKT-MKWRMPLG-1FDR', 'Fernando', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 12:43:03.706129') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (111, 79, 'Mantenimiento', 'Nuevo ticket: se pausa equipo por aumento de temperatura', 'gimena ha creado un nuevo ticket', 'TKT-MKWY8CWO-7Q1V', 'gimena', true, 10, '2026-01-28 09:46:51.152265', '2026-01-27 15:47:51.396697') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1124, 637, 'Administrador', 'Nuevo ticket: cloaca', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLTKNBC-ZVDC', 'franco ortiz', false, NULL, NULL, '2026-09-03 14:49:19.915179') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (121, 84, 'Mantenimiento', 'Nuevo ticket: colocar servilletero', 'mariela ha creado un nuevo ticket', 'TKT-MKY2YB7F-2I6M', 'mariela', true, 10, '2026-01-29 08:54:49.810612', '2026-01-28 10:47:46.883461') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (123, 85, 'Mantenimiento', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MKY5QEAA-KJFL', 'franco', true, 10, '2026-01-29 08:54:49.810612', '2026-01-28 12:05:36.472445') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (468, 277, 'Mantenimiento', 'Nuevo ticket: bolsas', 'franco ha creado un nuevo ticket', 'TKT-MM9EBH2Y-ZPXB', 'franco', true, 10, '2026-03-02 13:34:39.267053', '2026-03-02 13:31:07.069886') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (323, 204, 'Sistemas', 'Nuevo ticket: no puedo ver pedidos medicos', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MLK101WM-5RZ2', 'Gimena Soledad Manrique Olivera', true, 3, '2026-02-13 08:14:15.512714', '2026-02-12 19:24:04.810971') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (472, 279, 'Mantenimiento', 'Nuevo ticket: aire acondicionado', 'lorena cataldo ha creado un nuevo ticket', 'TKT-MM9I9CG5-HDFF', 'lorena cataldo', true, 10, '2026-03-03 08:23:34.33562', '2026-03-02 15:21:26.223326') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (127, 88, 'Sistemas', 'Nuevo ticket: Instalación de impresora', 'Romina Azeglio ha creado un nuevo ticket', 'TKT-MKZL4X0Y-PV99', 'Romina Azeglio', true, 3, '2026-01-29 14:25:07.362166', '2026-01-29 12:04:34.365187') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (333, 209, 'Mantenimiento', 'Nuevo ticket: impresora Minolta', 'pepa shirley ha creado un nuevo ticket', 'TKT-MLKT7HQX-E7NA', 'pepa shirley', true, 10, '2026-02-13 08:33:56.18706', '2026-02-13 08:33:41.150695') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1006, 570, 'Compras e Insumos', 'Nuevo ticket: caruchos de placas', 'mariela ha creado un nuevo ticket', 'TKT-MRUPPNCP-GGAU', 'mariela', false, NULL, NULL, '2026-07-21 10:51:45.603784') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (133, 91, 'Mantenimiento', 'Nuevo ticket: Cable canal', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-ML0TAIPP-LQEN', 'Rodolfo VIgon', true, 10, '2026-01-30 08:40:43.851129', '2026-01-30 08:40:38.852851') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (339, 212, 'Sistemas', 'Nuevo ticket: Sin sistema de Mendoza en compu del 4', 'Gerardo ha creado un nuevo ticket', 'TKT-MLKUUTM4-8YXV', 'Gerardo', true, 3, '2026-02-13 11:16:14.219224', '2026-02-13 09:19:49.244713') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (129, 89, 'Sistemas', 'Nuevo ticket: CAMBIO DE CABLE', 'MARIELA ha creado un nuevo ticket', 'TKT-MKZLFUYJ-LYQ0', 'MARIELA', true, 3, '2026-01-30 09:38:58.319027', '2026-01-29 12:13:04.914313') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (131, 90, 'Mantenimiento', 'Nuevo ticket: Falla de Temperatura', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MKZLYR95-7ARG', 'David Gutiérrez', true, 10, '2026-01-30 10:12:59.600789', '2026-01-29 12:27:46.561246') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (135, 92, 'Mantenimiento', 'Nuevo ticket: Llave de luz y enchufe', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML0UQXQ4-ZQMZ', 'David Gutiérrez', true, 10, '2026-01-30 10:12:59.600789', '2026-01-30 09:21:24.419577') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (137, 93, 'Sistemas', 'Nuevo ticket: No podemos ingresar al sistema de San Martín', 'Gerardo ha creado un nuevo ticket', 'TKT-ML0X5FKB-ARQP', 'Gerardo', true, 3, '2026-01-30 11:42:02.51312', '2026-01-30 10:28:39.952079') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (355, 220, 'Sistemas', 'Nuevo ticket: Vincha', 'maria jose calvo ha creado un nuevo ticket', 'TKT-MLRXI4IT-ST82', 'maria jose calvo', true, 3, '2026-02-18 08:11:11.234935', '2026-02-18 08:08:18.943018') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (486, 286, 'Mantenimiento', 'Nuevo ticket: NO FUNCIONA MOCHILA DE BAÑO DE RAYOS.', 'NATALIA JUAREZ ha creado un nuevo ticket', 'TKT-MMC1YKK7-AUY7', 'NATALIA JUAREZ', true, 10, '2026-03-04 15:48:38.237433', '2026-03-04 10:08:28.232185') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (280, 182, 'Administrador', 'Nuevo ticket: PEDIDO BIDON AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MLGJJCZC-BXOW', 'TERESA ROMO', true, 1, '2026-02-24 11:53:28.652128', '2026-02-10 08:51:54.012861') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (139, 94, 'Sistemas', 'Nuevo ticket: Telefonos no funcionan', 'SM ha creado un nuevo ticket', 'TKT-ML28TGSU-E1AO', 'SM', true, 3, '2026-01-31 08:46:34.586041', '2026-01-31 08:43:03.269412') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (141, 95, 'Sistemas', 'Nuevo ticket: No hay internet', 'Sede Maipu ha creado un nuevo ticket', 'TKT-ML28V6G3-0RXA', 'Sede Maipu', true, 3, '2026-01-31 08:46:34.586041', '2026-01-31 08:44:23.153307') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (455, 270, 'Administrador', 'Nuevo ticket: ventana de recepcion', 'franco ha creado un nuevo ticket', 'TKT-MM6GWX0Z-FVCR', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-28 12:20:28.259941') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (143, 96, 'Sistemas', 'Nuevo ticket: Servidor', 'SM ha creado un nuevo ticket', 'TKT-ML29GZS8-MIM4', 'SM', true, 3, '2026-01-31 10:11:33.334425', '2026-01-31 09:01:20.955207') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (145, 97, 'Mantenimiento', 'Nuevo ticket: Falla de Escaner', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML29YPPV-X4BV', 'David Gutiérrez', true, 10, '2026-02-02 11:35:13.110123', '2026-01-31 09:15:07.706068') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (102, 74, 'Administrador', 'Nuevo ticket: aires', 'franco ha creado un nuevo ticket', 'TKT-MKWOSJ6D-B8EF', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 11:23:36.482829') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (108, 77, 'Administrador', 'Nuevo ticket: Sucursal Maipu', 'Fernando ha creado un nuevo ticket', 'TKT-MKWRON2L-TM9T', 'Fernando', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 12:44:33.761606') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (114, 80, 'Administrador', 'Nuevo ticket: Dipenser', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MKXYU924-ZLOT', 'Vargas Aldana Noelia', true, 1, '2026-02-09 11:27:04.903521', '2026-01-28 08:52:39.111723') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (116, 81, 'Administrador', 'Nuevo ticket: Problemas con la luz del cambiador', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MKXZRJV3-R8MG', 'David Gutiérrez', true, 1, '2026-02-09 11:27:04.903521', '2026-01-28 09:18:32.67192') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (118, 82, 'Administrador', 'Nuevo ticket: aires de patio', 'franco ha creado un nuevo ticket', 'TKT-MKY0PWOF-J0LY', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-28 09:45:15.585286') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (147, 98, 'Sistemas', 'Nuevo ticket: Error al cerrar estudios', 'Romina Azeglio ha creado un nuevo ticket', 'TKT-ML2C37DS-X8R4', 'Romina Azeglio', true, 3, '2026-02-02 08:35:14.412559', '2026-01-31 10:14:36.453749') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (149, 99, 'Sistemas', 'Nuevo ticket: Error al cerrar estudios', 'Romina Azeglio ha creado un nuevo ticket', 'TKT-ML2C54QK-9HXI', 'Romina Azeglio', true, 3, '2026-02-02 08:35:14.412559', '2026-01-31 10:16:06.336514') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (151, 100, 'Sistemas', 'Nuevo ticket: Cambio de PC', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-ML2EDX5I-TIDA', 'Rodolfo VIgon', true, 3, '2026-02-02 08:35:14.412559', '2026-01-31 11:18:55.65381') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (153, 101, 'Sistemas', 'Nuevo ticket: No podemos cerrar estudios se cierra la pagina y n...', 'Monica ha creado un nuevo ticket', 'TKT-ML524CP1-MFV6', 'Monica', true, 3, '2026-02-02 08:35:14.412559', '2026-02-02 07:58:53.662612') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (155, 102, 'Sistemas', 'Nuevo ticket: SISTEMA MENDOZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML52ARV8-KL0S', 'GASTON RENALIAS', true, 3, '2026-02-02 08:35:14.412559', '2026-02-02 08:03:52.022417') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (281, 183, 'Mantenimiento', 'Nuevo ticket: columna', 'franco ha creado un nuevo ticket', 'TKT-MLGOKV56-ZNNV', 'franco', true, 10, '2026-02-10 11:13:45.766764', '2026-02-10 11:13:02.257491') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (157, 103, 'Sistemas', 'Nuevo ticket: SISTEMA MZA NO GUARDA INFOR', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML53U26V-EQT5', 'GASTON RENALIAS', true, 3, '2026-02-02 10:54:52.340727', '2026-02-02 08:46:51.423467') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (425, 255, 'Mantenimiento', 'Nuevo ticket: dicroica', 'franco ha creado un nuevo ticket', 'TKT-MM2654Z4-WBLK', 'franco', true, 10, '2026-02-25 13:56:58.111401', '2026-02-25 12:07:51.284613') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (291, 188, 'Sistemas', 'Nuevo ticket: Contraseña', 'Sede Maipu ha creado un nuevo ticket', 'TKT-MLHZJZXL-DTUI', 'Sede Maipu', true, 3, '2026-02-11 09:26:04.480272', '2026-02-11 09:08:03.761307') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (297, 191, 'Mantenimiento', 'Nuevo ticket: protector de pared para camillas', 'franco ha creado un nuevo ticket', 'TKT-MLI66VO4-5ZE9', 'franco', true, 10, '2026-02-11 13:57:15.820952', '2026-02-11 12:13:49.026617') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (161, 105, 'Sistemas', 'Nuevo ticket: No cargan imagenes', 'Sede Maipu ha creado un nuevo ticket', 'TKT-ML5DHJBW-SEDU', 'Sede Maipu', true, 3, '2026-02-02 13:49:09.274211', '2026-02-02 13:17:03.281404') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (861, 493, 'Administrador', 'Nuevo ticket: calor', 'franco ha creado un nuevo ticket', 'TKT-MOHA2T7G-1X05', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-27 11:13:58.582318') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (451, 268, 'Compras e Insumos', 'Nuevo ticket: Compra de teclado', 'Rodolfo ha creado un nuevo ticket', 'TKT-MM683HFW-0E81', 'Rodolfo', false, NULL, NULL, '2026-02-28 08:13:38.076693') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (454, 270, 'Mantenimiento', 'Nuevo ticket: ventana de recepcion', 'franco ha creado un nuevo ticket', 'TKT-MM6GWX0Z-FVCR', 'franco', true, 10, '2026-03-02 09:09:32.875179', '2026-02-28 12:20:28.236707') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (303, 194, 'Sistemas', 'Nuevo ticket: no funciona usuario en workstation', 'cecilia belen alfaro ha creado un nuevo ticket', 'TKT-MLIALO7K-27S0', 'cecilia belen alfaro', true, 3, '2026-02-12 10:26:56.414869', '2026-02-11 14:17:17.652919') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (167, 108, 'Compras e Insumos', 'Nuevo ticket: HOJAS MEMBRETADAS -IMPRESORA', 'Monica ha creado un nuevo ticket', 'TKT-ML6FZEIF-6XKJ', 'Monica', false, NULL, NULL, '2026-02-03 07:14:42.282329') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (165, 107, 'Sistemas', 'Nuevo ticket: Solicitud de reenvio de estudio CONE BEAM', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-ML5HTDU2-V375', 'Lorena Andrea Menegon', true, 3, '2026-02-03 07:53:44.331005', '2026-02-02 15:18:14.48238') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (309, 197, 'Sistemas', 'Nuevo ticket: No se pueden comenzar ni cerrar los estudios', 'jorgelina ha creado un nuevo ticket', 'TKT-MLJCFBV6-493V', 'jorgelina', true, 3, '2026-02-12 10:26:56.414869', '2026-02-12 07:56:07.173823') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (315, 200, 'Sistemas', 'Nuevo ticket: Portal Médico', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MLJGZOE3-8VS4', 'Lorena Menegon', true, 3, '2026-02-12 10:26:56.414869', '2026-02-12 10:03:54.950529') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (319, 202, 'Sistemas', 'Nuevo ticket: Automatización', 'Rodolfo ha creado un nuevo ticket', 'TKT-MLJKVHA6-4J19', 'Rodolfo', true, 3, '2026-02-12 12:32:55.775799', '2026-02-12 11:52:37.588594') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (159, 104, 'Mantenimiento', 'Nuevo ticket: tablero', 'franco ha creado un nuevo ticket', 'TKT-ML5BNBW3-LPGO', 'franco', true, 10, '2026-02-03 08:34:56.372244', '2026-02-02 12:25:34.344179') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (163, 106, 'Mantenimiento', 'Nuevo ticket: LIMPIEZA', 'ANDREA BELEN DURAN ha creado un nuevo ticket', 'TKT-ML5ERPCC-DL5S', 'ANDREA BELEN DURAN', true, 10, '2026-02-03 08:34:56.372244', '2026-02-02 13:52:57.236601') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (424, 254, 'Administrador', 'Nuevo ticket: negatoscopio', 'franco ha creado un nuevo ticket', 'TKT-MM263P6Y-SJ4Z', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-25 12:06:44.19976') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (168, 109, 'Sistemas', 'Nuevo ticket: No entran pacientes', 'Sede Ciudad ha creado un nuevo ticket', 'TKT-ML6HEEX8-3GLB', 'Sede Ciudad', true, 3, '2026-02-03 09:06:02.823192', '2026-02-03 07:54:22.229443') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (170, 110, 'Sistemas', 'Nuevo ticket: VISUALIZADOR MZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML6HWV69-3K46', 'GASTON RENALIAS', true, 3, '2026-02-03 09:06:02.823192', '2026-02-03 08:08:43.096403') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (329, 207, 'Sistemas', 'Nuevo ticket: se cayo sistema', 'jessica johanna azcurra ha creado un nuevo ticket', 'TKT-MLK1H5QQ-KRY8', 'jessica johanna azcurra', true, 3, '2026-02-13 08:14:15.512714', '2026-02-12 19:37:22.945615') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (345, 215, 'Mantenimiento', 'Nuevo ticket: tablero', 'franco ha creado un nuevo ticket', 'TKT-MLL8LTUB-AF46', 'franco', true, 10, '2026-02-14 09:27:33.704181', '2026-02-13 15:44:44.2548') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (351, 218, 'Sistemas', 'Nuevo ticket: NOS DA NUEVAMENTE ERROR 500', 'Gerardo ha creado un nuevo ticket', 'TKT-MLMHY49Z-T7LX', 'Gerardo', true, 3, '2026-02-18 08:11:11.234935', '2026-02-14 12:54:00.367814') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (359, 222, 'Sistemas', 'Nuevo ticket: clave de medical workstation', 'JORGELINA ARAYA ha creado un nuevo ticket', 'TKT-MLRZ4HZB-R8G2', 'JORGELINA ARAYA', true, 3, '2026-02-18 10:55:11.773113', '2026-02-18 08:53:42.416502') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (363, 224, 'Mantenimiento', 'Nuevo ticket: aire acondicionado', 'franco ha creado un nuevo ticket', 'TKT-MLRZW8QJ-HUCT', 'franco', true, 10, '2026-02-18 12:15:19.600485', '2026-02-18 09:15:16.801256') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (274, 179, 'Administrador', 'Nuevo ticket: CONECCION A LA RED DE WORKSTATION', 'jonatan ha creado un nuevo ticket', 'TKT-MLFF45RV-3CCO', 'jonatan', true, 1, '2026-02-24 11:53:28.652128', '2026-02-09 14:00:20.181756') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (211, 147, 'Sistemas', 'Nuevo ticket: Añadir cuenta POP3', 'ENRIQUE ha creado un nuevo ticket', 'TKT-ML6P7VWY-0R7K', 'ENRIQUE', true, 3, '2026-02-04 09:50:43.106897', '2026-02-03 11:33:14.582305') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (215, 149, 'Sistemas', 'Nuevo ticket: NO CARGA WORKLIST Y NO PASAN LAS IMAGENS A AL WEB', 'jonatan ha creado un nuevo ticket', 'TKT-ML7WZKST-JL8J', 'jonatan', true, 3, '2026-02-04 09:50:43.106897', '2026-02-04 07:58:30.046882') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (217, 150, 'Sistemas', 'Nuevo ticket: Fallo de red.', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML7XDVD6-C193', 'David Gutiérrez', true, 3, '2026-02-04 09:50:43.106897', '2026-02-04 08:09:36.931832') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (219, 151, 'Sistemas', 'Nuevo ticket: Error 404', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-ML80EISG-ZEE4', 'Lorena Andrea Menegon', true, 3, '2026-02-04 09:50:43.106897', '2026-02-04 09:34:06.12062') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (221, 152, 'Sistemas', 'Nuevo ticket: Google Drive', 'Sede Ciudad ha creado un nuevo ticket', 'TKT-ML82OU0P-C989', 'Sede Ciudad', true, 3, '2026-02-04 10:42:27.756819', '2026-02-04 10:38:06.465876') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (223, 153, 'Sistemas', 'Nuevo ticket: Equipo no conectado', 'Sede Maipu ha creado un nuevo ticket', 'TKT-ML82TAT7-2R4Y', 'Sede Maipu', true, 3, '2026-02-04 10:42:27.756819', '2026-02-04 10:41:34.872847') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (213, 148, 'Mantenimiento', 'Nuevo ticket: bolsas', 'franco ha creado un nuevo ticket', 'TKT-ML6YRZ0X-D4NZ', 'franco', true, 10, '2026-02-04 11:14:01.775845', '2026-02-03 16:00:48.280487') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (172, 111, 'Mantenimiento', 'Nuevo ticket: Área calurosa', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML6JRBTU-MH88', 'David Gutiérrez', true, 10, '2026-02-04 12:38:49.39552', '2026-02-03 09:00:23.973708') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (174, 112, 'Mantenimiento', 'Nuevo ticket: arreglar o cambiar control remoto de persiana meta...', 'Danilo Barresi ha creado un nuevo ticket', 'TKT-ML6N9VDE-B42U', 'Danilo Barresi', true, 10, '2026-02-04 12:38:49.39552', '2026-02-03 10:38:47.962652') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (156, 102, 'Administrador', 'Nuevo ticket: SISTEMA MENDOZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML52ARV8-KL0S', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 08:03:52.033465') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (158, 103, 'Administrador', 'Nuevo ticket: SISTEMA MZA NO GUARDA INFOR', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML53U26V-EQT5', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 08:46:51.434383') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (160, 104, 'Administrador', 'Nuevo ticket: tablero', 'franco ha creado un nuevo ticket', 'TKT-ML5BNBW3-LPGO', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 12:25:34.357916') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (162, 105, 'Administrador', 'Nuevo ticket: No cargan imagenes', 'Sede Maipu ha creado un nuevo ticket', 'TKT-ML5DHJBW-SEDU', 'Sede Maipu', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 13:17:03.292428') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (207, 145, 'Mantenimiento', 'Nuevo ticket: pegado de zocalos y reparacion filtraciones maipu,...', 'Danilo Barresdi ha creado un nuevo ticket', 'TKT-ML6OHBF0-XVBO', 'Danilo Barresdi', true, 10, '2026-02-04 12:38:49.39552', '2026-02-03 11:12:34.964652') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (209, 146, 'Mantenimiento', 'Nuevo ticket: cloacas', 'franco ha creado un nuevo ticket', 'TKT-ML6OQ0EW-RQ6I', 'franco', true, 10, '2026-02-04 12:38:49.39552', '2026-02-03 11:19:20.60651') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1126, 638, 'Administrador', 'Nuevo ticket: cable', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLTM2UA-BJZH', 'franco ortiz', false, NULL, NULL, '2026-09-03 14:50:26.605478') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (275, 180, 'Mantenimiento', 'Nuevo ticket: caja', 'franco ha creado un nuevo ticket', 'TKT-MLFGMGIM-I2EL', 'franco', true, 10, '2026-02-10 11:12:04.857191', '2026-02-09 14:42:33.506868') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (845, 485, 'Sistemas', 'Nuevo ticket: EQUIPO BRIVO RX', 'CAMILA SIMONE ha creado un nuevo ticket', 'TKT-MOBLK06O-QKWH', 'CAMILA SIMONE', true, 3, '2026-04-24 10:48:13.032001', '2026-04-23 11:48:39.418299') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (435, 260, 'Mantenimiento', 'Nuevo ticket: pocelanato y cinta led', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MM3LUJSG-WU7I', 'MARIANA ZAGO', true, 10, '2026-02-27 11:59:00.753264', '2026-02-26 12:15:17.304846') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (862, 494, 'Mantenimiento', 'Nuevo ticket: aire central', 'franco ha creado un nuevo ticket', 'TKT-MOHA4FLC-VNJZ', 'franco', true, 10, '2026-04-27 11:16:12.854478', '2026-04-27 11:15:14.166449') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (445, 265, 'Mantenimiento', 'Nuevo ticket: aire acondicionado de sala de espera no esta funci...', 'jonatan ha creado un nuevo ticket', 'TKT-MM53RDBD-5E1F', 'jonatan', true, 10, '2026-03-02 09:09:32.875179', '2026-02-27 13:24:28.209648') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (225, 154, 'Sistemas', 'Nuevo ticket: Intercambio', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML88U0YA-TN9I', 'Sede San Martin', true, 3, '2026-02-04 13:36:25.488311', '2026-02-04 13:30:06.429982') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (227, 155, 'Sistemas', 'Nuevo ticket: carpeta publica', 'Daniela ha creado un nuevo ticket', 'TKT-ML88YVRH-O7YL', 'Daniela', true, 3, '2026-02-04 13:36:25.488311', '2026-02-04 13:33:52.978449') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (231, 157, 'Sistemas', 'Nuevo ticket: Computadora', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML890Z0R-EK9Z', 'Sede San Martin', true, 3, '2026-02-04 13:36:25.488311', '2026-02-04 13:35:30.514017') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (452, 269, 'Mantenimiento', 'Nuevo ticket: Resonador detuvo escaneo durante examen', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MM6B642U-RV2P', 'David Gutiérrez', true, 10, '2026-03-02 09:09:32.875179', '2026-02-28 09:39:39.57975') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (456, 271, 'Sistemas', 'Nuevo ticket: Instalación de mail', 'Guada ha creado un nuevo ticket', 'TKT-MM95OS9C-CZGB', 'Guada', true, 3, '2026-03-02 09:59:44.230362', '2026-03-02 09:29:31.550842') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (879, 503, 'Mantenimiento', 'Nuevo ticket: Llave del cambiador numero 1', 'ESTEFANIA GERVILLA ha creado un nuevo ticket', 'TKT-MOJ1AWIS-78ZZ', 'ESTEFANIA GERVILLA', true, 10, '2026-04-30 11:51:49.837012', '2026-04-28 16:43:51.857599') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (229, 156, 'Mantenimiento', 'Nuevo ticket: DESPACHAR CAJAS', 'jonatan ha creado un nuevo ticket', 'TKT-ML8900KB-7H5Z', 'jonatan', true, 10, '2026-02-04 13:55:48.06059', '2026-02-04 13:34:45.85619') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (237, 160, 'Compras e Insumos', 'Nuevo ticket: NECESITAMOS CAFE Y AZUCAR', 'Monica ha creado un nuevo ticket', 'TKT-ML9BO9WN-T8IJ', 'Monica', false, NULL, NULL, '2026-02-05 07:37:23.147113') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (325, 205, 'Sistemas', 'Nuevo ticket: No se cargan las ordenes medicas.', 'Valentina ha creado un nuevo ticket', 'TKT-MLK15OEW-CJ9C', 'Valentina', true, 3, '2026-02-13 08:14:15.512714', '2026-02-12 19:28:27.261438') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (335, 210, 'Sistemas', 'Nuevo ticket: no se puede generar el QR', 'lujan claudia ha creado un nuevo ticket', 'TKT-MLKUHNBR-AU4O', 'lujan claudia', true, 3, '2026-02-13 11:16:14.219224', '2026-02-13 09:09:34.56427') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (233, 158, 'Sistemas', 'Nuevo ticket: redes', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML8958MR-7OFA', 'Sede San Martin', true, 3, '2026-02-05 08:21:19.929119', '2026-02-04 13:38:49.594113') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (235, 159, 'Sistemas', 'Nuevo ticket: Publico', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML8960OR-AM7T', 'Sede San Martin', true, 3, '2026-02-05 08:21:19.929119', '2026-02-04 13:39:25.955447') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (238, 161, 'Sistemas', 'Nuevo ticket: VISUALIZADOR MZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML9C40EB-15NE', 'GASTON RENALIAS', true, 3, '2026-02-05 08:21:19.929119', '2026-02-05 07:49:37.307338') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (240, 162, 'Sistemas', 'Nuevo ticket: VER PAQUETE OFFICE', 'Rodriguez Daniela ha creado un nuevo ticket', 'TKT-ML9CS6YT-QPE5', 'Rodriguez Daniela', true, 3, '2026-02-05 08:21:19.929119', '2026-02-05 08:08:25.55277') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (997, 564, 'Compras e Insumos', 'Nuevo ticket: CARTUCHOS DE PLACAS 2', 'MARIELA ha creado un nuevo ticket', 'TKT-MRKO116T-D4ZW', 'MARIELA', false, NULL, NULL, '2026-07-14 10:06:55.783369') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (347, 216, 'Mantenimiento', 'Nuevo ticket: Mouse roto', 'PAEZ NATALIA ha creado un nuevo ticket', 'TKT-MLL8MLLX-2B89', 'PAEZ NATALIA', true, 10, '2026-02-14 09:27:33.704181', '2026-02-13 15:45:20.236921') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (478, 282, 'Mantenimiento', 'Nuevo ticket: lockers', 'franco ha creado un nuevo ticket', 'TKT-MMAWJBJU-GU3B', 'franco', true, 10, '2026-03-04 08:38:50.792454', '2026-03-03 14:48:52.41587') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (349, 217, 'Sistemas', 'Nuevo ticket: NO HAY SISTEMA EN CIUDAD - ERROR 500', 'Gerardo ha creado un nuevo ticket', 'TKT-MLMC78L1-AA84', 'Gerardo', true, 3, '2026-02-18 08:11:11.234935', '2026-02-14 10:13:08.162479') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (341, 213, 'Sistemas', 'Nuevo ticket: GONZALEZ, ISRAEL dni	54919218. no se sube imagen a...', 'veronicappriano ha creado un nuevo ticket', 'TKT-MLL0GWF7-65Y7', 'veronicappriano', true, 3, '2026-02-18 08:11:11.234935', '2026-02-13 11:56:57.393543') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (242, 163, 'Mantenimiento', 'Nuevo ticket: Aire acondicionado', 'Vanesa Medina ha creado un nuevo ticket', 'TKT-ML9R664T-ZRNE', 'Vanesa Medina', true, 10, '2026-02-06 08:14:32.540126', '2026-02-05 14:51:12.286477') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (244, 164, 'Mantenimiento', 'Nuevo ticket: lona', 'danilo barresi ha creado un nuevo ticket', 'TKT-ML9TBZO3-DYAU', 'danilo barresi', true, 10, '2026-02-06 08:14:32.540126', '2026-02-05 15:51:43.077381') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (246, 165, 'Mantenimiento', 'Nuevo ticket: Cambio de silla', 'Martin Klimisch ha creado un nuevo ticket', 'TKT-ML9VT93W-49HQ', 'Martin Klimisch', true, 10, '2026-02-06 08:14:32.540126', '2026-02-05 17:01:07.685561') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (426, 255, 'Administrador', 'Nuevo ticket: dicroica', 'franco ha creado un nuevo ticket', 'TKT-MM2654Z4-WBLK', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-25 12:07:51.29786') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (250, 167, 'Compras e Insumos', 'Nuevo ticket: Stock de fuentes', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MLAUJC00-REN1', 'Rodolfo VIgon', false, NULL, NULL, '2026-02-06 09:13:11.427693') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (357, 221, 'Mantenimiento', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MLRY29MH-CR6H', 'franco', true, 10, '2026-02-18 12:15:19.600485', '2026-02-18 08:23:58.663778') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (361, 223, 'Mantenimiento', 'Nuevo ticket: luz baño', 'franco ha creado un nuevo ticket', 'TKT-MLRZV8S3-K8XA', 'franco', true, 10, '2026-02-18 12:15:19.600485', '2026-02-18 09:14:30.204149') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (248, 166, 'Mantenimiento', 'Nuevo ticket: CORTINA / AGUA/ PAVA ELECTRICA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MLAUJ2XN-XNFL', 'TERESA ROMO', true, 10, '2026-02-06 12:18:07.128385', '2026-02-06 09:12:59.688882') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (251, 168, 'Mantenimiento', 'Nuevo ticket: luz de emergencia', 'franco ha creado un nuevo ticket', 'TKT-MLAZ2FQK-7MGB', 'franco', true, 10, '2026-02-06 12:18:07.128385', '2026-02-06 11:20:01.20494') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (282, 183, 'Administrador', 'Nuevo ticket: columna', 'franco ha creado un nuevo ticket', 'TKT-MLGOKV56-ZNNV', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-10 11:13:02.271154') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (292, 188, 'Administrador', 'Nuevo ticket: Contraseña', 'Sede Maipu ha creado un nuevo ticket', 'TKT-MLHZJZXL-DTUI', 'Sede Maipu', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 09:08:03.774573') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (253, 169, 'Mantenimiento', 'Nuevo ticket: cartel en magnet monitor', 'GIMENA ha creado un nuevo ticket', 'TKT-MLB6R5XB-MDCR', 'GIMENA', true, 10, '2026-02-07 09:08:32.333156', '2026-02-06 14:55:12.201248') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (257, 171, 'Mantenimiento', 'Nuevo ticket: escalera', 'franco ha creado un nuevo ticket', 'TKT-MLB9A036-PN7N', 'franco', true, 10, '2026-02-07 09:08:32.333156', '2026-02-06 16:05:50.330218') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (255, 170, 'Sistemas', 'Nuevo ticket: cpu no tiene tapa', 'GIMENA ha creado un nuevo ticket', 'TKT-MLB73U9I-ILIU', 'GIMENA', true, 3, '2026-02-09 07:51:55.544172', '2026-02-06 15:05:03.613364') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (259, 172, 'Sistemas', 'Nuevo ticket: Bot', 'Claudia Lujan ha creado un nuevo ticket', 'TKT-MLF44WLK-QYUC', 'Claudia Lujan', true, 3, '2026-02-09 11:24:16.222537', '2026-02-09 08:52:59.155266') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (226, 154, 'Administrador', 'Nuevo ticket: Intercambio', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML88U0YA-TN9I', 'Sede San Martin', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 13:30:06.443141') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (228, 155, 'Administrador', 'Nuevo ticket: carpeta publica', 'Daniela ha creado un nuevo ticket', 'TKT-ML88YVRH-O7YL', 'Daniela', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 13:33:52.99101') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (230, 156, 'Administrador', 'Nuevo ticket: DESPACHAR CAJAS', 'jonatan ha creado un nuevo ticket', 'TKT-ML8900KB-7H5Z', 'jonatan', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 13:34:45.86773') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (232, 157, 'Administrador', 'Nuevo ticket: Computadora', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML890Z0R-EK9Z', 'Sede San Martin', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 13:35:30.527147') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (261, 173, 'Sistemas', 'Nuevo ticket: Prueba de campo sede', 'Usuario Prueba ha creado un nuevo ticket', 'TKT-MLF4ZFP7-PG8R', 'Usuario Prueba', true, 3, '2026-02-09 11:24:16.222537', '2026-02-09 09:16:43.590707') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (269, 177, 'Sistemas', 'Nuevo ticket: Error en ID', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MLF9EPSV-6239', 'Rodolfo VIgon', true, 3, '2026-02-09 11:24:16.222537', '2026-02-09 11:20:34.995322') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (40, 42, 'Administrador', 'Nuevo ticket: TELEFONO SIN FUNCIONAR', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MKOH4NTE-G541', 'Marcelo Castro', true, 1, '2026-02-09 11:27:04.903521', '2026-01-21 17:26:56.035527') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (42, 43, 'Administrador', 'Nuevo ticket: REEMPLZAO DE ECOGRAFO', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKPEI33C-WFNA', 'CLAUDIO', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 09:01:09.700677') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (44, 44, 'Administrador', 'Nuevo ticket: cambiar el foco', 'mariela ha creado un nuevo ticket', 'TKT-MKPG4KNY-HYFE', 'mariela', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 09:46:38.512637') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (46, 45, 'Administrador', 'Nuevo ticket: sacar cable canal', 'mariela ha creado un nuevo ticket', 'TKT-MKPG6J4F-SMWL', 'mariela', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 09:48:09.822062') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (48, 46, 'Administrador', 'Nuevo ticket: Obras sociales', 'Rodolfo ha creado un nuevo ticket', 'TKT-MKPI7Q7Y-G9MV', 'Rodolfo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 10:45:04.914001') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (50, 47, 'Administrador', 'Nuevo ticket: pintura', 'MARIELA ha creado un nuevo ticket', 'TKT-MKPLNSJN-O43M', 'MARIELA', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 12:21:33.277835') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (52, 48, 'Administrador', 'Nuevo ticket: pegar los socalos', 'MARIELA ha creado un nuevo ticket', 'TKT-MKPLQ0E2-8JFH', 'MARIELA', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 12:23:16.743973') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (54, 49, 'Administrador', 'Nuevo ticket: TEMPERATURA ELEVADA', 'JORGELINA ARAYA ha creado un nuevo ticket', 'TKT-MKPNYVX7-O6I0', 'JORGELINA ARAYA', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 13:26:10.09445') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (56, 50, 'Administrador', 'Nuevo ticket: picaporte', 'franco ha creado un nuevo ticket', 'TKT-MKPPF1XJ-5VR9', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-22 14:06:44.001255') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (58, 51, 'Administrador', 'Nuevo ticket: NO SE PUEDE INGRESAR A MAIPU', 'Monica ha creado un nuevo ticket', 'TKT-MKQQOJHP-GRD5', 'Monica', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 07:29:52.455026') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (60, 52, 'Administrador', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MKQTBLNU-VKUV', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 08:43:47.578947') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (62, 53, 'Administrador', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MKQVOYXP-IEQX', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 09:50:10.541938') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (64, 54, 'Administrador', 'Nuevo ticket: Informe de tareas', 'Rodolfo ha creado un nuevo ticket', 'TKT-MKQZ09DU-3A26', 'Rodolfo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 11:22:56.15093') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (66, 55, 'Administrador', 'Nuevo ticket: NO ANDAN LOS TELEFONOS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKQZ8N7K-26WW', 'CLAUDIO', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 11:29:27.311876') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (96, 71, 'Administrador', 'Nuevo ticket: aire acondicionado', 'franco ha creado un nuevo ticket', 'TKT-MKWJKTMF-MPRP', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 08:57:38.69777') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (68, 56, 'Administrador', 'Nuevo ticket: PERDIDA DE AGUA', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MKQZA7F0-X1EO', 'CLAUDIO', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 11:30:40.155127') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (100, 73, 'Administrador', 'Nuevo ticket: lluvia agua', 'cristian ha creado un nuevo ticket', 'TKT-MKWOR9QL-HJGU', 'cristian', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 11:22:37.60797') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (74, 60, 'Administrador', 'Nuevo ticket: NO FUNCIONA WEB DE SAN MARTIN', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MKR7ORMI-PBRR', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 15:25:56.457104') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (104, 75, 'Administrador', 'Nuevo ticket: aire central', 'franco ha creado un nuevo ticket', 'TKT-MKWQVMYU-E68F', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 12:22:00.601464') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (76, 61, 'Administrador', 'Nuevo ticket: luz de un consultorio, baño personal', 'Fernando ha creado un nuevo ticket', 'TKT-MKR7QRA5-JQ0F', 'Fernando', true, 1, '2026-02-09 11:27:04.903521', '2026-01-23 15:27:29.322971') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (78, 62, 'Administrador', 'Nuevo ticket: Sistema de San Martín', 'Gerardo ha creado un nuevo ticket', 'TKT-MKSD86IS-O01U', 'Gerardo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-24 10:48:46.483893') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (110, 78, 'Administrador', 'Nuevo ticket: equipo pausado por temperatura', 'gimena ha creado un nuevo ticket', 'TKT-MKWXE2BM-2DU9', 'gimena', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 15:24:18.003888') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (80, 63, 'Administrador', 'Nuevo ticket: Ingreso a San Martín.', 'Gerardo ha creado un nuevo ticket', 'TKT-MKSDKYUL-IW2Z', 'Gerardo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-24 10:58:43.076944') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (82, 64, 'Administrador', 'Nuevo ticket: NO PODEMOS INGRESAR A SAN MARTIN', 'Monica ha creado un nuevo ticket', 'TKT-MKV15P4B-CJNY', 'Monica', true, 1, '2026-02-09 11:27:04.903521', '2026-01-26 07:34:13.76474') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (84, 65, 'Administrador', 'Nuevo ticket: VISUALIZADOR SAN MARTIN', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MKV1CUBW-3T6Z', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-01-26 07:39:47.109913') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (86, 66, 'Administrador', 'Nuevo ticket: Ingreso a San Martin', 'Gerardo ha creado un nuevo ticket', 'TKT-MKV3L277-H7PX', 'Gerardo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-26 08:42:09.789275') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (88, 67, 'Administrador', 'Nuevo ticket: Error apartado "Novedades" en la web', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MKV4PZ39-P6PO', 'Lorena Andrea Menegon', true, 1, '2026-02-09 11:27:04.903521', '2026-01-26 09:13:58.651287') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (90, 68, 'Administrador', 'Nuevo ticket: problema en sistema de mendoza maquina segundo pis...', 'lorena cataldo ha creado un nuevo ticket', 'TKT-MKVKFZ9C-1PF1', 'lorena cataldo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-26 16:34:06.173222') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (92, 69, 'Administrador', 'Nuevo ticket: SAN MARTIN NO SE PUEDE INGRESAR', 'Monica ha creado un nuevo ticket', 'TKT-MKWGY0VW-CHIR', 'Monica', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 07:43:55.797302') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (94, 70, 'Administrador', 'Nuevo ticket: WEB SAN MARTIN', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MKWHS4KH-W2IM', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-01-27 08:07:20.246968') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (128, 88, 'Administrador', 'Nuevo ticket: Instalación de impresora', 'Romina Azeglio ha creado un nuevo ticket', 'TKT-MKZL4X0Y-PV99', 'Romina Azeglio', true, 1, '2026-02-09 11:27:04.903521', '2026-01-29 12:04:34.379642') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (120, 83, 'Administrador', 'Nuevo ticket: poner la zapatilla de enchufes', 'mariela ha creado un nuevo ticket', 'TKT-MKY2WX3T-7Q37', 'mariela', true, 1, '2026-02-09 11:27:04.903521', '2026-01-28 10:46:41.979687') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (122, 84, 'Administrador', 'Nuevo ticket: colocar servilletero', 'mariela ha creado un nuevo ticket', 'TKT-MKY2YB7F-2I6M', 'mariela', true, 1, '2026-02-09 11:27:04.903521', '2026-01-28 10:47:46.899969') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (124, 85, 'Administrador', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MKY5QEAA-KJFL', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-01-28 12:05:36.484981') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (130, 89, 'Administrador', 'Nuevo ticket: CAMBIO DE CABLE', 'MARIELA ha creado un nuevo ticket', 'TKT-MKZLFUYJ-LYQ0', 'MARIELA', true, 1, '2026-02-09 11:27:04.903521', '2026-01-29 12:13:04.924567') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (132, 90, 'Administrador', 'Nuevo ticket: Falla de Temperatura', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MKZLYR95-7ARG', 'David Gutiérrez', true, 1, '2026-02-09 11:27:04.903521', '2026-01-29 12:27:46.574739') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (134, 91, 'Administrador', 'Nuevo ticket: Cable canal', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-ML0TAIPP-LQEN', 'Rodolfo VIgon', true, 1, '2026-02-09 11:27:04.903521', '2026-01-30 08:40:38.86628') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (136, 92, 'Administrador', 'Nuevo ticket: Llave de luz y enchufe', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML0UQXQ4-ZQMZ', 'David Gutiérrez', true, 1, '2026-02-09 11:27:04.903521', '2026-01-30 09:21:24.43124') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (138, 93, 'Administrador', 'Nuevo ticket: No podemos ingresar al sistema de San Martín', 'Gerardo ha creado un nuevo ticket', 'TKT-ML0X5FKB-ARQP', 'Gerardo', true, 1, '2026-02-09 11:27:04.903521', '2026-01-30 10:28:39.963217') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (140, 94, 'Administrador', 'Nuevo ticket: Telefonos no funcionan', 'SM ha creado un nuevo ticket', 'TKT-ML28TGSU-E1AO', 'SM', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 08:43:03.284198') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (142, 95, 'Administrador', 'Nuevo ticket: No hay internet', 'Sede Maipu ha creado un nuevo ticket', 'TKT-ML28V6G3-0RXA', 'Sede Maipu', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 08:44:23.162993') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (144, 96, 'Administrador', 'Nuevo ticket: Servidor', 'SM ha creado un nuevo ticket', 'TKT-ML29GZS8-MIM4', 'SM', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 09:01:20.965527') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (146, 97, 'Administrador', 'Nuevo ticket: Falla de Escaner', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML29YPPV-X4BV', 'David Gutiérrez', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 09:15:07.717893') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (148, 98, 'Administrador', 'Nuevo ticket: Error al cerrar estudios', 'Romina Azeglio ha creado un nuevo ticket', 'TKT-ML2C37DS-X8R4', 'Romina Azeglio', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 10:14:36.467579') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (150, 99, 'Administrador', 'Nuevo ticket: Error al cerrar estudios', 'Romina Azeglio ha creado un nuevo ticket', 'TKT-ML2C54QK-9HXI', 'Romina Azeglio', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 10:16:06.346842') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (152, 100, 'Administrador', 'Nuevo ticket: Cambio de PC', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-ML2EDX5I-TIDA', 'Rodolfo VIgon', true, 1, '2026-02-09 11:27:04.903521', '2026-01-31 11:18:55.66743') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (154, 101, 'Administrador', 'Nuevo ticket: No podemos cerrar estudios se cierra la pagina y n...', 'Monica ha creado un nuevo ticket', 'TKT-ML524CP1-MFV6', 'Monica', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 07:58:55.092072') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (164, 106, 'Administrador', 'Nuevo ticket: LIMPIEZA', 'ANDREA BELEN DURAN ha creado un nuevo ticket', 'TKT-ML5ERPCC-DL5S', 'ANDREA BELEN DURAN', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 13:52:57.248568') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (166, 107, 'Administrador', 'Nuevo ticket: Solicitud de reenvio de estudio CONE BEAM', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-ML5HTDU2-V375', 'Lorena Andrea Menegon', true, 1, '2026-02-09 11:27:04.903521', '2026-02-02 15:18:14.491645') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (169, 109, 'Administrador', 'Nuevo ticket: No entran pacientes', 'Sede Ciudad ha creado un nuevo ticket', 'TKT-ML6HEEX8-3GLB', 'Sede Ciudad', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 07:54:22.242565') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (171, 110, 'Administrador', 'Nuevo ticket: VISUALIZADOR MZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML6HWV69-3K46', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 08:08:43.106778') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (173, 111, 'Administrador', 'Nuevo ticket: Área calurosa', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML6JRBTU-MH88', 'David Gutiérrez', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 09:00:23.983595') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (175, 112, 'Administrador', 'Nuevo ticket: arreglar o cambiar control remoto de persiana meta...', 'Danilo Barresi ha creado un nuevo ticket', 'TKT-ML6N9VDE-B42U', 'Danilo Barresi', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 10:38:47.97757') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (208, 145, 'Administrador', 'Nuevo ticket: pegado de zocalos y reparacion filtraciones maipu,...', 'Danilo Barresdi ha creado un nuevo ticket', 'TKT-ML6OHBF0-XVBO', 'Danilo Barresdi', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 11:12:34.975416') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (210, 146, 'Administrador', 'Nuevo ticket: cloacas', 'franco ha creado un nuevo ticket', 'TKT-ML6OQ0EW-RQ6I', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 11:19:20.615729') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (212, 147, 'Administrador', 'Nuevo ticket: Añadir cuenta POP3', 'ENRIQUE ha creado un nuevo ticket', 'TKT-ML6P7VWY-0R7K', 'ENRIQUE', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 11:33:14.592707') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (214, 148, 'Administrador', 'Nuevo ticket: bolsas', 'franco ha creado un nuevo ticket', 'TKT-ML6YRZ0X-D4NZ', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-02-03 16:00:48.29122') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (216, 149, 'Administrador', 'Nuevo ticket: NO CARGA WORKLIST Y NO PASAN LAS IMAGENS A AL WEB', 'jonatan ha creado un nuevo ticket', 'TKT-ML7WZKST-JL8J', 'jonatan', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 07:58:30.058635') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (218, 150, 'Administrador', 'Nuevo ticket: Fallo de red.', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-ML7XDVD6-C193', 'David Gutiérrez', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 08:09:36.943574') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (220, 151, 'Administrador', 'Nuevo ticket: Error 404', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-ML80EISG-ZEE4', 'Lorena Andrea Menegon', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 09:34:06.135411') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (222, 152, 'Administrador', 'Nuevo ticket: Google Drive', 'Sede Ciudad ha creado un nuevo ticket', 'TKT-ML82OU0P-C989', 'Sede Ciudad', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 10:38:06.479539') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (224, 153, 'Administrador', 'Nuevo ticket: Equipo no conectado', 'Sede Maipu ha creado un nuevo ticket', 'TKT-ML82TAT7-2R4Y', 'Sede Maipu', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 10:41:34.882784') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (234, 158, 'Administrador', 'Nuevo ticket: redes', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML8958MR-7OFA', 'Sede San Martin', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 13:38:49.606128') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (236, 159, 'Administrador', 'Nuevo ticket: Publico', 'Sede San Martin ha creado un nuevo ticket', 'TKT-ML8960OR-AM7T', 'Sede San Martin', true, 1, '2026-02-09 11:27:04.903521', '2026-02-04 13:39:25.966007') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (239, 161, 'Administrador', 'Nuevo ticket: VISUALIZADOR MZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-ML9C40EB-15NE', 'GASTON RENALIAS', true, 1, '2026-02-09 11:27:04.903521', '2026-02-05 07:49:37.31827') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (241, 162, 'Administrador', 'Nuevo ticket: VER PAQUETE OFFICE', 'Rodriguez Daniela ha creado un nuevo ticket', 'TKT-ML9CS6YT-QPE5', 'Rodriguez Daniela', true, 1, '2026-02-09 11:27:04.903521', '2026-02-05 08:08:25.56406') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (243, 163, 'Administrador', 'Nuevo ticket: Aire acondicionado', 'Vanesa Medina ha creado un nuevo ticket', 'TKT-ML9R664T-ZRNE', 'Vanesa Medina', true, 1, '2026-02-09 11:27:04.903521', '2026-02-05 14:51:12.301774') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (245, 164, 'Administrador', 'Nuevo ticket: lona', 'danilo barresi ha creado un nuevo ticket', 'TKT-ML9TBZO3-DYAU', 'danilo barresi', true, 1, '2026-02-09 11:27:04.903521', '2026-02-05 15:51:43.097374') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (247, 165, 'Administrador', 'Nuevo ticket: Cambio de silla', 'Martin Klimisch ha creado un nuevo ticket', 'TKT-ML9VT93W-49HQ', 'Martin Klimisch', true, 1, '2026-02-09 11:27:04.903521', '2026-02-05 17:01:07.696156') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (249, 166, 'Administrador', 'Nuevo ticket: CORTINA / AGUA/ PAVA ELECTRICA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MLAUJ2XN-XNFL', 'TERESA ROMO', true, 1, '2026-02-09 11:27:04.903521', '2026-02-06 09:12:59.703937') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (252, 168, 'Administrador', 'Nuevo ticket: luz de emergencia', 'franco ha creado un nuevo ticket', 'TKT-MLAZ2FQK-7MGB', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-02-06 11:20:01.220587') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (254, 169, 'Administrador', 'Nuevo ticket: cartel en magnet monitor', 'GIMENA ha creado un nuevo ticket', 'TKT-MLB6R5XB-MDCR', 'GIMENA', true, 1, '2026-02-09 11:27:04.903521', '2026-02-06 14:55:12.214503') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (256, 170, 'Administrador', 'Nuevo ticket: cpu no tiene tapa', 'GIMENA ha creado un nuevo ticket', 'TKT-MLB73U9I-ILIU', 'GIMENA', true, 1, '2026-02-09 11:27:04.903521', '2026-02-06 15:05:03.627629') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (258, 171, 'Administrador', 'Nuevo ticket: escalera', 'franco ha creado un nuevo ticket', 'TKT-MLB9A036-PN7N', 'franco', true, 1, '2026-02-09 11:27:04.903521', '2026-02-06 16:05:50.34311') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (260, 172, 'Administrador', 'Nuevo ticket: Bot', 'Claudia Lujan ha creado un nuevo ticket', 'TKT-MLF44WLK-QYUC', 'Claudia Lujan', true, 1, '2026-02-09 11:27:04.903521', '2026-02-09 08:52:59.16732') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (262, 173, 'Administrador', 'Nuevo ticket: Prueba de campo sede', 'Usuario Prueba ha creado un nuevo ticket', 'TKT-MLF4ZFP7-PG8R', 'Usuario Prueba', true, 1, '2026-02-09 11:27:04.903521', '2026-02-09 09:16:43.609808') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (270, 177, 'Administrador', 'Nuevo ticket: Error en ID', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MLF9EPSV-6239', 'Rodolfo VIgon', true, 1, '2026-02-09 11:27:04.903521', '2026-02-09 11:20:35.010219') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1122, 636, 'Administrador', 'Nuevo ticket: alarma en tablero de sepi', 'emmanuel muñoz ha creado un nuevo ticket', 'TKT-MTLJ7A1S-3TMG', 'emmanuel muñoz', false, NULL, NULL, '2026-09-03 09:58:59.994416') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (277, 181, 'Mantenimiento', 'Nuevo ticket: plafón y cortina roller.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MLFISGK9-WWIP', 'pablo estrella', true, 10, '2026-02-10 11:12:04.857191', '2026-02-09 15:43:12.739234') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (427, 256, 'Sistemas', 'Nuevo ticket: Odontologia.', 'Noelia Estefania Escobar ha creado un nuevo ticket', 'TKT-MM2ATT04-41WM', 'Noelia Estefania Escobar', true, 3, '2026-02-26 10:20:49.405128', '2026-02-25 14:19:00.643966') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (283, 184, 'Mantenimiento', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MLGPZEVZ-UXHE', 'franco', true, 10, '2026-02-10 13:55:19.203718', '2026-02-10 11:52:20.651218') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (293, 189, 'Sistemas', 'Nuevo ticket: CONFIGURACION DE IMPRESORAS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MLI0APME-LV6O', 'CLAUDIO', true, 3, '2026-02-11 09:28:59.305426', '2026-02-11 09:28:50.111114') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1136, 643, 'Administrador', 'Nuevo ticket: luces de emergencia', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTMZCQUS-U20D', 'franco ortiz', false, NULL, NULL, '2026-09-04 10:18:55.066532') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1127, 639, 'Sistemas', 'Nuevo ticket: COMPU PLANTA BAJA PUESTO NUMERO 1 RAIANO CLAUDIA', 'VANESA MEDINA ha creado un nuevo ticket', 'TKT-MTLUEIKX-LLE9', 'VANESA MEDINA', true, 3, '2026-09-04 10:33:46.827707', '2026-09-03 15:12:33.337354') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (305, 195, 'Sistemas', 'Nuevo ticket: se me cae la ventana de la computadora permanentem...', 'claudia raiano ha creado un nuevo ticket', 'TKT-MLIHLLJC-P4F2', 'claudia raiano', true, 3, '2026-02-12 10:26:56.414869', '2026-02-11 17:33:11.508174') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1128, 639, 'Administrador', 'Nuevo ticket: COMPU PLANTA BAJA PUESTO NUMERO 1 RAIANO CLAUDIA', 'VANESA MEDINA ha creado un nuevo ticket', 'TKT-MTLUEIKX-LLE9', 'VANESA MEDINA', false, NULL, NULL, '2026-09-03 15:12:33.366396') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (403, 244, 'Sistemas', 'Nuevo ticket: internos no operativos', 'florencia benavides ha creado un nuevo ticket', 'TKT-MLZ4Q8WA-5HJT', 'florencia benavides', true, 3, '2026-02-26 10:21:28.312838', '2026-02-23 09:04:58.384737') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (847, 486, 'Mantenimiento', 'Nuevo ticket: callle', 'franco ha creado un nuevo ticket', 'TKT-MOBQSYR5-GKZG', 'franco', true, 10, '2026-04-24 11:32:28.125647', '2026-04-23 14:15:35.546115') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (437, 261, 'Mantenimiento', 'Nuevo ticket: AIRE SPLIT', 'jonatan ha creado un nuevo ticket', 'TKT-MM3MIPU1-GHPR', 'jonatan', true, 10, '2026-02-27 11:59:00.753264', '2026-02-26 12:34:04.886019') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (864, 495, 'Mantenimiento', 'Nuevo ticket: sala caliente', 'franco ha creado un nuevo ticket', 'TKT-MOHAE3P6-JHJ0', 'franco', true, 10, '2026-04-27 13:01:30.769282', '2026-04-27 11:22:45.311361') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1137, 644, 'Mantenimiento', 'Nuevo ticket: ayuda', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTN0RCUV-KG63', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-04 10:58:16.313202') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (369, 227, 'Mantenimiento', 'Nuevo ticket: NECESITAMOS BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MLTLP2II-YO9D', 'TERESA ROMO', true, 10, '2026-02-19 14:25:37.736001', '2026-02-19 12:13:19.883053') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (462, 274, 'Mantenimiento', 'Nuevo ticket: cerradura de lockerts', 'jonatan ha creado un nuevo ticket', 'TKT-MM98MLYC-4XYJ', 'jonatan', true, 10, '2026-03-02 13:34:39.267053', '2026-03-02 10:51:48.90733') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (466, 276, 'Mantenimiento', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MM9EAW6M-S2GI', 'franco', true, 10, '2026-03-02 13:34:39.267053', '2026-03-02 13:30:39.998331') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (464, 275, 'Mantenimiento', 'Nuevo ticket: limpieza tamblero', 'franco ha creado un nuevo ticket', 'TKT-MM99TQYR-R02A', 'franco', true, 10, '2026-03-02 13:34:39.267053', '2026-03-02 11:25:21.611976') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (365, 225, 'Sistemas', 'Nuevo ticket: cambio de cable de audio', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MLS6P241-IEQ0', 'ROMINA AZEGLIO', true, 3, '2026-02-20 09:27:04.518596', '2026-02-18 12:25:38.941543') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (367, 226, 'Sistemas', 'Nuevo ticket: Sin Acceso', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MLTJX5Y9-LSBR', 'Lorena Menegon', true, 3, '2026-02-20 09:27:04.518596', '2026-02-19 11:23:38.350578') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (371, 228, 'Sistemas', 'Nuevo ticket: no se borra el de los pacientes ya realizados', 'cecilia alfaro ha creado un nuevo ticket', 'TKT-MLTQ237N-4HU4', 'cecilia alfaro', true, 3, '2026-02-20 09:27:04.518596', '2026-02-19 14:15:25.785522') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (375, 230, 'Sistemas', 'Nuevo ticket: limite de peso de los pacintentes de reso y tac', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MLUU5QHK-TZCP', 'MARIANA ZAGO', true, 3, '2026-02-20 09:27:04.518596', '2026-02-20 08:58:00.550435') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (458, 272, 'Mantenimiento', 'Nuevo ticket: Puerta área sistema', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MM96QDFM-JINN', 'Rodolfo VIgon', true, 10, '2026-03-02 13:34:39.267053', '2026-03-02 09:58:45.261133') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (460, 273, 'Mantenimiento', 'Nuevo ticket: Aires de Mamo y Facturacion', 'Enrique ha creado un nuevo ticket', 'TKT-MM96R45I-LF36', 'Enrique', true, 10, '2026-03-02 13:34:39.267053', '2026-03-02 09:59:19.881913') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (474, 280, 'Sistemas', 'Nuevo ticket: MICROFONO DEFECTUOSO', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MMAI9IYY-96EX', 'GASTON RENALIAS', true, 3, '2026-03-03 08:24:45.688511', '2026-03-03 08:09:20.877702') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (998, 565, 'Compras e Insumos', 'Nuevo ticket: placas de mamografia  25x30  2 cajas', 'María del Carmen ha creado un nuevo ticket', 'TKT-MRL13DWO-UXH2', 'María del Carmen', false, NULL, NULL, '2026-07-14 16:12:40.621379') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1007, 571, 'Compras e Insumos', 'Nuevo ticket: materiales', 'jonatan ha creado un nuevo ticket', 'TKT-MRUX49Y9-NYW9', 'jonatan', false, NULL, NULL, '2026-07-21 14:19:05.363543') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (490, 288, 'Mantenimiento', 'Nuevo ticket: Dispenser de agua', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MMCAAHK0-4MAE', 'Vargas Aldana Noelia', true, 10, '2026-03-04 15:48:38.237433', '2026-03-04 14:01:41.094816') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (484, 285, 'Sistemas', 'Nuevo ticket: mail', 'Vanesa Contreras ha creado un nuevo ticket', 'TKT-MMC0XSXD-FJDN', 'Vanesa Contreras', true, 3, '2026-03-05 09:02:03.241827', '2026-03-04 09:39:52.821566') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (482, 284, 'Sistemas', 'Nuevo ticket: falla en sistema', 'ledesma estefania ha creado un nuevo ticket', 'TKT-MMB2YME7-DQA6', 'ledesma estefania', true, 3, '2026-03-05 09:02:07.736015', '2026-03-03 17:48:44.011808') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (880, 503, 'Administrador', 'Nuevo ticket: Llave del cambiador numero 1', 'ESTEFANIA GERVILLA ha creado un nuevo ticket', 'TKT-MOJ1AWIS-78ZZ', 'ESTEFANIA GERVILLA', true, 1, '2026-08-29 09:20:40.458597', '2026-04-28 16:43:51.867241') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (373, 229, 'Mantenimiento', 'Nuevo ticket: IMPRESORA', 'SHIRLEY PEPA ha creado un nuevo ticket', 'TKT-MLTS08YW-RIBW', 'SHIRLEY PEPA', true, 10, '2026-02-20 12:44:54.12292', '2026-02-19 15:09:59.155808') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (377, 231, 'Mantenimiento', 'Nuevo ticket: presupuesto', 'franco ha creado un nuevo ticket', 'TKT-MLV0CEUO-GUJN', 'franco', true, 10, '2026-02-20 12:44:54.12292', '2026-02-20 11:51:09.753936') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (379, 232, 'Mantenimiento', 'Nuevo ticket: zocalos', 'franco ha creado un nuevo ticket', 'TKT-MLV0D1F8-KYV6', 'franco', true, 10, '2026-02-20 12:44:54.12292', '2026-02-20 11:51:39.000945') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (381, 233, 'Mantenimiento', 'Nuevo ticket: cartel de matafuego', 'franco ha creado un nuevo ticket', 'TKT-MLV0GQYX-STPV', 'franco', true, 10, '2026-02-20 12:44:54.12292', '2026-02-20 11:54:32.080271') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (383, 234, 'Mantenimiento', 'Nuevo ticket: tomas', 'franco ha creado un nuevo ticket', 'TKT-MLV0HSMC-7KWH', 'franco', true, 10, '2026-02-20 12:44:54.12292', '2026-02-20 11:55:20.87185') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (385, 235, 'Mantenimiento', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MLV0KL12-TDZO', 'franco', true, 10, '2026-02-20 12:44:54.12292', '2026-02-20 11:57:31.008017') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (387, 236, 'Mantenimiento', 'Nuevo ticket: aire acoindicionado', 'franco ha creado un nuevo ticket', 'TKT-MLV0LKNL-CM8B', 'franco', true, 10, '2026-02-20 12:44:54.12292', '2026-02-20 11:58:17.176274') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (494, 290, 'Mantenimiento', 'Nuevo ticket: cartel', 'franco ha creado un nuevo ticket', 'TKT-MMDOOIRQ-7Z3L', 'franco', true, 10, '2026-03-06 08:13:17.626228', '2026-03-05 13:32:16.649985') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (492, 289, 'Mantenimiento', 'Nuevo ticket: pegamento en el piso', 'franco ha creado un nuevo ticket', 'TKT-MMDONKIX-RV5L', 'franco', true, 10, '2026-03-06 08:13:17.626228', '2026-03-05 13:31:32.273523') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (496, 291, 'Mantenimiento', 'Nuevo ticket: lona', 'franco ha creado un nuevo ticket', 'TKT-MMDOQ58C-LJQ3', 'franco', true, 10, '2026-03-06 08:13:17.626228', '2026-03-05 13:33:32.418068') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (428, 256, 'Administrador', 'Nuevo ticket: Odontologia.', 'Noelia Estefania Escobar ha creado un nuevo ticket', 'TKT-MM2ATT04-41WM', 'Noelia Estefania Escobar', true, 1, '2026-04-23 09:51:05.481381', '2026-02-25 14:19:00.655497') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (391, 238, 'Mantenimiento', 'Nuevo ticket: 2 luces funcionan intermitentes dentro de resonanc...', 'sebastian ha creado un nuevo ticket', 'TKT-MLV64WC4-L92R', 'sebastian', true, 10, '2026-02-23 08:08:41.360461', '2026-02-20 14:33:16.859861') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (393, 239, 'Mantenimiento', 'Nuevo ticket: se rompió una  cerradura del Locke el segundo camb...', 'gimena manrique ha creado un nuevo ticket', 'TKT-MLVH9JGM-OWZI', 'gimena manrique', true, 10, '2026-02-23 08:08:41.360461', '2026-02-20 19:44:49.238928') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (389, 237, 'Sistemas', 'Nuevo ticket: pdf editable', 'Romina Barani ha creado un nuevo ticket', 'TKT-MLV2Q9S8-7C01', 'Romina Barani', true, 3, '2026-02-23 09:10:58.367235', '2026-02-20 12:57:55.598229') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (395, 240, 'Sistemas', 'Nuevo ticket: No hay sistema', 'Alejandro Montero ha creado un nuevo ticket', 'TKT-MLWAO5IZ-IXKP', 'Alejandro Montero', true, 3, '2026-02-23 09:10:58.367235', '2026-02-21 09:27:59.88762') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (397, 241, 'Mantenimiento', 'Nuevo ticket: lluvia', 'franco ha creado un nuevo ticket', 'TKT-MLZ4122E-WITS', 'franco', true, 10, '2026-02-23 10:46:07.670114', '2026-02-23 08:45:23.169141') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (399, 242, 'Mantenimiento', 'Nuevo ticket: tablero lluvia', 'franco ha creado un nuevo ticket', 'TKT-MLZ41Q45-X98C', 'franco', true, 10, '2026-02-23 10:46:07.670114', '2026-02-23 08:45:54.299713') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (401, 243, 'Mantenimiento', 'Nuevo ticket: FILTRACIONES POR LLUVIA', 'GERMAN VIGON ha creado un nuevo ticket', 'TKT-MLZ4AKIM-2P17', 'GERMAN VIGON', true, 10, '2026-02-23 10:46:07.670114', '2026-02-23 08:52:46.952836') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (405, 245, 'Sistemas', 'Nuevo ticket: CAMARAS.', 'jonatan ha creado un nuevo ticket', 'TKT-MLZ60XR7-7R38', 'jonatan', true, 3, '2026-02-23 11:25:10.091396', '2026-02-23 09:41:16.780109') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (407, 246, 'Mantenimiento', 'Nuevo ticket: gotea en densitometria', 'franco ha creado un nuevo ticket', 'TKT-MLZ8FCIC-56R9', 'franco', true, 10, '2026-02-23 14:09:32.280227', '2026-02-23 10:48:28.323845') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (366, 225, 'Administrador', 'Nuevo ticket: cambio de cable de audio', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MLS6P241-IEQ0', 'ROMINA AZEGLIO', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 12:25:38.955723') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (413, 249, 'Mantenimiento', 'Nuevo ticket: Arreglo de silla', 'Guada ha creado un nuevo ticket', 'TKT-MM0LMEED-8QT4', 'Guada', true, 10, '2026-02-25 08:48:40.485512', '2026-02-24 09:45:38.540242') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (429, 257, 'Mantenimiento', 'Nuevo ticket: carteleria', 'franco ha creado un nuevo ticket', 'TKT-MM2BSNMF-C6R3', 'franco', true, 10, '2026-02-25 15:35:06.733249', '2026-02-25 14:46:06.624263') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (409, 247, 'Sistemas', 'Nuevo ticket: Sistema RIS Ciudad', 'Martín Adrián Klimisch ha creado un nuevo ticket', 'TKT-MM0KCBGW-DXIQ', 'Martín Adrián Klimisch', true, 3, '2026-02-24 10:50:20.916694', '2026-02-24 09:09:48.568519') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (411, 248, 'Sistemas', 'Nuevo ticket: Sistema RIS Maipú', 'Martín Adrián Klimisch ha creado un nuevo ticket', 'TKT-MM0KGD3F-9LNJ', 'Martín Adrián Klimisch', true, 3, '2026-02-24 10:50:20.916694', '2026-02-24 09:12:57.295035') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (284, 184, 'Administrador', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MLGPZEVZ-UXHE', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-10 11:52:20.666477') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (294, 189, 'Administrador', 'Nuevo ticket: CONFIGURACION DE IMPRESORAS', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MLI0APME-LV6O', 'CLAUDIO', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 09:28:50.126227') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (306, 195, 'Administrador', 'Nuevo ticket: se me cae la ventana de la computadora permanentem...', 'claudia raiano ha creado un nuevo ticket', 'TKT-MLIHLLJC-P4F2', 'claudia raiano', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 17:33:11.520853') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (312, 198, 'Administrador', 'Nuevo ticket: Camara', 'Matias ha creado un nuevo ticket', 'TKT-MLJCX1EV-DYL4', 'Matias', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 08:09:53.410885') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (326, 205, 'Administrador', 'Nuevo ticket: No se cargan las ordenes medicas.', 'Valentina ha creado un nuevo ticket', 'TKT-MLK15OEW-CJ9C', 'Valentina', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 19:28:27.274848') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (336, 210, 'Administrador', 'Nuevo ticket: no se puede generar el QR', 'lujan claudia ha creado un nuevo ticket', 'TKT-MLKUHNBR-AU4O', 'lujan claudia', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 09:09:34.578477') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (342, 213, 'Administrador', 'Nuevo ticket: GONZALEZ, ISRAEL dni	54919218. no se sube imagen a...', 'veronicappriano ha creado un nuevo ticket', 'TKT-MLL0GWF7-65Y7', 'veronicappriano', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 11:56:57.420031') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (348, 216, 'Administrador', 'Nuevo ticket: Mouse roto', 'PAEZ NATALIA ha creado un nuevo ticket', 'TKT-MLL8MLLX-2B89', 'PAEZ NATALIA', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 15:45:20.246568') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (272, 178, 'Administrador', 'Nuevo ticket: No cierra el locker de uno de los cambiadores.', 'Alejandro Monterop ha creado un nuevo ticket', 'TKT-MLFD62NR-34B5', 'Alejandro Monterop', true, 1, '2026-02-24 11:53:28.652128', '2026-02-09 13:05:50.223233') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (322, 203, 'Administrador', 'Nuevo ticket: Mantenimiento y limpieza de aires en sala de maqui...', 'emmanuel muñoz ha creado un nuevo ticket', 'TKT-MLJMVVNU-VIM3', 'emmanuel muñoz', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 12:48:55.47988') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (332, 208, 'Administrador', 'Nuevo ticket: AIRES', 'jonatan ha creado un nuevo ticket', 'TKT-MLKRSL2E-T2G1', 'jonatan', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 07:54:07.5604') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (338, 211, 'Administrador', 'Nuevo ticket: No funciona el sistema', 'Monica ha creado un nuevo ticket', 'TKT-MLKUK4XV-E8M8', 'Monica', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 09:11:30.709817') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (354, 219, 'Administrador', 'Nuevo ticket: ERROR 500', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MLRWRQ77-631I', 'GASTON RENALIAS', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 07:47:47.355954') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (358, 221, 'Administrador', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MLRY29MH-CR6H', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 08:23:58.678493') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (286, 185, 'Administrador', 'Nuevo ticket: se salio un soporte de escalera que usan pacientes...', 'gimena ha creado un nuevo ticket', 'TKT-MLGUV18S-ADWX', 'gimena', true, 1, '2026-02-24 11:53:28.652128', '2026-02-10 14:08:54.436556') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (288, 186, 'Administrador', 'Nuevo ticket: visualizador MZA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MLHY6TME-77WS', 'GASTON RENALIAS', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 08:29:49.470636') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (290, 187, 'Administrador', 'Nuevo ticket: No anda el sistema HUB', 'Monica ha creado un nuevo ticket', 'TKT-MLHYS35B-VYR9', 'Monica', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 08:46:21.576184') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (296, 190, 'Administrador', 'Nuevo ticket: URGENTE - GRILLA PERDIDA', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MLI3VH3B-O9LQ', 'GASTON RENALIAS', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 11:08:57.69592') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (300, 192, 'Administrador', 'Nuevo ticket: RX PANORAMICA', 'ANDREA DURAN ha creado un nuevo ticket', 'TKT-MLI7DQNC-WM71', 'ANDREA DURAN', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 12:47:08.734079') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (302, 193, 'Administrador', 'Nuevo ticket: problema de luces', 'cecilia belen alfaro ha creado un nuevo ticket', 'TKT-MLIAG8GU-Y3HL', 'cecilia belen alfaro', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 14:13:03.993234') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (308, 196, 'Administrador', 'Nuevo ticket: cambio de tonner', 'lujan claudia ha creado un nuevo ticket', 'TKT-MLJC4UQG-S71K', 'lujan claudia', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 07:47:58.395419') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (314, 199, 'Administrador', 'Nuevo ticket: REVISAR MAIL y CAMBIAR IDIOMA DE OFFICE', 'Orellano Lautaro ha creado un nuevo ticket', 'TKT-MLJDNFZJ-DFNC', 'Orellano Lautaro', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 08:30:25.355365') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (318, 201, 'Administrador', 'Nuevo ticket: UPS', 'Matias ha creado un nuevo ticket', 'TKT-MLJK4HBH-6FE3', 'Matias', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 11:31:38.144167') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (328, 206, 'Administrador', 'Nuevo ticket: tenemos muchos reclamos de informes y sobre todo d...', 'facundo benito ha creado un nuevo ticket', 'TKT-MLK18LQV-CEN1', 'facundo benito', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 19:30:43.788954') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (344, 214, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MLL8EA8N-RO1Q', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 15:38:52.292083') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (350, 217, 'Administrador', 'Nuevo ticket: NO HAY SISTEMA EN CIUDAD - ERROR 500', 'Gerardo ha creado un nuevo ticket', 'TKT-MLMC78L1-AA84', 'Gerardo', true, 1, '2026-02-24 11:53:28.652128', '2026-02-14 10:13:08.177559') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (362, 223, 'Administrador', 'Nuevo ticket: luz baño', 'franco ha creado un nuevo ticket', 'TKT-MLRZV8S3-K8XA', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 09:14:30.217014') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (324, 204, 'Administrador', 'Nuevo ticket: no puedo ver pedidos medicos', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MLK101WM-5RZ2', 'Gimena Soledad Manrique Olivera', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 19:24:04.822187') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (334, 209, 'Administrador', 'Nuevo ticket: impresora Minolta', 'pepa shirley ha creado un nuevo ticket', 'TKT-MLKT7HQX-E7NA', 'pepa shirley', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 08:33:41.161344') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (340, 212, 'Administrador', 'Nuevo ticket: Sin sistema de Mendoza en compu del 4', 'Gerardo ha creado un nuevo ticket', 'TKT-MLKUUTM4-8YXV', 'Gerardo', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 09:19:49.255704') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (356, 220, 'Administrador', 'Nuevo ticket: Vincha', 'maria jose calvo ha creado un nuevo ticket', 'TKT-MLRXI4IT-ST82', 'maria jose calvo', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 08:08:18.955508') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (360, 222, 'Administrador', 'Nuevo ticket: clave de medical workstation', 'JORGELINA ARAYA ha creado un nuevo ticket', 'TKT-MLRZ4HZB-R8G2', 'JORGELINA ARAYA', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 08:53:42.429834') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (298, 191, 'Administrador', 'Nuevo ticket: protector de pared para camillas', 'franco ha creado un nuevo ticket', 'TKT-MLI66VO4-5ZE9', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 12:13:49.043317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (304, 194, 'Administrador', 'Nuevo ticket: no funciona usuario en workstation', 'cecilia belen alfaro ha creado un nuevo ticket', 'TKT-MLIALO7K-27S0', 'cecilia belen alfaro', true, 1, '2026-02-24 11:53:28.652128', '2026-02-11 14:17:17.663683') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (310, 197, 'Administrador', 'Nuevo ticket: No se pueden comenzar ni cerrar los estudios', 'jorgelina ha creado un nuevo ticket', 'TKT-MLJCFBV6-493V', 'jorgelina', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 07:56:07.198825') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (316, 200, 'Administrador', 'Nuevo ticket: Portal Médico', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MLJGZOE3-8VS4', 'Lorena Menegon', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 10:03:54.963186') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (320, 202, 'Administrador', 'Nuevo ticket: Automatización', 'Rodolfo ha creado un nuevo ticket', 'TKT-MLJKVHA6-4J19', 'Rodolfo', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 11:52:37.602827') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (330, 207, 'Administrador', 'Nuevo ticket: se cayo sistema', 'jessica johanna azcurra ha creado un nuevo ticket', 'TKT-MLK1H5QQ-KRY8', 'jessica johanna azcurra', true, 1, '2026-02-24 11:53:28.652128', '2026-02-12 19:37:22.956756') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (412, 248, 'Administrador', 'Nuevo ticket: Sistema RIS Maipú', 'Martín Adrián Klimisch ha creado un nuevo ticket', 'TKT-MM0KGD3F-9LNJ', 'Martín Adrián Klimisch', true, 1, '2026-02-24 11:53:28.652128', '2026-02-24 09:12:57.306591') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (346, 215, 'Administrador', 'Nuevo ticket: tablero', 'franco ha creado un nuevo ticket', 'TKT-MLL8LTUB-AF46', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-13 15:44:44.268538') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (352, 218, 'Administrador', 'Nuevo ticket: NOS DA NUEVAMENTE ERROR 500', 'Gerardo ha creado un nuevo ticket', 'TKT-MLMHY49Z-T7LX', 'Gerardo', true, 1, '2026-02-24 11:53:28.652128', '2026-02-14 12:54:00.379084') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (364, 224, 'Administrador', 'Nuevo ticket: aire acondicionado', 'franco ha creado un nuevo ticket', 'TKT-MLRZW8QJ-HUCT', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-18 09:15:16.813466') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (276, 180, 'Administrador', 'Nuevo ticket: caja', 'franco ha creado un nuevo ticket', 'TKT-MLFGMGIM-I2EL', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-09 14:42:33.517353') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (368, 226, 'Administrador', 'Nuevo ticket: Sin Acceso', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MLTJX5Y9-LSBR', 'Lorena Menegon', true, 1, '2026-02-24 11:53:28.652128', '2026-02-19 11:23:38.374516') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (370, 227, 'Administrador', 'Nuevo ticket: NECESITAMOS BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MLTLP2II-YO9D', 'TERESA ROMO', true, 1, '2026-02-24 11:53:28.652128', '2026-02-19 12:13:19.902062') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (372, 228, 'Administrador', 'Nuevo ticket: no se borra el de los pacientes ya realizados', 'cecilia alfaro ha creado un nuevo ticket', 'TKT-MLTQ237N-4HU4', 'cecilia alfaro', true, 1, '2026-02-24 11:53:28.652128', '2026-02-19 14:15:25.799586') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (374, 229, 'Administrador', 'Nuevo ticket: IMPRESORA', 'SHIRLEY PEPA ha creado un nuevo ticket', 'TKT-MLTS08YW-RIBW', 'SHIRLEY PEPA', true, 1, '2026-02-24 11:53:28.652128', '2026-02-19 15:09:59.169601') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (376, 230, 'Administrador', 'Nuevo ticket: limite de peso de los pacintentes de reso y tac', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MLUU5QHK-TZCP', 'MARIANA ZAGO', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 08:58:00.563262') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (378, 231, 'Administrador', 'Nuevo ticket: presupuesto', 'franco ha creado un nuevo ticket', 'TKT-MLV0CEUO-GUJN', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 11:51:09.765522') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (380, 232, 'Administrador', 'Nuevo ticket: zocalos', 'franco ha creado un nuevo ticket', 'TKT-MLV0D1F8-KYV6', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 11:51:39.006098') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (382, 233, 'Administrador', 'Nuevo ticket: cartel de matafuego', 'franco ha creado un nuevo ticket', 'TKT-MLV0GQYX-STPV', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 11:54:32.091695') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (384, 234, 'Administrador', 'Nuevo ticket: tomas', 'franco ha creado un nuevo ticket', 'TKT-MLV0HSMC-7KWH', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 11:55:20.880002') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (386, 235, 'Administrador', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MLV0KL12-TDZO', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 11:57:31.027296') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (388, 236, 'Administrador', 'Nuevo ticket: aire acoindicionado', 'franco ha creado un nuevo ticket', 'TKT-MLV0LKNL-CM8B', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 11:58:17.1892') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (390, 237, 'Administrador', 'Nuevo ticket: pdf editable', 'Romina Barani ha creado un nuevo ticket', 'TKT-MLV2Q9S8-7C01', 'Romina Barani', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 12:57:55.611201') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (392, 238, 'Administrador', 'Nuevo ticket: 2 luces funcionan intermitentes dentro de resonanc...', 'sebastian ha creado un nuevo ticket', 'TKT-MLV64WC4-L92R', 'sebastian', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 14:33:16.871503') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (394, 239, 'Administrador', 'Nuevo ticket: se rompió una  cerradura del Locke el segundo camb...', 'gimena manrique ha creado un nuevo ticket', 'TKT-MLVH9JGM-OWZI', 'gimena manrique', true, 1, '2026-02-24 11:53:28.652128', '2026-02-20 19:44:49.250427') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (396, 240, 'Administrador', 'Nuevo ticket: No hay sistema', 'Alejandro Montero ha creado un nuevo ticket', 'TKT-MLWAO5IZ-IXKP', 'Alejandro Montero', true, 1, '2026-02-24 11:53:28.652128', '2026-02-21 09:27:59.912317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (398, 241, 'Administrador', 'Nuevo ticket: lluvia', 'franco ha creado un nuevo ticket', 'TKT-MLZ4122E-WITS', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-23 08:45:23.189103') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (400, 242, 'Administrador', 'Nuevo ticket: tablero lluvia', 'franco ha creado un nuevo ticket', 'TKT-MLZ41Q45-X98C', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-23 08:45:54.365338') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (402, 243, 'Administrador', 'Nuevo ticket: FILTRACIONES POR LLUVIA', 'GERMAN VIGON ha creado un nuevo ticket', 'TKT-MLZ4AKIM-2P17', 'GERMAN VIGON', true, 1, '2026-02-24 11:53:28.652128', '2026-02-23 08:52:46.964641') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (404, 244, 'Administrador', 'Nuevo ticket: internos no operativos', 'florencia benavides ha creado un nuevo ticket', 'TKT-MLZ4Q8WA-5HJT', 'florencia benavides', true, 1, '2026-02-24 11:53:28.652128', '2026-02-23 09:04:58.394972') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (406, 245, 'Administrador', 'Nuevo ticket: CAMARAS.', 'jonatan ha creado un nuevo ticket', 'TKT-MLZ60XR7-7R38', 'jonatan', true, 1, '2026-02-24 11:53:28.652128', '2026-02-23 09:41:16.790961') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (408, 246, 'Administrador', 'Nuevo ticket: gotea en densitometria', 'franco ha creado un nuevo ticket', 'TKT-MLZ8FCIC-56R9', 'franco', true, 1, '2026-02-24 11:53:28.652128', '2026-02-23 10:48:28.334859') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (410, 247, 'Administrador', 'Nuevo ticket: Sistema RIS Ciudad', 'Martín Adrián Klimisch ha creado un nuevo ticket', 'TKT-MM0KCBGW-DXIQ', 'Martín Adrián Klimisch', true, 1, '2026-02-24 11:53:28.652128', '2026-02-24 09:09:48.582865') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (414, 249, 'Administrador', 'Nuevo ticket: Arreglo de silla', 'Guada ha creado un nuevo ticket', 'TKT-MM0LMEED-8QT4', 'Guada', true, 1, '2026-02-24 11:53:28.652128', '2026-02-24 09:45:38.551961') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1130, 640, 'Administrador', 'Nuevo ticket: baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLUMO4N-JUU2', 'franco ortiz', false, NULL, NULL, '2026-09-03 15:18:53.818375') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (849, 487, 'Mantenimiento', 'Nuevo ticket: baranda de rampa genera', 'franco ha creado un nuevo ticket', 'TKT-MOBQTY48-P1HK', 'franco', true, 10, '2026-04-24 11:32:28.125647', '2026-04-23 14:16:21.379581') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (881, 504, 'Mantenimiento', 'Nuevo ticket: porta lampara exterior y puerta sala de limpieza.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MOJ2SFFM-ZKQR', 'pablo estrella', true, 10, '2026-04-30 11:51:49.837012', '2026-04-28 17:25:29.128564') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (415, 250, 'Mantenimiento', 'Nuevo ticket: lockers', 'jonatan ha creado un nuevo ticket', 'TKT-MM0RW0DH-CEXB', 'jonatan', true, 10, '2026-02-25 08:48:40.485512', '2026-02-24 12:41:04.627406') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (897, 512, 'Mantenimiento', 'Nuevo ticket: estante', 'franco ha creado un nuevo ticket', 'TKT-MOVM29KQ-1HAU', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-05-07 11:58:14.915515') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (417, 251, 'Sistemas', 'Nuevo ticket: PUBLICO', 'SHIRLEY PEPA ha creado un nuevo ticket', 'TKT-MM0YLO3U-K7VX', 'SHIRLEY PEPA', true, 3, '2026-02-26 10:20:49.405128', '2026-02-24 15:48:59.477647') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (419, 252, 'Sistemas', 'Nuevo ticket: SIN SISTEMA', 'DAVID VIDELA ha creado un nuevo ticket', 'TKT-MM114K7H-R2O7', 'DAVID VIDELA', true, 3, '2026-02-26 10:20:49.405128', '2026-02-24 16:59:40.147346') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (911, 519, 'Sistemas', 'Nuevo ticket: No se puede ingresar a San Martin', 'Monica ha creado un nuevo ticket', 'TKT-MP16R0RV-A1JW', 'Monica', true, 3, '2026-05-12 09:03:08.663892', '2026-05-11 09:36:13.228439') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (439, 262, 'Sistemas', 'Nuevo ticket: No se puede ingresar al sistema de Mendoza.', 'Gerardo ha creado un nuevo ticket', 'TKT-MM4T9184-ROXF', 'Gerardo', true, 3, '2026-02-28 08:01:53.386497', '2026-02-27 08:30:16.576577') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (447, 266, 'Mantenimiento', 'Nuevo ticket: SILLA', 'VERONICA POBLETE ha creado un nuevo ticket', 'TKT-MM564NA9-8MGI', 'VERONICA POBLETE', true, 10, '2026-03-02 09:09:32.875179', '2026-02-27 14:30:46.900857') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (915, 521, 'Mantenimiento', 'Nuevo ticket: refrigerante', 'franco ha creado un nuevo ticket', 'TKT-MP2R4MS8-FF85', 'franco', true, 10, '2026-05-14 12:06:51.303882', '2026-05-12 11:54:26.875075') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (470, 278, 'Mantenimiento', 'Nuevo ticket: carteleria de puerta', 'franco ha creado un nuevo ticket', 'TKT-MM9EWC9B-JL07', 'franco', true, 10, '2026-03-03 08:23:34.33562', '2026-03-02 13:47:20.601522') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (865, 495, 'Administrador', 'Nuevo ticket: sala caliente', 'franco ha creado un nuevo ticket', 'TKT-MOHAE3P6-JHJ0', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-27 11:22:45.321178') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (476, 281, 'Mantenimiento', 'Nuevo ticket: caño colgando', 'franco ha creado un nuevo ticket', 'TKT-MMARNAP6-Q44E', 'franco', true, 10, '2026-03-04 08:38:50.792454', '2026-03-03 12:31:59.860022') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (480, 283, 'Mantenimiento', 'Nuevo ticket: cerradura de lockers', 'franco ha creado un nuevo ticket', 'TKT-MMAWLWOG-7HYP', 'franco', true, 10, '2026-03-04 08:38:50.792454', '2026-03-03 14:50:53.115092') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (488, 287, 'Mantenimiento', 'Nuevo ticket: filtracion de agua', 'franco ha creado un nuevo ticket', 'TKT-MMC75PKG-1TV4', 'franco', true, 10, '2026-03-04 15:48:38.237433', '2026-03-04 12:33:59.366231') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (498, 292, 'Sistemas', 'Nuevo ticket: no funciona la impresora', 'claudia cataldo ha creado un nuevo ticket', 'TKT-MMDP9JM7-O82B', 'claudia cataldo', true, 3, '2026-03-09 08:14:21.906227', '2026-03-05 13:48:37.526842') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (500, 293, 'Sistemas', 'Nuevo ticket: mail', 'SHIRLEY PEPA ha creado un nuevo ticket', 'TKT-MMDTA3WB-2HUH', 'SHIRLEY PEPA', true, 3, '2026-03-09 08:14:21.906227', '2026-03-05 15:41:02.276664') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (416, 250, 'Administrador', 'Nuevo ticket: lockers', 'jonatan ha creado un nuevo ticket', 'TKT-MM0RW0DH-CEXB', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-02-24 12:41:04.645562') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (418, 251, 'Administrador', 'Nuevo ticket: PUBLICO', 'SHIRLEY PEPA ha creado un nuevo ticket', 'TKT-MM0YLO3U-K7VX', 'SHIRLEY PEPA', true, 1, '2026-04-23 09:51:05.481381', '2026-02-24 15:48:59.492468') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1138, 644, 'Administrador', 'Nuevo ticket: ayuda', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTN0RCUV-KG63', 'franco ortiz', false, NULL, NULL, '2026-09-04 10:58:16.348683') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (851, 488, 'Mantenimiento', 'Nuevo ticket: pintar', 'franco ha creado un nuevo ticket', 'TKT-MOBQUTQR-LDKR', 'franco', true, 10, '2026-04-24 11:32:28.125647', '2026-04-23 14:17:02.364208') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (502, 294, 'Mantenimiento', 'Nuevo ticket: PEDIDO AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MMEX24PC-TXMT', 'TERESA ROMO', true, 10, '2026-03-06 13:58:40.865926', '2026-03-06 10:14:34.722716') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (504, 295, 'Mantenimiento', 'Nuevo ticket: techo', 'franco ha creado un nuevo ticket', 'TKT-MMF3352P-NUM9', 'franco', true, 10, '2026-03-06 13:58:40.865926', '2026-03-06 13:03:19.5448') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1131, 641, 'Mantenimiento', 'Nuevo ticket: control de cemepaci', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLUO9YM-XVO7', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-03 15:20:08.709027') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (866, 496, 'Mantenimiento', 'Nuevo ticket: No funciona el aire acondicionado. Ya cambié las p...', 'Gerardo ha creado un nuevo ticket', 'TKT-MOHAQWLA-3ZQ7', 'Gerardo', true, 10, '2026-04-27 13:01:30.769282', '2026-04-27 11:32:42.630129') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (917, 522, 'Mantenimiento', 'Nuevo ticket: focos', 'jonatan ha creado un nuevo ticket', 'TKT-MP71FJYR-H0IJ', 'jonatan', true, 10, '2026-05-18 08:25:46.780993', '2026-05-15 11:53:57.267054') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (937, 532, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MPFF4X6C-JXQK', 'franco', true, 10, '2026-05-21 10:18:51.726715', '2026-05-21 08:39:45.064346') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (939, 533, 'Mantenimiento', 'Nuevo ticket: filtros de aires acondicionados', 'franco ha creado un nuevo ticket', 'TKT-MPFHIHY4-NFUX', 'franco', true, 10, '2026-05-21 10:18:51.726715', '2026-05-21 09:46:17.75447') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (508, 297, 'Sistemas', 'Nuevo ticket: Vuelvo a reclamar sobre la impresora de transcripc...', 'Monica ha creado un nuevo ticket', 'TKT-MMF6OZ6Z-WH9N', 'Monica', true, 3, '2026-03-09 08:14:21.906227', '2026-03-06 14:44:17.21315') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (510, 298, 'Sistemas', 'Nuevo ticket: Revisar impresora', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MMGCCFOC-V41H', 'Guadalupe Sanchez', true, 3, '2026-03-09 08:14:21.906227', '2026-03-07 10:10:15.915724') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (512, 299, 'Sistemas', 'Nuevo ticket: impresora rota', 'claudia cataldo ha creado un nuevo ticket', 'TKT-MMGCEMLR-R02J', 'claudia cataldo', true, 3, '2026-03-09 08:14:21.906227', '2026-03-07 10:11:58.206374') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (514, 300, 'Sistemas', 'Nuevo ticket: NO FUNCIONA LA IMPRESORA DE LA OFICINA.', 'Gerardo ha creado un nuevo ticket', 'TKT-MMGE5USH-I01T', 'Gerardo', true, 3, '2026-03-09 08:14:21.906227', '2026-03-07 11:01:08.147462') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (941, 534, 'Mantenimiento', 'Nuevo ticket: cloaca', 'franco ha creado un nuevo ticket', 'TKT-MPFIPAFY-OZHD', 'franco', true, 10, '2026-05-21 13:52:15.697592', '2026-05-21 10:19:34.218482') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (999, 566, 'Compras e Insumos', 'Nuevo ticket: placas', 'María del Carmen ha creado un nuevo ticket', 'TKT-MRL167AN-6LM0', 'María del Carmen', false, NULL, NULL, '2026-07-14 16:14:51.940786') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1008, 572, 'Compras e Insumos', 'Nuevo ticket: cinta hipoalergenica TRANSPORE  4 UNIDADES', 'María del Carmen ha creado un nuevo ticket', 'TKT-MRV0ZPAA-Q2JU', 'María del Carmen', false, NULL, NULL, '2026-07-21 16:07:30.458886') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (520, 303, 'Compras e Insumos', 'Nuevo ticket: Compra RAM', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MMJ5I7ID-8RIU', 'Rodolfo VIgon', false, NULL, NULL, '2026-03-09 09:22:06.474991') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1019, 578, 'Compras e Insumos', 'Nuevo ticket: materiales', 'jonatan ha creado un nuevo ticket', 'TKT-MS4X69OY-5ERZ', 'jonatan', false, NULL, NULL, '2026-07-28 14:18:20.084654') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1027, 583, 'Sistemas', 'Nuevo ticket: publico', 'jonatan ha creado un nuevo ticket', 'TKT-MS7G1FHW-CTER', 'jonatan', true, 3, '2026-07-31 08:07:48.775154', '2026-07-30 08:41:59.549222') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (521, 304, 'Sistemas', 'Nuevo ticket: PANTALLA DE NUMERADOR Y QR', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MMJ68SJU-DV9B', 'MARIANA ZAGO', true, 3, '2026-03-09 11:54:26.410623', '2026-03-09 09:42:46.799249') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (506, 296, 'Mantenimiento', 'Nuevo ticket: almohadas', 'franco ha creado un nuevo ticket', 'TKT-MMF54DSX-W77M', 'franco', true, 10, '2026-03-09 12:34:49.369724', '2026-03-06 14:00:16.745785') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (516, 301, 'Mantenimiento', 'Nuevo ticket: tapa de gabinete', 'jonatan ha creado un nuevo ticket', 'TKT-MMJ3EFD6-F4N7', 'jonatan', true, 10, '2026-03-09 12:34:49.369724', '2026-03-09 08:23:10.802054') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (518, 302, 'Mantenimiento', 'Nuevo ticket: lluvia', 'franco ha creado un nuevo ticket', 'TKT-MMJ52ICB-JJ1T', 'franco', true, 10, '2026-03-09 12:34:49.369724', '2026-03-09 09:09:54.017106') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (523, 305, 'Mantenimiento', 'Nuevo ticket: Quitar plotter del interior del ascensor.', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MMJ7YM5T-FRAD', 'Lorena Andrea Menegon', true, 10, '2026-03-09 12:34:49.369724', '2026-03-09 10:30:51.189465') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1009, 573, 'Mantenimiento', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MRXSU8UA-D9UI', 'franco', true, 10, '2026-08-04 15:37:39.475343', '2026-07-23 14:42:37.457371') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1031, 585, 'Mantenimiento', 'Nuevo ticket: SILLA RESPALDO ROTO', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MSAAL7J1-IJI8', 'Gimena Soledad Manrique Olivera', true, 10, '2026-08-04 15:37:39.475343', '2026-08-01 08:32:43.024523') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1020, 579, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS629LOS-C341', 'franco ortiz', true, 10, '2026-08-04 15:37:39.475343', '2026-07-29 09:28:39.855622') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1035, 587, 'Compras e Insumos', 'Nuevo ticket: LIBRERIA', 'María del Carmen ha creado un nuevo ticket', 'TKT-MSDQ4H1P-DWK5', 'María del Carmen', true, 11, '2026-08-11 12:54:38.32259', '2026-08-03 18:10:54.59243') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (850, 487, 'Administrador', 'Nuevo ticket: baranda de rampa genera', 'franco ha creado un nuevo ticket', 'TKT-MOBQTY48-P1HK', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 14:16:21.390555') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (882, 504, 'Administrador', 'Nuevo ticket: porta lampara exterior y puerta sala de limpieza.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MOJ2SFFM-ZKQR', 'pablo estrella', true, 1, '2026-08-29 09:20:40.458597', '2026-04-28 17:25:29.139443') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (527, 307, 'Sistemas', 'Nuevo ticket: HUB DE ACCESO', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MMJGW2AO-5L5V', 'CLAUDIO', true, 3, '2026-03-10 08:20:10.441299', '2026-03-09 14:40:48.677686') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (525, 306, 'Mantenimiento', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MMJG9G4K-R1XJ', 'franco', true, 10, '2026-03-10 08:45:39.41063', '2026-03-09 14:23:13.513318') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (529, 308, 'Mantenimiento', 'Nuevo ticket: BIDON DE AGUA', 'MARIA DEL CARMEN HERRERA ha creado un nuevo ticket', 'TKT-MMJH7UEV-GG0C', 'MARIA DEL CARMEN HERRERA', true, 10, '2026-03-10 08:45:39.41063', '2026-03-09 14:49:58.33287') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (531, 309, 'Mantenimiento', 'Nuevo ticket: foco plafon y gotera en techo.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MMJSSSWI-1H68', 'pablo estrella', true, 10, '2026-03-10 08:45:39.41063', '2026-03-09 20:14:11.930254') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (533, 310, 'Mantenimiento', 'Nuevo ticket: luces dicroicas de afuera.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MMJSVWU2-1VN7', 'pablo estrella', true, 10, '2026-03-10 08:45:39.41063', '2026-03-09 20:16:37.000597') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (539, 313, 'Compras e Insumos', 'Nuevo ticket: Hojas para impresora del 1er piso y lapiceras', 'Monica ha creado un nuevo ticket', 'TKT-MMKQ8K99-1OUU', 'Monica', false, NULL, NULL, '2026-03-10 11:50:14.546791') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (542, 315, 'Mantenimiento', 'Nuevo ticket: reparar manija ventana directorio', 'danilo barresi ha creado un nuevo ticket', 'TKT-MMKU5D1X-W9UL', 'danilo barresi', true, 10, '2026-03-12 08:59:11.184364', '2026-03-10 13:39:43.705758') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (544, 316, 'Mantenimiento', 'Nuevo ticket: filtracion de agua tuerquita', 'franco ha creado un nuevo ticket', 'TKT-MMKW9PPN-1FZ1', 'franco', true, 10, '2026-03-12 08:59:11.184364', '2026-03-10 14:39:05.968511') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (503, 294, 'Administrador', 'Nuevo ticket: PEDIDO AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MMEX24PC-TXMT', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-06 10:14:34.738839') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (505, 295, 'Administrador', 'Nuevo ticket: techo', 'franco ha creado un nuevo ticket', 'TKT-MMF3352P-NUM9', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-06 13:03:19.557621') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (507, 296, 'Administrador', 'Nuevo ticket: almohadas', 'franco ha creado un nuevo ticket', 'TKT-MMF54DSX-W77M', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-06 14:00:16.756944') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (511, 298, 'Administrador', 'Nuevo ticket: Revisar impresora', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MMGCCFOC-V41H', 'Guadalupe Sanchez', true, 1, '2026-04-23 09:51:05.481381', '2026-03-07 10:10:15.927398') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1132, 641, 'Administrador', 'Nuevo ticket: control de cemepaci', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLUO9YM-XVO7', 'franco ortiz', false, NULL, NULL, '2026-09-03 15:20:08.757071') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (535, 311, 'Sistemas', 'Nuevo ticket: No puedo abrir la ventana para tipear los estudios...', 'Gerardo ha creado un nuevo ticket', 'TKT-MMKP3W22-CAII', 'Gerardo', true, 3, '2026-03-11 08:27:38.954181', '2026-03-10 11:18:36.946005') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (537, 312, 'Sistemas', 'Nuevo ticket: Mamografías', 'Romina ha creado un nuevo ticket', 'TKT-MMKPNGF4-MNG9', 'Romina', true, 3, '2026-03-11 08:27:38.954181', '2026-03-10 11:33:49.79936') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (540, 314, 'Sistemas', 'Nuevo ticket: ACTUALIZACION DE USUARIO', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MMKS9199-C77E', 'ROMINA AZEGLIO', true, 3, '2026-03-11 08:27:38.954181', '2026-03-10 12:46:35.811417') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (548, 318, 'Sistemas', 'Nuevo ticket: sin sistema no puedo arribar ver pacientes', 'GIMENA manique ha creado un nuevo ticket', 'TKT-MML0UR9V-VLKR', 'GIMENA manique', true, 3, '2026-03-11 08:27:38.954181', '2026-03-10 16:47:26.245175') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (853, 489, 'Mantenimiento', 'Nuevo ticket: calle', 'franco ha creado un nuevo ticket', 'TKT-MOBQW7YV-ZE8B', 'franco', true, 10, '2026-04-24 11:32:28.125647', '2026-04-23 14:18:07.451994') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1117, 634, 'Mantenimiento', 'Nuevo ticket: pala', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTKDNNFE-3S9W', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-02 14:35:59.870903') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (883, 505, 'Mantenimiento', 'Nuevo ticket: vestidor', 'franco ha creado un nuevo ticket', 'TKT-MOK879JZ-7BI1', 'franco', true, 10, '2026-04-30 11:51:49.837012', '2026-04-29 12:44:45.608299') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1123, 637, 'Mantenimiento', 'Nuevo ticket: cloaca', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLTKNBC-ZVDC', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-03 14:49:19.788956') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (899, 513, 'Mantenimiento', 'Nuevo ticket: SILLA ROTA', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MOVS28GD-UHLF', 'David Gutiérrez', true, 10, '2026-05-08 12:05:03.651404', '2026-05-07 14:46:11.158308') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (550, 319, 'Sistemas', 'Nuevo ticket: Llamador', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MMMAWOZ0-6BHX', 'ROMINA AZEGLIO', true, 3, '2026-03-12 08:43:27.183925', '2026-03-11 14:16:38.897207') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (546, 317, 'Mantenimiento', 'Nuevo ticket: filtracion de agua 1 piso', 'franco ha creado un nuevo ticket', 'TKT-MMKWBHXF-EGU4', 'franco', true, 10, '2026-03-12 08:59:11.184364', '2026-03-10 14:40:29.19095') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (552, 320, 'Mantenimiento', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MMMCRD2O-8OJD', 'franco', true, 10, '2026-03-12 08:59:11.184364', '2026-03-11 15:08:29.428783') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (554, 321, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MMMCRXHA-Y0Q9', 'franco', true, 10, '2026-03-12 08:59:11.184364', '2026-03-11 15:08:55.876325') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (913, 520, 'Mantenimiento', 'Nuevo ticket: caldera', 'franco ha creado un nuevo ticket', 'TKT-MP1C53S8-JSDI', 'franco', true, 10, '2026-05-14 12:06:51.303882', '2026-05-11 12:07:08.329233') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (919, 523, 'Mantenimiento', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MP78CUTA-VR4B', 'franco', true, 10, '2026-05-18 08:25:46.780993', '2026-05-15 15:07:48.518778') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (556, 322, 'Mantenimiento', 'Nuevo ticket: congelado', 'franco ha creado un nuevo ticket', 'TKT-MMNK6KPW-X71J', 'franco', true, 10, '2026-03-12 11:43:18.904495', '2026-03-12 11:24:02.692868') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (558, 323, 'Mantenimiento', 'Nuevo ticket: Armario', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MMNKSPCS-SJY1', 'David Gutiérrez', true, 10, '2026-03-12 11:43:18.904495', '2026-03-12 11:41:15.137857') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (560, 324, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MMNLPKM6-ZISW', 'franco', true, 10, '2026-03-12 15:44:25.578196', '2026-03-12 12:06:48.613941') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (921, 524, 'Mantenimiento', 'Nuevo ticket: Rotura de cortina', 'Gerardo ha creado un nuevo ticket', 'TKT-MPB5S1YJ-MZGI', 'Gerardo', true, 10, '2026-05-19 09:21:33.294981', '2026-05-18 09:06:43.609747') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (923, 525, 'Mantenimiento', 'Nuevo ticket: calefacion', 'franco ha creado un nuevo ticket', 'TKT-MPBFA092-PHG1', 'franco', true, 10, '2026-05-19 09:21:33.294981', '2026-05-18 13:32:37.615831') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (564, 326, 'Sistemas', 'Nuevo ticket: Mi maquina esta muy lenta', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MMOSXZKO-HTHR', 'Lorena Andrea Menegon', true, 3, '2026-03-13 08:36:06.586528', '2026-03-13 08:17:04.789521') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (929, 528, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MPCRH4TZ-1DDV', 'franco', true, 10, '2026-05-21 10:18:51.726715', '2026-05-19 12:01:51.744852') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (949, 538, 'Mantenimiento', 'Nuevo ticket: escritorio', 'franco ha creado un nuevo ticket', 'TKT-MPMOLB0D-BQ6S', 'franco', true, 10, '2026-05-26 10:39:28.672084', '2026-05-26 10:38:49.477614') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (951, 539, 'Mantenimiento', 'Nuevo ticket: terraza', 'franco ha creado un nuevo ticket', 'TKT-MPO4HNT3-10DJ', 'franco', true, 10, '2026-05-27 12:21:37.320741', '2026-05-27 10:51:39.280123') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (599, 360, 'Mantenimiento', 'Nuevo ticket: bobinas', 'jonatan ha creado un nuevo ticket', 'TKT-MMP52K2B-589D', 'jonatan', true, 10, '2026-03-13 15:43:26.687936', '2026-03-13 13:56:33.446281') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (601, 361, 'Mantenimiento', 'Nuevo ticket: matafuegos', 'franco ha creado un nuevo ticket', 'TKT-MMP7QIDG-E05G', 'franco', true, 10, '2026-03-13 15:43:26.687936', '2026-03-13 15:11:10.092662') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (603, 362, 'Compras e Insumos', 'Nuevo ticket: Almacenamiento', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MMQ7UJVC-KT8A', 'Rodolfo VIgon', false, NULL, NULL, '2026-03-14 08:02:04.8431') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (562, 325, 'Sistemas', 'Nuevo ticket: toner', 'carina romagnoli ha creado un nuevo ticket', 'TKT-MMNUXI6T-5O7J', 'carina romagnoli', true, 3, '2026-03-14 11:18:15.8497', '2026-03-12 16:24:55.312781') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (566, 327, 'Sistemas', 'Nuevo ticket: Resolución Pantallas Tótem', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MMOTZLM3-JC59', 'Lorena Menegon', true, 3, '2026-03-14 11:18:15.8497', '2026-03-13 08:46:19.571804') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (957, 542, 'Mantenimiento', 'Nuevo ticket: jabalina', 'jonatan ha creado un nuevo ticket', 'TKT-MPWVZ90E-DJXQ', 'jonatan', true, 10, '2026-06-04 12:02:45.702205', '2026-06-02 14:03:18.992223') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (961, 544, 'Sistemas', 'Nuevo ticket: agregar a consola servicios', 'marcelo castro ha creado un nuevo ticket', 'TKT-MQ5GW9YF-TMVH', 'marcelo castro', true, 3, '2026-06-10 08:39:11.364718', '2026-06-08 14:11:01.640197') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (963, 545, 'Sistemas', 'Nuevo ticket: WIFI', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MQ83FOHR-K4PB', 'Rodolfo VIgon', true, 3, '2026-06-10 10:59:19.686142', '2026-06-10 10:17:30.888001') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (604, 363, 'Sistemas', 'Nuevo ticket: TOTEN', 'CLAUDIO FACCENDINI ha creado un nuevo ticket', 'TKT-MMT28FN2-KNSI', 'CLAUDIO FACCENDINI', true, 3, '2026-03-16 08:51:19.53597', '2026-03-16 07:48:13.376879') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (606, 364, 'Sistemas', 'Nuevo ticket: TAMAÑO DE LAS FUENTES  EN LOS TOTEN', 'CLAUDIO FACCENDINI ha creado un nuevo ticket', 'TKT-MMT2BGXK-935E', 'CLAUDIO FACCENDINI', true, 3, '2026-03-16 08:51:19.53597', '2026-03-16 07:50:35.016544') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (608, 365, 'Sistemas', 'Nuevo ticket: NO FUNCIONA MI INTERNO', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MMT3W57J-9GHE', 'TERESA ROMO', true, 3, '2026-03-16 08:51:19.53597', '2026-03-16 08:34:39.206599') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (610, 366, 'Mantenimiento', 'Nuevo ticket: Pintura', 'franco ortiz ha creado un nuevo ticket', 'TKT-MMT7REPP-6IEH', 'franco ortiz', true, 10, '2026-03-16 12:09:19.609183', '2026-03-16 10:22:56.737829') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (979, 554, 'Sistemas', 'Nuevo ticket: COLOCAR ACCESO A ESCANER', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MQS7QAQK-ZNMU', 'FACUNDO PAREDES', true, 3, '2026-06-25 08:04:15.266408', '2026-06-24 12:13:08.131006') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (981, 555, 'Mantenimiento', 'Nuevo ticket: foco quemado', 'gimena ha creado un nuevo ticket', 'TKT-MQVFXDI3-KPMJ', 'gimena', true, 10, '2026-06-29 15:39:37.158287', '2026-06-26 18:25:53.773015') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (612, 367, 'Mantenimiento', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MMTG7IVU-AHZ0', 'TERESA ROMO', true, 10, '2026-03-16 14:59:38.361098', '2026-03-16 14:19:25.53814') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (986, 558, 'Compras e Insumos', 'Nuevo ticket: PEDIDO DE INSUMOS', 'jonatan ha creado un nuevo ticket', 'TKT-MR0O2FGA-ONMB', 'jonatan', false, NULL, NULL, '2026-06-30 10:12:37.483893') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (987, 559, 'Mantenimiento', 'Nuevo ticket: luz quemada en pasillo central.', 'estrella pablo ha creado un nuevo ticket', 'TKT-MR2C0UEE-OSSI', 'estrella pablo', true, 10, '2026-07-02 08:10:36.422129', '2026-07-01 14:11:00.3736') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (995, 563, 'Mantenimiento', 'Nuevo ticket: pintar', 'franco ha creado un nuevo ticket', 'TKT-MRKJE72F-UENK', 'franco', true, 10, '2026-07-16 12:03:26.500304', '2026-07-14 07:57:11.777319') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (620, 371, 'Mantenimiento', 'Nuevo ticket: lavado', 'franco ha creado un nuevo ticket', 'TKT-MMUMARJD-7Y71', 'franco', true, 10, '2026-03-17 14:34:06.268844', '2026-03-17 09:57:40.629595') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (549, 318, 'Administrador', 'Nuevo ticket: sin sistema no puedo arribar ver pacientes', 'GIMENA manique ha creado un nuevo ticket', 'TKT-MML0UR9V-VLKR', 'GIMENA manique', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 16:47:26.260333') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (551, 319, 'Administrador', 'Nuevo ticket: Llamador', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MMMAWOZ0-6BHX', 'ROMINA AZEGLIO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-11 14:16:38.908656') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (553, 320, 'Administrador', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MMMCRD2O-8OJD', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-11 15:08:29.439425') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1133, 642, 'Sistemas', 'Nuevo ticket: problemas de impresion', 'claudia raiano ha creado un nuevo ticket', 'TKT-MTLYSWPT-0QLV', 'claudia raiano', true, 3, '2026-09-04 10:33:46.827707', '2026-09-03 17:15:43.314863') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (868, 497, 'Mantenimiento', 'Nuevo ticket: almohadas y ventilacion', 'jonatan ha creado un nuevo ticket', 'TKT-MOHD1GGH-L5IJ', 'jonatan', true, 10, '2026-04-27 13:01:30.769282', '2026-04-27 12:36:54.171556') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1140, 645, 'Administrador', 'Nuevo ticket: Crear clave', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MTN15BON-88QF', 'Lorena Andrea Menegon', false, NULL, NULL, '2026-09-04 11:09:08.027075') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1142, 646, 'Administrador', 'Nuevo ticket: consolas del sistema faltantes', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MTOIZ1S6-JMJJ', 'ROMINA AZEGLIO', false, NULL, NULL, '2026-09-05 12:15:54.709309') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1135, 643, 'Mantenimiento', 'Nuevo ticket: luces de emergencia', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTMZCQUS-U20D', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-04 10:18:55.000023') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (614, 368, 'Sistemas', 'Nuevo ticket: cambio de matricula medico derivante', 'Vanesa medina ha creado un nuevo ticket', 'TKT-MMTG868R-V9NX', 'Vanesa medina', true, 3, '2026-03-17 11:27:22.596154', '2026-03-16 14:19:55.806278') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (616, 369, 'Sistemas', 'Nuevo ticket: No hay sistema', 'Alejandro Montero ha creado un nuevo ticket', 'TKT-MMTMH7IO-10FL', 'Alejandro Montero', true, 3, '2026-03-17 11:27:22.596154', '2026-03-16 17:14:55.062571') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (618, 370, 'Sistemas', 'Nuevo ticket: Sistema de mza lento', 'Monica ha creado un nuevo ticket', 'TKT-MMUIWJQ4-KQRJ', 'Monica', true, 3, '2026-03-17 11:27:22.596154', '2026-03-17 08:22:38.437306') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (626, 374, 'Sistemas', 'Nuevo ticket: TAMAÑO DE LAS FUENTES EN LOS TOTENS DE RECEPCIONES', 'RECEPCIONES ha creado un nuevo ticket', 'TKT-MMUO9G3G-AWP1', 'RECEPCIONES', true, 3, '2026-03-17 11:27:22.596154', '2026-03-17 10:52:38.365998') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1121, 636, 'Mantenimiento', 'Nuevo ticket: alarma en tablero de sepi', 'emmanuel muñoz ha creado un nuevo ticket', 'TKT-MTLJ7A1S-3TMG', 'emmanuel muñoz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-03 09:58:59.917445') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1125, 638, 'Mantenimiento', 'Nuevo ticket: cable', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLTM2UA-BJZH', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-03 14:50:26.558041') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1129, 640, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTLUMO4N-JUU2', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-03 15:18:53.76037') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (632, 377, 'Compras e Insumos', 'Nuevo ticket: AMPLIFICADOR PARA AUMENTAL EL VOLUMEN.', 'Gerardo ha creado un nuevo ticket', 'TKT-MMUTR1TP-IMDR', 'Gerardo', false, NULL, NULL, '2026-03-17 13:26:17.737658') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (622, 372, 'Mantenimiento', 'Nuevo ticket: filtros', 'franco ha creado un nuevo ticket', 'TKT-MMUMBVY8-UTKZ', 'franco', true, 10, '2026-03-17 14:34:06.268844', '2026-03-17 09:58:32.964873') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (624, 373, 'Mantenimiento', 'Nuevo ticket: lockers', 'franco ha creado un nuevo ticket', 'TKT-MMUNZAP5-KJFK', 'franco', true, 10, '2026-03-17 14:34:06.268844', '2026-03-17 10:44:44.782658') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (628, 375, 'Mantenimiento', 'Nuevo ticket: patio', 'franco ha creado un nuevo ticket', 'TKT-MMUR3DXH-QUW0', 'franco', true, 10, '2026-03-17 14:34:06.268844', '2026-03-17 12:11:54.444399') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (630, 376, 'Mantenimiento', 'Nuevo ticket: ver que tirar', 'franco ha creado un nuevo ticket', 'TKT-MMUR4IFX-QZKN', 'franco', true, 10, '2026-03-17 14:34:06.268844', '2026-03-17 12:12:46.947168') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (925, 526, 'Mantenimiento', 'Nuevo ticket: bolsas', 'franco ha creado un nuevo ticket', 'TKT-MPBFAEU4-05YI', 'franco', true, 10, '2026-05-19 09:21:33.294981', '2026-05-18 13:32:56.513674') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (943, 535, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MPGUWQM9-A847', 'franco', true, 10, '2026-05-26 10:39:28.672084', '2026-05-22 08:49:03.346445') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (633, 378, 'Mantenimiento', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MMUW77MV-ZCG8', 'franco', true, 10, '2026-03-18 14:12:58.005367', '2026-03-17 14:34:50.988734') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (635, 379, 'Mantenimiento', 'Nuevo ticket: Silla en consola.', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MMW24MYF-VBWY', 'David Gutiérrez', true, 10, '2026-03-18 14:12:58.005367', '2026-03-18 10:08:34.756191') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (637, 380, 'Mantenimiento', 'Nuevo ticket: cartel', 'franco ha creado un nuevo ticket', 'TKT-MMW7J0SO-1PV1', 'franco', true, 10, '2026-03-18 14:12:58.005367', '2026-03-18 12:39:43.981999') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (639, 381, 'Mantenimiento', 'Nuevo ticket: plafon', 'franco ha creado un nuevo ticket', 'TKT-MMW7JSMO-RW5I', 'franco', true, 10, '2026-03-18 14:12:58.005367', '2026-03-18 12:40:20.022368') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (641, 382, 'Mantenimiento', 'Nuevo ticket: zocalo', 'franco ha creado un nuevo ticket', 'TKT-MMW7KG2X-Y1OE', 'franco', true, 10, '2026-03-18 14:12:58.005367', '2026-03-18 12:40:50.414896') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (643, 383, 'Mantenimiento', 'Nuevo ticket: terraza', 'franco ha creado un nuevo ticket', 'TKT-MMXHW9D8-JCBU', 'franco', true, 10, '2026-03-19 11:40:41.217632', '2026-03-19 10:17:43.923217') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (645, 384, 'Mantenimiento', 'Nuevo ticket: tamden', 'franco ha creado un nuevo ticket', 'TKT-MMXONWQ6-FC74', 'franco', true, 10, '2026-03-19 14:06:45.965979', '2026-03-19 13:27:11.603238') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (647, 385, 'Mantenimiento', 'Nuevo ticket: oficina de guada', 'franco ha creado un nuevo ticket', 'TKT-MMXOPLRL-GGE9', 'franco', true, 10, '2026-03-19 14:06:45.965979', '2026-03-19 13:28:30.712692') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (649, 386, 'Sistemas', 'Nuevo ticket: carga de estudios', 'jonatan ha creado un nuevo ticket', 'TKT-MMXQZZ5X-JID2', 'jonatan', true, 3, '2026-03-20 09:43:58.606694', '2026-03-19 14:32:33.867592') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (651, 387, 'Sistemas', 'Nuevo ticket: no funciona work list', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MMY4DG66-G5MU', 'Gimena Soledad Manrique Olivera', true, 3, '2026-03-20 09:43:58.606694', '2026-03-19 20:46:57.455815') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (653, 388, 'Sistemas', 'Nuevo ticket: worklist', 'jonatan ha creado un nuevo ticket', 'TKT-MMYT1KMU-UZBX', 'jonatan', true, 3, '2026-03-20 09:43:58.606694', '2026-03-20 08:17:33.79143') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (655, 389, 'Sistemas', 'Nuevo ticket: PUBLICO SM', 'Jonatan Luduena ha creado un nuevo ticket', 'TKT-MMYTN4TU-KBR6', 'Jonatan Luduena', true, 3, '2026-03-20 09:43:58.606694', '2026-03-20 08:34:19.705077') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (623, 372, 'Administrador', 'Nuevo ticket: filtros', 'franco ha creado un nuevo ticket', 'TKT-MMUMBVY8-UTKZ', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 09:58:33.043246') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (625, 373, 'Administrador', 'Nuevo ticket: lockers', 'franco ha creado un nuevo ticket', 'TKT-MMUNZAP5-KJFK', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 10:44:44.802636') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (627, 374, 'Administrador', 'Nuevo ticket: TAMAÑO DE LAS FUENTES EN LOS TOTENS DE RECEPCIONES', 'RECEPCIONES ha creado un nuevo ticket', 'TKT-MMUO9G3G-AWP1', 'RECEPCIONES', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 10:52:38.382381') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (629, 375, 'Administrador', 'Nuevo ticket: patio', 'franco ha creado un nuevo ticket', 'TKT-MMUR3DXH-QUW0', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 12:11:54.463812') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (631, 376, 'Administrador', 'Nuevo ticket: ver que tirar', 'franco ha creado un nuevo ticket', 'TKT-MMUR4IFX-QZKN', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 12:12:46.962138') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (634, 378, 'Administrador', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MMUW77MV-ZCG8', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 14:34:50.997895') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1134, 642, 'Administrador', 'Nuevo ticket: problemas de impresion', 'claudia raiano ha creado un nuevo ticket', 'TKT-MTLYSWPT-0QLV', 'claudia raiano', false, NULL, NULL, '2026-09-03 17:15:43.366098') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (855, 490, 'Mantenimiento', 'Nuevo ticket: luces escalera', 'franco ha creado un nuevo ticket', 'TKT-MOBQYACZ-03G2', 'franco', true, 10, '2026-04-24 11:32:28.125647', '2026-04-23 14:19:43.870245') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1143, 647, 'Mantenimiento', 'Nuevo ticket: Alarma de bajo flujo de agua', 'Javier Rios ha creado un nuevo ticket', 'TKT-MTR4YB7I-WLIK', 'Javier Rios', true, 10, '2026-09-07 11:06:58.651423', '2026-09-07 08:06:43.991954') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (885, 506, 'Mantenimiento', 'Nuevo ticket: PUERTA', 'jonatan ha creado un nuevo ticket', 'TKT-MOK9Q0AB-HHLB', 'jonatan', true, 10, '2026-04-30 11:51:49.837012', '2026-04-29 13:27:19.682606') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (657, 390, 'Mantenimiento', 'Nuevo ticket: Colocar cerradura en mueble', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MMYUDQHE-DJCW', 'Guadalupe Sanchez', true, 10, '2026-03-23 12:58:29.087344', '2026-03-20 08:55:00.825106') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (659, 391, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MMZ6IKIF-BQEG', 'franco', true, 10, '2026-03-23 12:58:29.087344', '2026-03-20 14:34:41.767737') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (661, 392, 'Mantenimiento', 'Nuevo ticket: alarma', 'franco ha creado un nuevo ticket', 'TKT-MMZ6KM9Q-E07M', 'franco', true, 10, '2026-03-23 12:58:29.087344', '2026-03-20 14:36:17.347537') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (663, 393, 'Mantenimiento', 'Nuevo ticket: plafon', 'franco ha creado un nuevo ticket', 'TKT-MMZ6LQ6J-6DS7', 'franco', true, 10, '2026-03-23 12:58:29.087344', '2026-03-20 14:37:09.072413') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (665, 394, 'Mantenimiento', 'Nuevo ticket: caldera', 'franco ha creado un nuevo ticket', 'TKT-MN353RWX-OCOW', 'franco', true, 10, '2026-03-23 12:58:29.087344', '2026-03-23 09:06:16.658361') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (667, 395, 'Mantenimiento', 'Nuevo ticket: protector para la pared', 'franco ha creado un nuevo ticket', 'TKT-MN38RPFL-F37Z', 'franco', true, 10, '2026-03-23 12:58:29.087344', '2026-03-23 10:48:52.010627') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (671, 397, 'Mantenimiento', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MN3DE9TW-P46M', 'franco', true, 10, '2026-03-23 12:58:29.087344', '2026-03-23 12:58:23.314884') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1145, 648, 'Mantenimiento', 'Nuevo ticket: canaletas', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTRDIKNV-IH7Z', 'franco ortiz', false, NULL, NULL, '2026-09-07 12:06:26.236222') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (901, 514, 'Mantenimiento', 'Nuevo ticket: taller', 'franco ha creado un nuevo ticket', 'TKT-MOVSY11V-UOW7', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-05-07 15:10:54.554052') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (927, 527, 'Mantenimiento', 'Nuevo ticket: mueble donde guardamos material de contraste. el c...', 'gimena ha creado un nuevo ticket', 'TKT-MPBPUM7E-XO5Z', 'gimena', true, 10, '2026-05-19 09:21:33.294981', '2026-05-18 18:28:35.358794') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (931, 529, 'Sistemas', 'Nuevo ticket: recambio de cartucho impresora', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MPD2EL8U-2GJY', 'Marcelo Castro', true, 3, '2026-05-20 08:33:26.151261', '2026-05-19 17:07:48.782642') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (959, 543, 'Sistemas', 'Nuevo ticket: Se cayo es sistema de turnos', 'Alejandro Montero ha creado un nuevo ticket', 'TKT-MPYCVA4O-R11J', 'Alejandro Montero', true, 3, '2026-06-04 07:56:54.953846', '2026-06-03 14:43:53.401758') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (953, 540, 'Mantenimiento', 'Nuevo ticket: control de aire', 'franco ha creado un nuevo ticket', 'TKT-MPOEJNYU-5JMR', 'franco', true, 10, '2026-06-04 12:02:45.702205', '2026-05-27 15:33:08.914607') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (983, 556, 'Compras e Insumos', 'Nuevo ticket: reposicion de insumos', 'MARIELA ha creado un nuevo ticket', 'TKT-MQZ5M7DX-P9T0', 'MARIELA', false, NULL, NULL, '2026-06-29 08:48:21.189879') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (967, 547, 'Mantenimiento', 'Nuevo ticket: canilla del baño', 'julieta venturin ha creado un nuevo ticket', 'TKT-MQI3STJJ-I34X', 'julieta venturin', true, 10, '2026-06-29 15:39:37.158287', '2026-06-17 10:25:25.572628') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (975, 551, 'Mantenimiento', 'Nuevo ticket: puerta cocina', 'ledesma estefania ha creado un nuevo ticket', 'TKT-MQLIP8B5-D1G1', 'ledesma estefania', true, 10, '2026-06-29 15:39:37.158287', '2026-06-19 19:45:50.856832') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1011, 574, 'Mantenimiento', 'Nuevo ticket: luz', 'franco ha creado un nuevo ticket', 'TKT-MRXSV91L-UY5I', 'franco', true, 10, '2026-08-04 15:37:39.475343', '2026-07-23 14:43:24.329312') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (869, 497, 'Administrador', 'Nuevo ticket: almohadas y ventilacion', 'jonatan ha creado un nuevo ticket', 'TKT-MOHD1GGH-L5IJ', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-04-27 12:36:54.184313') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (944, 535, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MPGUWQM9-A847', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-22 08:49:03.403317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (677, 400, 'Mantenimiento', 'Nuevo ticket: silla con clavo en recepcion', 'vanesa medina ha creado un nuevo ticket', 'TKT-MN66N945-WZPE', 'vanesa medina', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 12:12:43.510033') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (679, 401, 'Mantenimiento', 'Nuevo ticket: aire acondicionado', 'medina vanesa ha creado un nuevo ticket', 'TKT-MN66P8IN-03LF', 'medina vanesa', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 12:14:16.036682') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (681, 402, 'Mantenimiento', 'Nuevo ticket: aire acondicionado,', 'medina vanesa ha creado un nuevo ticket', 'TKT-MN66SXS8-ACS9', 'medina vanesa', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 12:17:08.752771') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (683, 403, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MN67353O-42YM', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 12:25:04.800169') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (685, 404, 'Mantenimiento', 'Nuevo ticket: puerta de patio', 'franco ha creado un nuevo ticket', 'TKT-MN674ES2-NKUL', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 12:26:03.999493') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (687, 405, 'Mantenimiento', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MN69V01S-N2WV', 'TERESA ROMO', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 13:42:43.850846') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (668, 395, 'Administrador', 'Nuevo ticket: protector para la pared', 'franco ha creado un nuevo ticket', 'TKT-MN38RPFL-F37Z', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-23 10:48:52.026517') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (670, 396, 'Administrador', 'Nuevo ticket: telefono', 'mariela ha creado un nuevo ticket', 'TKT-MN3AHOEO-8219', 'mariela', true, 1, '2026-04-23 09:51:05.481381', '2026-03-23 11:37:03.341693') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (672, 397, 'Administrador', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MN3DE9TW-P46M', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-23 12:58:23.326817') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (674, 398, 'Administrador', 'Nuevo ticket: mail sin funcionar', 'vanesa medina ha creado un nuevo ticket', 'TKT-MN66IP1J-T2HZ', 'vanesa medina', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:09:10.893869') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (676, 399, 'Administrador', 'Nuevo ticket: mal funcionamiento del escaner', 'claudia raiano ha creado un nuevo ticket', 'TKT-MN66K2RJ-1E39', 'claudia raiano', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:10:15.313092') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (678, 400, 'Administrador', 'Nuevo ticket: silla con clavo en recepcion', 'vanesa medina ha creado un nuevo ticket', 'TKT-MN66N945-WZPE', 'vanesa medina', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:12:43.522103') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (680, 401, 'Administrador', 'Nuevo ticket: aire acondicionado', 'medina vanesa ha creado un nuevo ticket', 'TKT-MN66P8IN-03LF', 'medina vanesa', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:14:16.045827') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (682, 402, 'Administrador', 'Nuevo ticket: aire acondicionado,', 'medina vanesa ha creado un nuevo ticket', 'TKT-MN66SXS8-ACS9', 'medina vanesa', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:17:08.765823') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (684, 403, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MN67353O-42YM', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:25:04.811745') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (686, 404, 'Administrador', 'Nuevo ticket: puerta de patio', 'franco ha creado un nuevo ticket', 'TKT-MN674ES2-NKUL', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 12:26:04.010912') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (688, 405, 'Administrador', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MN69V01S-N2WV', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 13:42:43.864988') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (690, 406, 'Administrador', 'Nuevo ticket: recepcion, baño publico, consultorio, puerta elect...', 'estrella pablo ha creado un nuevo ticket', 'TKT-MN6A0GE8-50HR', 'estrella pablo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 13:46:58.327769') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (692, 407, 'Administrador', 'Nuevo ticket: puerta de baño', 'franco ha creado un nuevo ticket', 'TKT-MN6AMMJ4-8Q5P', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 14:04:12.718924') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1144, 647, 'Administrador', 'Nuevo ticket: Alarma de bajo flujo de agua', 'Javier Rios ha creado un nuevo ticket', 'TKT-MTR4YB7I-WLIK', 'Javier Rios', false, NULL, NULL, '2026-09-07 08:06:44.034916') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (870, 498, 'Compras e Insumos', 'Nuevo ticket: tonner negro,impresora de eocgrafias', 'María del Carmen ha creado un nuevo ticket', 'TKT-MOHMQ44L-JE50', 'María del Carmen', false, NULL, NULL, '2026-04-27 17:08:01.139353') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1139, 645, 'Sistemas', 'Nuevo ticket: Crear clave', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MTN15BON-88QF', 'Lorena Andrea Menegon', true, 3, '2026-09-07 08:07:19.793726', '2026-09-04 11:09:07.972992') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1141, 646, 'Sistemas', 'Nuevo ticket: consolas del sistema faltantes', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MTOIZ1S6-JMJJ', 'ROMINA AZEGLIO', true, 3, '2026-09-07 08:07:19.793726', '2026-09-05 12:15:54.606759') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1146, 648, 'Administrador', 'Nuevo ticket: canaletas', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTRDIKNV-IH7Z', 'franco ortiz', false, NULL, NULL, '2026-09-07 12:06:26.264467') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (669, 396, 'Sistemas', 'Nuevo ticket: telefono', 'mariela ha creado un nuevo ticket', 'TKT-MN3AHOEO-8219', 'mariela', true, 3, '2026-03-28 08:28:16.782282', '2026-03-23 11:37:03.329701') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (673, 398, 'Sistemas', 'Nuevo ticket: mail sin funcionar', 'vanesa medina ha creado un nuevo ticket', 'TKT-MN66IP1J-T2HZ', 'vanesa medina', true, 3, '2026-03-28 08:28:16.782282', '2026-03-25 12:09:10.873848') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (675, 399, 'Sistemas', 'Nuevo ticket: mal funcionamiento del escaner', 'claudia raiano ha creado un nuevo ticket', 'TKT-MN66K2RJ-1E39', 'claudia raiano', true, 3, '2026-03-28 08:28:16.782282', '2026-03-25 12:10:15.302132') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (703, 413, 'Sistemas', 'Nuevo ticket: Gestión de cola de espera', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MN7ILOE4-GUBG', 'Lorena Menegon', true, 3, '2026-03-28 08:28:16.782282', '2026-03-26 10:35:11.566829') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (705, 414, 'Sistemas', 'Nuevo ticket: consola tecnico y medico', 'vanesa medina ha creado un nuevo ticket', 'TKT-MN7LPIZ7-JNOF', 'vanesa medina', true, 3, '2026-03-28 08:28:16.782282', '2026-03-26 12:02:10.011228') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (709, 416, 'Sistemas', 'Nuevo ticket: PANTALLA PRIMER PISO RX ADONTOLOGICO', 'VANESA MEDINA ha creado un nuevo ticket', 'TKT-MN938CYZ-ULNO', 'VANESA MEDINA', true, 3, '2026-03-28 08:28:16.782282', '2026-03-27 13:00:28.338305') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (711, 417, 'Sistemas', 'Nuevo ticket: CHEQUEAR LA COMPUTADORA DE LORENA USO DE TACLADO Y...', 'Monica ha creado un nuevo ticket', 'TKT-MN96BDBH-5JO7', 'Monica', true, 3, '2026-03-28 08:28:16.782282', '2026-03-27 14:26:47.6036') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (945, 536, 'Mantenimiento', 'Nuevo ticket: cambio luz', 'danilo ha creado un nuevo ticket', 'TKT-MPH2GQC9-H503', 'danilo', true, 10, '2026-05-26 10:39:28.672084', '2026-05-22 12:20:33.419785') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (991, 561, 'Mantenimiento', 'Nuevo ticket: No funciona el control/aire de la recepción del 4 ...', 'Gerardo ha creado un nuevo ticket', 'TKT-MR9EDKF0-JJC5', 'Gerardo', true, 10, '2026-07-10 12:02:58.78662', '2026-07-06 12:51:16.543838') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (984, 557, 'Sistemas', 'Nuevo ticket: WIFI Inestable', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MQZ7K3XO-4KX8', 'FACUNDO PAREDES', true, 3, '2026-07-13 08:26:43.467912', '2026-06-29 09:42:42.584309') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (723, 423, 'Sistemas', 'Nuevo ticket: impresora', 'CECILIA ha creado un nuevo ticket', 'TKT-MND58QAD-OBVB', 'CECILIA', true, 3, '2026-03-30 10:48:08.488357', '2026-03-30 09:07:49.533712') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (725, 424, 'Sistemas', 'Nuevo ticket: Imagenes de Impresora', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MND5P8E0-7X8T', 'Vargas Aldana Noelia', true, 3, '2026-03-30 10:48:08.488357', '2026-03-30 09:20:39.486822') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1002, 568, 'Mantenimiento', 'Nuevo ticket: terraza', 'franco ha creado un nuevo ticket', 'TKT-MRP27NRW-FYDP', 'franco', true, 10, '2026-07-17 13:32:11.83041', '2026-07-17 11:55:04.24543') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1022, 580, 'Mantenimiento', 'Nuevo ticket: luz', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS62A8TS-4Y5A', 'franco ortiz', true, 10, '2026-08-04 15:37:39.475343', '2026-07-29 09:29:09.854667') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (856, 490, 'Administrador', 'Nuevo ticket: luces escalera', 'franco ha creado un nuevo ticket', 'TKT-MOBQYACZ-03G2', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 14:19:43.883219') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (886, 506, 'Administrador', 'Nuevo ticket: PUERTA', 'jonatan ha creado un nuevo ticket', 'TKT-MOK9Q0AB-HHLB', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-04-29 13:27:19.696305') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (733, 428, 'Sistemas', 'Nuevo ticket: Problemas con el envío de estudios por la IA', 'Monica ha creado un nuevo ticket', 'TKT-MNESDND3-PZHN', 'Monica', true, 3, '2026-04-01 09:29:41.829126', '2026-03-31 12:43:16.372822') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (737, 430, 'Sistemas', 'Nuevo ticket: NO ME FUNCIONA LA VINCHA DEL TELEFONO', 'ANDREA BELEN ha creado un nuevo ticket', 'TKT-MNEZF9UG-88XJ', 'ANDREA BELEN', true, 3, '2026-04-01 09:29:41.829126', '2026-03-31 16:00:29.486007') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (743, 433, 'Sistemas', 'Nuevo ticket: Vincha', 'erica contreras ha creado un nuevo ticket', 'TKT-MNFY2U4V-02PH', 'erica contreras', true, 3, '2026-04-01 09:29:41.829126', '2026-04-01 08:10:35.807446') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (713, 418, 'Mantenimiento', 'Nuevo ticket: cajon', 'franco ha creado un nuevo ticket', 'TKT-MN96VKT2-EAT7', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-27 14:42:30.428396') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (715, 419, 'Mantenimiento', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MN97D7B9-XWWU', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-27 14:56:12.750283') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (717, 420, 'Mantenimiento', 'Nuevo ticket: Rotura de picaporte de puerta nueva de la sala de ...', 'Gerardo ha creado un nuevo ticket', 'TKT-MNAALQXQ-ZHFY', 'Gerardo', true, 10, '2026-04-01 11:18:05.587922', '2026-03-28 09:14:36.459672') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (719, 421, 'Mantenimiento', 'Nuevo ticket: se rompio el picaporte de la puerta', 'claudia cataldo ha creado un nuevo ticket', 'TKT-MNAEU76O-QKHR', 'claudia cataldo', true, 10, '2026-04-01 11:18:05.587922', '2026-03-28 11:13:09.228655') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (819, 472, 'Mantenimiento', 'Nuevo ticket: cartel', 'franco ha creado un nuevo ticket', 'TKT-MO344YOR-TLFS', 'franco', true, 10, '2026-04-17 13:24:31.642964', '2026-04-17 13:18:54.754682') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (621, 371, 'Administrador', 'Nuevo ticket: lavado', 'franco ha creado un nuevo ticket', 'TKT-MMUMARJD-7Y71', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 09:57:40.672949') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (636, 379, 'Administrador', 'Nuevo ticket: Silla en consola.', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MMW24MYF-VBWY', 'David Gutiérrez', true, 1, '2026-04-23 09:51:05.481381', '2026-03-18 10:08:34.772408') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (638, 380, 'Administrador', 'Nuevo ticket: cartel', 'franco ha creado un nuevo ticket', 'TKT-MMW7J0SO-1PV1', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-18 12:39:44.002277') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (640, 381, 'Administrador', 'Nuevo ticket: plafon', 'franco ha creado un nuevo ticket', 'TKT-MMW7JSMO-RW5I', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-18 12:40:20.032236') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (642, 382, 'Administrador', 'Nuevo ticket: zocalo', 'franco ha creado un nuevo ticket', 'TKT-MMW7KG2X-Y1OE', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-18 12:40:50.428887') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (644, 383, 'Administrador', 'Nuevo ticket: terraza', 'franco ha creado un nuevo ticket', 'TKT-MMXHW9D8-JCBU', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-19 10:17:43.935262') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (646, 384, 'Administrador', 'Nuevo ticket: tamden', 'franco ha creado un nuevo ticket', 'TKT-MMXONWQ6-FC74', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-19 13:27:11.615773') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (648, 385, 'Administrador', 'Nuevo ticket: oficina de guada', 'franco ha creado un nuevo ticket', 'TKT-MMXOPLRL-GGE9', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-19 13:28:30.72529') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (650, 386, 'Administrador', 'Nuevo ticket: carga de estudios', 'jonatan ha creado un nuevo ticket', 'TKT-MMXQZZ5X-JID2', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-03-19 14:32:33.878861') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (652, 387, 'Administrador', 'Nuevo ticket: no funciona work list', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MMY4DG66-G5MU', 'Gimena Soledad Manrique Olivera', true, 1, '2026-04-23 09:51:05.481381', '2026-03-19 20:46:57.466352') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (654, 388, 'Administrador', 'Nuevo ticket: worklist', 'jonatan ha creado un nuevo ticket', 'TKT-MMYT1KMU-UZBX', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-03-20 08:17:33.808507') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (745, 434, 'Sistemas', 'Nuevo ticket: Arreglo de computadora', 'maximiliano reynaga ha creado un nuevo ticket', 'TKT-MNFY3PQL-W8E4', 'maximiliano reynaga', true, 3, '2026-04-01 09:29:41.829126', '2026-04-01 08:11:16.795155') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (857, 491, 'Sistemas', 'Nuevo ticket: PEDIDO DE TECLADO BOX 2', 'CARINA ROMAGNOLI ha creado un nuevo ticket', 'TKT-MOEFBN0V-W3N8', 'CARINA ROMAGNOLI', true, 3, '2026-04-27 09:21:44.584837', '2026-04-25 11:17:29.961791') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1147, 649, 'Sistemas', 'Nuevo ticket: PROBLEMA ESPECIFICO CON PACIENTE', 'Javier Rios ha creado un nuevo ticket', 'TKT-MTRG3TXP-WSUC', 'Javier Rios', true, 3, '2026-09-08 08:13:35.26936', '2026-09-07 13:18:57.268828') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (871, 499, 'Sistemas', 'Nuevo ticket: bot - expiro la contraseña', 'carina romagnoli ha creado un nuevo ticket', 'TKT-MOIK44EH-9H0J', 'carina romagnoli', true, 3, '2026-04-29 10:48:20.629235', '2026-04-28 08:42:42.001593') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (887, 507, 'Mantenimiento', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MOKAKQHV-KLO9', 'franco', true, 10, '2026-04-30 11:51:49.837012', '2026-04-29 13:51:13.320214') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (689, 406, 'Mantenimiento', 'Nuevo ticket: recepcion, baño publico, consultorio, puerta elect...', 'estrella pablo ha creado un nuevo ticket', 'TKT-MN6A0GE8-50HR', 'estrella pablo', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 13:46:58.31755') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (691, 407, 'Mantenimiento', 'Nuevo ticket: puerta de baño', 'franco ha creado un nuevo ticket', 'TKT-MN6AMMJ4-8Q5P', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 14:04:12.707429') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (693, 408, 'Mantenimiento', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MN6ANGWT-JCTQ', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 14:04:52.064296') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (695, 409, 'Mantenimiento', 'Nuevo ticket: vestirdor', 'franco ha creado un nuevo ticket', 'TKT-MN6AOR70-JVZ1', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 14:05:52.052538') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (697, 410, 'Mantenimiento', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MN6APQIP-8YIO', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 14:06:37.831732') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (699, 411, 'Mantenimiento', 'Nuevo ticket: eco 1', 'franco ha creado un nuevo ticket', 'TKT-MN6AQPUP-6AIE', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-25 14:07:23.621612') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (701, 412, 'Mantenimiento', 'Nuevo ticket: NO PUEDO TENER ACCESO DESDE MI COMPU PERSONAL', 'FACUNDO ha creado un nuevo ticket', 'TKT-MN7EHJOO-66AV', 'FACUNDO', true, 10, '2026-04-01 11:18:05.587922', '2026-03-26 08:40:00.377142') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (707, 415, 'Mantenimiento', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MN912CFG-Z9X4', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-27 11:59:48.467809') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (721, 422, 'Mantenimiento', 'Nuevo ticket: ESTA ROTO EL PICAPORTE DE LA PUERTA DE TRANSCRIPCI...', 'Monica ha creado un nuevo ticket', 'TKT-MND3EOJU-PYI1', 'Monica', true, 10, '2026-04-01 11:18:05.587922', '2026-03-30 08:16:28.002681') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (727, 425, 'Mantenimiento', 'Nuevo ticket: gotera', 'franco ha creado un nuevo ticket', 'TKT-MNDEPEG8-DR0K', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-03-30 13:32:43.889908') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (729, 426, 'Mantenimiento', 'Nuevo ticket: aire de sala de maquinas apagado', 'CECILIA ha creado un nuevo ticket', 'TKT-MNDG8WQN-UO7C', 'CECILIA', true, 10, '2026-04-01 11:18:05.587922', '2026-03-30 14:15:53.669971') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (731, 427, 'Mantenimiento', 'Nuevo ticket: Ajustar bisagra de casillero', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MNEP9PWB-3DLG', 'David Gutiérrez', true, 10, '2026-04-01 11:18:05.587922', '2026-03-31 11:16:14.208036') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (735, 429, 'Mantenimiento', 'Nuevo ticket: BIDON  DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MNEUBZSD-OPWB', 'TERESA ROMO', true, 10, '2026-04-01 11:18:05.587922', '2026-03-31 13:37:58.393234') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (739, 431, 'Mantenimiento', 'Nuevo ticket: AGUA', 'maria jose calvo ha creado un nuevo ticket', 'TKT-MNEZKV13-X61Y', 'maria jose calvo', true, 10, '2026-04-01 11:18:05.587922', '2026-03-31 16:04:50.212789') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (741, 432, 'Mantenimiento', 'Nuevo ticket: Arreglo de computadora', 'maximiliano reynaga ha creado un nuevo ticket', 'TKT-MNFY0OJS-ZASH', 'maximiliano reynaga', true, 10, '2026-04-01 11:18:05.587922', '2026-04-01 08:08:55.264146') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (747, 435, 'Mantenimiento', 'Nuevo ticket: cambio picaportes', 'franco ha creado un nuevo ticket', 'TKT-MNG44PD8-VVTU', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-04-01 11:00:00.639831') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (749, 436, 'Mantenimiento', 'Nuevo ticket: aire acondicionado perdia agua', 'franco ha creado un nuevo ticket', 'TKT-MNG4OAUC-Z5X1', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-04-01 11:15:14.929728') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (751, 437, 'Mantenimiento', 'Nuevo ticket: Cambio de silla tamden', 'franco ha creado un nuevo ticket', 'TKT-MNG4RTBU-9X6K', 'franco', true, 10, '2026-04-01 11:18:05.587922', '2026-04-01 11:17:58.84926') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (753, 438, 'Compras e Insumos', 'Nuevo ticket: Compra de vinchas', 'Rodolfo ha creado un nuevo ticket', 'TKT-MNG532A4-M3T0', 'Rodolfo', false, NULL, NULL, '2026-04-01 11:26:43.667369') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (754, 439, 'Compras e Insumos', 'Nuevo ticket: Insumos para RM', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MNG6QHJN-BIC9', 'David Gutiérrez', false, NULL, NULL, '2026-04-01 12:12:56.159914') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (903, 515, 'Mantenimiento', 'Nuevo ticket: tapicero', 'franco ha creado un nuevo ticket', 'TKT-MOX0U6GT-4H5T', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-05-08 11:39:38.077263') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (907, 517, 'Mantenimiento', 'Nuevo ticket: ordenar', 'franco ha creado un nuevo ticket', 'TKT-MOX0VYHF-JKYK', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-05-08 11:41:01.016564') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (933, 530, 'Mantenimiento', 'Nuevo ticket: silla de recepcion', 'franco ha creado un nuevo ticket', 'TKT-MPE4WU5C-0U69', 'franco', true, 10, '2026-05-21 10:18:51.726715', '2026-05-20 11:05:45.565877') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (757, 441, 'Mantenimiento', 'Nuevo ticket: perfume', 'franco ha creado un nuevo ticket', 'TKT-MNGAAFHN-O1AW', 'franco', true, 10, '2026-04-01 15:34:32.204939', '2026-04-01 13:52:25.468859') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (759, 442, 'Mantenimiento', 'Nuevo ticket: silla consola Tc', 'ALDANA VARGAS ha creado un nuevo ticket', 'TKT-MNGAQXEW-8J6P', 'ALDANA VARGAS', true, 10, '2026-04-01 15:34:32.204939', '2026-04-01 14:05:15.184052') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (955, 541, 'Mantenimiento', 'Nuevo ticket: termotanque y marco de chapa.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MPPYPMP7-85TZ', 'pablo estrella', true, 10, '2026-06-04 12:02:45.702205', '2026-05-28 17:45:25.719784') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (969, 548, 'Sistemas', 'Nuevo ticket: NO PUEDO IMPRIMIR LAS RESONANCIAS', 'gimena ha creado un nuevo ticket', 'TKT-MQIJS9NT-7QL1', 'gimena', true, 3, '2026-06-19 10:23:08.008899', '2026-06-17 17:52:53.680145') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (977, 552, 'Compras e Insumos', 'Nuevo ticket: pedido', 'María del Carmen ha creado un nuevo ticket', 'TKT-MQQWJIUB-0SOW', 'María del Carmen', false, NULL, NULL, '2026-06-23 14:12:10.063593') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (761, 443, 'Mantenimiento', 'Nuevo ticket: se quemo foco de pasillo, frente salida del ascens...', 'gimena ha creado un nuevo ticket', 'TKT-MNK8QME9-1RY3', 'gimena', true, 10, '2026-04-07 10:07:15.924266', '2026-04-04 08:20:06.416135') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (765, 445, 'Mantenimiento', 'Nuevo ticket: baños publicos de recepcion', 'pablo estrella ha creado un nuevo ticket', 'TKT-MNNTFBDF-5281', 'pablo estrella', true, 10, '2026-04-07 10:07:15.924266', '2026-04-06 20:22:29.358036') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (755, 440, 'Sistemas', 'Nuevo ticket: no puedo arribar o dar finalizado a los pacientes ...', 'GIMENA ha creado un nuevo ticket', 'TKT-MNG8LRW0-HUMG', 'GIMENA', true, 3, '2026-04-08 09:05:15.419096', '2026-04-01 13:05:15.513783') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (763, 444, 'Sistemas', 'Nuevo ticket: falla de impresora', 'DAVID VIDELA ha creado un nuevo ticket', 'TKT-MNNL44C4-A8C5', 'DAVID VIDELA', true, 3, '2026-04-08 09:05:15.419096', '2026-04-06 16:29:50.0919') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (767, 446, 'Sistemas', 'Nuevo ticket: SCANNER PUESTO 1', 'DAVID VIDELA ha creado un nuevo ticket', 'TKT-MNP3W6N2-JOC3', 'DAVID VIDELA', true, 3, '2026-04-08 09:05:15.419096', '2026-04-07 18:03:18.71151') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (769, 447, 'Sistemas', 'Nuevo ticket: Impresora planta baja', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MNPYTKIS-YAOE', 'Vargas Aldana Noelia', true, 3, '2026-04-08 09:05:15.419096', '2026-04-08 08:29:04.807586') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (771, 448, 'Mantenimiento', 'Nuevo ticket: AIRE CONGELADO', 'JORGELINA ARAYA ha creado un nuevo ticket', 'TKT-MNQAOI1I-HJNE', 'JORGELINA ARAYA', true, 10, '2026-04-09 09:22:15.266024', '2026-04-08 14:01:03.728286') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (746, 434, 'Administrador', 'Nuevo ticket: Arreglo de computadora', 'maximiliano reynaga ha creado un nuevo ticket', 'TKT-MNFY3PQL-W8E4', 'maximiliano reynaga', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 08:11:16.813437') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1148, 649, 'Administrador', 'Nuevo ticket: PROBLEMA ESPECIFICO CON PACIENTE', 'Javier Rios ha creado un nuevo ticket', 'TKT-MTRG3TXP-WSUC', 'Javier Rios', false, NULL, NULL, '2026-09-07 13:18:57.339261') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (905, 516, 'Mantenimiento', 'Nuevo ticket: tapicero', 'franco ha creado un nuevo ticket', 'TKT-MOX0UT6J-L7SP', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-05-08 11:40:07.489794') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (947, 537, 'Mantenimiento', 'Nuevo ticket: PUERTA', 'ANA ha creado un nuevo ticket', 'TKT-MPH8QC27-M1X1', 'ANA', true, 10, '2026-05-26 10:39:28.672084', '2026-05-22 15:15:59.172964') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (978, 553, 'Compras e Insumos', 'Nuevo ticket: TONER PARA IMPRESORA DE TRANSCRIPCIÓN', 'Monica ha creado un nuevo ticket', 'TKT-MQS4H6O2-NOIV', 'Monica', false, NULL, NULL, '2026-06-24 10:42:04.104337') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (965, 546, 'Mantenimiento', 'Nuevo ticket: aire frio calor', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MQI2EXW5-GC0Y', 'MARIANA ZAGO', true, 10, '2026-06-29 15:39:37.158287', '2026-06-17 09:46:38.501611') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (973, 550, 'Mantenimiento', 'Nuevo ticket: Actualizar plotters', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MQJLP3E7-2Q75', 'Lorena Andrea Menegon', true, 10, '2026-06-29 15:39:37.158287', '2026-06-18 11:34:11.017574') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (775, 450, 'Sistemas', 'Nuevo ticket: Estudios salen torcidos', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MNRJNC61-SRHQ', 'Rodolfo VIgon', true, 3, '2026-04-11 09:54:19.25704', '2026-04-09 10:59:52.159568') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (781, 453, 'Sistemas', 'Nuevo ticket: No puedo ingresar a San Martin', 'Monica ha creado un nuevo ticket', 'TKT-MNSXEQ2P-Y37E', 'Monica', true, 3, '2026-04-11 09:54:19.25704', '2026-04-10 10:12:51.077576') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (785, 455, 'Sistemas', 'Nuevo ticket: Faltan aplicaciones de osde/ impresora de tickets', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MNTF3ORV-GW33', 'Marcelo Castro', true, 3, '2026-04-11 09:54:19.25704', '2026-04-10 18:28:09.279644') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (787, 456, 'Sistemas', 'Nuevo ticket: no hay sistema riss', 'franco baigorri ha creado un nuevo ticket', 'TKT-MNUA1TN2-LAKH', 'franco baigorri', true, 3, '2026-04-11 09:54:19.25704', '2026-04-11 08:54:30.370887') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (989, 560, 'Mantenimiento', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MR3HW0IP-CXJY', 'TERESA ROMO', true, 10, '2026-07-10 12:02:58.78662', '2026-07-02 09:42:59.073919') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1000, 567, 'Mantenimiento', 'Nuevo ticket: Bidon agua', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MRP0UWHP-Y7NP', 'TERESA ROMO', true, 10, '2026-07-17 13:32:11.83041', '2026-07-17 11:17:09.597027') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1015, 576, 'Sistemas', 'Nuevo ticket: Pop up', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MS358GXP-RCPM', 'Lorena Andrea Menegon', true, 3, '2026-07-31 08:07:48.775154', '2026-07-27 08:28:27.397792') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (773, 449, 'Mantenimiento', 'Nuevo ticket: puerta de ingreso de pacientes a los consultorios,', 'VANESA MEDINA ha creado un nuevo ticket', 'TKT-MNRJIV3D-TZ09', 'VANESA MEDINA', true, 10, '2026-04-13 11:47:29.544154', '2026-04-09 10:56:23.420749') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (777, 451, 'Mantenimiento', 'Nuevo ticket: reparar boton microhondas', 'danilo ha creado un nuevo ticket', 'TKT-MNRL3FQB-W4FX', 'danilo', true, 10, '2026-04-13 11:47:29.544154', '2026-04-09 11:40:22.890622') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (779, 452, 'Mantenimiento', 'Nuevo ticket: no encienden todas las luces de recepcion en plant...', 'lujan claudia ha creado un nuevo ticket', 'TKT-MNSR7HQV-SWDN', 'lujan claudia', true, 10, '2026-04-13 11:47:29.544154', '2026-04-10 07:19:15.999615') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (783, 454, 'Mantenimiento', 'Nuevo ticket: BIDON AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MNT5E8R9-REBW', 'TERESA ROMO', true, 10, '2026-04-13 11:47:29.544154', '2026-04-10 13:56:25.575791') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (791, 458, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MNX9OOH9-XOO9', 'franco', true, 10, '2026-04-13 11:47:29.544154', '2026-04-13 11:07:35.667207') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (793, 459, 'Mantenimiento', 'Nuevo ticket: equipo', 'franco ha creado un nuevo ticket', 'TKT-MNX9PFX0-UIYU', 'franco', true, 10, '2026-04-13 11:47:29.544154', '2026-04-13 11:08:11.229317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1033, 586, 'Sistemas', 'Nuevo ticket: Problema para cerrar estudios en el sistema de Ciu...', 'Gerardo ha creado un nuevo ticket', 'TKT-MSAGJN7T-N5F6', 'Gerardo', true, 3, '2026-08-01 11:33:54.762006', '2026-08-01 11:19:27.776608') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1013, 575, 'Mantenimiento', 'Nuevo ticket: reflector', 'franco ortiz ha creado un nuevo ticket', 'TKT-MRXSVWCZ-CX9G', 'franco ortiz', true, 10, '2026-08-04 15:37:39.475343', '2026-07-23 14:43:54.541442') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1024, 581, 'Mantenimiento', 'Nuevo ticket: estante', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS68G89G-7UGQ', 'franco ortiz', true, 10, '2026-08-04 15:37:39.475343', '2026-07-29 12:21:46.765096') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1036, 588, 'Compras e Insumos', 'Nuevo ticket: Solicito insumos', 'Andrea Duran ha creado un nuevo ticket', 'TKT-MSEOOPTA-Z1M9', 'Andrea Duran', true, 11, '2026-08-11 12:54:31.117048', '2026-08-04 10:18:26.011896') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (888, 507, 'Administrador', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MOKAKQHV-KLO9', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-29 13:51:13.329075') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (789, 457, 'Sistemas', 'Nuevo ticket: Falla de impresora', 'Monica ha creado un nuevo ticket', 'TKT-MNX7S9LY-TCIP', 'Monica', true, 3, '2026-04-14 11:41:45.67422', '2026-04-13 10:14:23.797118') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (805, 465, 'Sistemas', 'Nuevo ticket: Estudio', 'Dra Zarza ha creado un nuevo ticket', 'TKT-MNYQBBD2-RIXC', 'Dra Zarza', true, 3, '2026-04-14 11:41:45.67422', '2026-04-14 11:40:51.815261') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (795, 460, 'Mantenimiento', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MNXBSWXK-0ZOV', 'franco', true, 10, '2026-04-14 16:30:03.690381', '2026-04-13 12:06:52.479') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (797, 461, 'Mantenimiento', 'Nuevo ticket: lockes', 'franco ha creado un nuevo ticket', 'TKT-MNXEMGM8-10XK', 'franco', true, 10, '2026-04-14 16:30:03.690381', '2026-04-13 13:25:50.252806') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (799, 462, 'Mantenimiento', 'Nuevo ticket: ascensor', 'franco ha creado un nuevo ticket', 'TKT-MNXHDTHV-HBAO', 'franco', true, 10, '2026-04-14 16:30:03.690381', '2026-04-13 14:43:05.889478') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (801, 463, 'Mantenimiento', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MNXHEPQD-1UL5', 'franco', true, 10, '2026-04-14 16:30:03.690381', '2026-04-13 14:43:47.659202') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (803, 464, 'Mantenimiento', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MNXIOKG2-JEF0', 'franco', true, 10, '2026-04-14 16:30:03.690381', '2026-04-13 15:19:26.989446') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (809, 467, 'Mantenimiento', 'Nuevo ticket: tapa', 'franco ha creado un nuevo ticket', 'TKT-MO04X6IT-L90A', 'franco', true, 10, '2026-04-15 14:30:04.827168', '2026-04-15 11:17:32.829044') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (811, 468, 'Mantenimiento', 'Nuevo ticket: acrilico', 'franco ha creado un nuevo ticket', 'TKT-MO04YE23-NBUL', 'franco', true, 10, '2026-04-15 14:30:04.827168', '2026-04-15 11:18:29.168776') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (807, 466, 'Sistemas', 'Nuevo ticket: No logra escanear el equipo.', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MNYZ5X8P-3C4R', 'Marcelo Castro', true, 3, '2026-04-16 08:44:51.625824', '2026-04-14 15:48:36.759692') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (813, 469, 'Mantenimiento', 'Nuevo ticket: AGUA BIDON', 'María del Carmen ha creado un nuevo ticket', 'TKT-MO0FCRUH-ZFW9', 'María del Carmen', true, 10, '2026-04-16 11:53:26.467672', '2026-04-15 16:09:36.386259') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (815, 470, 'Sistemas', 'Nuevo ticket: MAIL DE FACTURACION', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MO1M18HO-UI7G', 'FACUNDO PAREDES', true, 3, '2026-04-17 09:06:40.124924', '2026-04-16 12:04:21.570184') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (817, 471, 'Mantenimiento', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MO1TDZCU-6PL7', 'TERESA ROMO', true, 10, '2026-04-17 13:24:31.642964', '2026-04-16 15:30:13.574505') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (776, 450, 'Administrador', 'Nuevo ticket: Estudios salen torcidos', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MNRJNC61-SRHQ', 'Rodolfo VIgon', true, 1, '2026-04-23 09:51:05.481381', '2026-04-09 10:59:52.1788') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (792, 458, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MNX9OOH9-XOO9', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 11:07:35.677369') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (835, 480, 'Sistemas', 'Nuevo ticket: Sistema caído', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MOBCA71O-6ZUO', 'David Gutiérrez', true, 3, '2026-04-24 10:48:13.032001', '2026-04-23 07:29:05.215959') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (837, 481, 'Sistemas', 'Nuevo ticket: No puedo entrar al cuidad', 'Monica ha creado un nuevo ticket', 'TKT-MOBCAKL7-EXLT', 'Monica', true, 3, '2026-04-24 10:48:13.032001', '2026-04-23 07:29:22.753719') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (859, 492, 'Compras e Insumos', 'Nuevo ticket: Equipos nuevos', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MOH5JU88-Q43F', 'Rodolfo VIgon', false, NULL, NULL, '2026-04-27 09:07:14.913893') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (823, 474, 'Mantenimiento', 'Nuevo ticket: dispenser de jabon', 'franco ha creado un nuevo ticket', 'TKT-MO77MY3F-ZE5G', 'franco', true, 10, '2026-04-20 13:04:35.49852', '2026-04-20 10:07:57.349557') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1149, 650, 'Compras e Insumos', 'Nuevo ticket: PLACAS', 'MARIELA ha creado un nuevo ticket', 'TKT-MTSN1AG6-OQ73', 'MARIELA', false, NULL, NULL, '2026-09-08 09:20:42.188943') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (873, 500, 'Sistemas', 'Nuevo ticket: ingresos mal cargados de pacientes no puedo genera...', 'Monica ha creado un nuevo ticket', 'TKT-MOIKFPVJ-TJQW', 'Monica', true, 3, '2026-04-29 10:48:20.629235', '2026-04-28 08:51:43.047368') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (825, 475, 'Mantenimiento', 'Nuevo ticket: luz baño eco 2', 'danili ha creado un nuevo ticket', 'TKT-MO7ILXZY-4D3R', 'danili', true, 10, '2026-04-20 15:28:59.903961', '2026-04-20 15:15:06.345473') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (821, 473, 'Sistemas', 'Nuevo ticket: sistema de ciudad muy lento', 'Erica vanesa Contreras ha creado un nuevo ticket', 'TKT-MO73GD05-GQE1', 'Erica vanesa Contreras', true, 3, '2026-04-21 08:25:33.226697', '2026-04-20 08:10:51.633679') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (889, 508, 'Mantenimiento', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MOLLPOTG-BUR8', 'franco', true, 10, '2026-04-30 11:51:49.837012', '2026-04-30 11:50:46.449403') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1150, 651, 'Sistemas', 'Nuevo ticket: no se ve el publico', 'gaston renalias ha creado un nuevo ticket', 'TKT-MTSNCCEK-JMAY', 'gaston renalias', true, 3, '2026-09-08 10:03:50.444634', '2026-09-08 09:29:17.940041') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (935, 531, 'Mantenimiento', 'Nuevo ticket: puerta cambiador', 'Frias Diego ha creado un nuevo ticket', 'TKT-MPE6WG6D-Y02K', 'Frias Diego', true, 10, '2026-05-21 10:18:51.726715', '2026-05-20 12:01:26.674305') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (971, 549, 'Sistemas', 'Nuevo ticket: CAMBIO DE OFICINA', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MQJEJYXB-WEUJ', 'FACUNDO PAREDES', true, 3, '2026-06-19 10:23:08.008899', '2026-06-18 08:14:14.579302') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (827, 476, 'Mantenimiento', 'Nuevo ticket: lubricar puerttas de maipu', 'franco ha creado un nuevo ticket', 'TKT-MO8UTIMP-OLMB', 'franco', true, 10, '2026-04-22 15:41:41.355955', '2026-04-21 13:44:41.244882') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (829, 477, 'Mantenimiento', 'Nuevo ticket: ventilacion', 'franco ha creado un nuevo ticket', 'TKT-MO8UXUP5-A7DD', 'franco', true, 10, '2026-04-22 15:41:41.355955', '2026-04-21 13:48:03.504412') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (831, 478, 'Mantenimiento', 'Nuevo ticket: Colocar el panel y zocalos faltantes en el servici...', 'mariela ha creado un nuevo ticket', 'TKT-MOA0DPHB-PMFV', 'mariela', true, 10, '2026-04-22 15:41:41.355955', '2026-04-22 09:08:07.507723') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (833, 479, 'Mantenimiento', 'Nuevo ticket: jabonera', 'franco ha creado un nuevo ticket', 'TKT-MOAB86M3-S8JR', 'franco', true, 10, '2026-04-22 15:41:41.355955', '2026-04-22 14:11:45.547219') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (993, 562, 'Sistemas', 'Nuevo ticket: NO FUNCIONA EL VISUAL', 'CONTRERAS ERICA VANESA ha creado un nuevo ticket', 'TKT-MRJ7HUZA-M83Z', 'CONTRERAS ERICA VANESA', true, 3, '2026-07-15 08:07:13.251349', '2026-07-13 09:36:21.249019') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (448, 266, 'Administrador', 'Nuevo ticket: SILLA', 'VERONICA POBLETE ha creado un nuevo ticket', 'TKT-MM564NA9-8MGI', 'VERONICA POBLETE', true, 1, '2026-04-23 09:51:05.481381', '2026-02-27 14:30:46.917581') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (461, 273, 'Administrador', 'Nuevo ticket: Aires de Mamo y Facturacion', 'Enrique ha creado un nuevo ticket', 'TKT-MM96R45I-LF36', 'Enrique', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 09:59:19.891891') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (471, 278, 'Administrador', 'Nuevo ticket: carteleria de puerta', 'franco ha creado un nuevo ticket', 'TKT-MM9EWC9B-JL07', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 13:47:20.617573') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (481, 283, 'Administrador', 'Nuevo ticket: cerradura de lockers', 'franco ha creado un nuevo ticket', 'TKT-MMAWLWOG-7HYP', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-03 14:50:53.12861') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (442, 263, 'Administrador', 'Nuevo ticket: BIDON AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MM4VKGV1-YYWK', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-02-27 09:35:09.313504') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (450, 267, 'Administrador', 'Nuevo ticket: CLAVO SOBRESALE LA MESA', 'VERONICA BRASILI ha creado un nuevo ticket', 'TKT-MM566Y24-R7ZM', 'VERONICA BRASILI', true, 1, '2026-04-23 09:51:05.481381', '2026-02-27 14:32:34.182214') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (463, 274, 'Administrador', 'Nuevo ticket: cerradura de lockerts', 'jonatan ha creado un nuevo ticket', 'TKT-MM98MLYC-4XYJ', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 10:51:48.919308') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (467, 276, 'Administrador', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MM9EAW6M-S2GI', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 13:30:40.015555') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (477, 281, 'Administrador', 'Nuevo ticket: caño colgando', 'franco ha creado un nuevo ticket', 'TKT-MMARNAP6-Q44E', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-03 12:31:59.871859') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (485, 285, 'Administrador', 'Nuevo ticket: mail', 'Vanesa Contreras ha creado un nuevo ticket', 'TKT-MMC0XSXD-FJDN', 'Vanesa Contreras', true, 1, '2026-04-23 09:51:05.481381', '2026-03-04 09:39:52.849231') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (489, 287, 'Administrador', 'Nuevo ticket: filtracion de agua', 'franco ha creado un nuevo ticket', 'TKT-MMC75PKG-1TV4', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-04 12:33:59.37829') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (493, 289, 'Administrador', 'Nuevo ticket: pegamento en el piso', 'franco ha creado un nuevo ticket', 'TKT-MMDONKIX-RV5L', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-05 13:31:32.287486') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (434, 259, 'Administrador', 'Nuevo ticket: tiras led', 'franco ha creado un nuevo ticket', 'TKT-MM3DZRCN-A0DE', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-26 08:35:23.482851') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (444, 264, 'Administrador', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MM521EZ7-9ESW', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-27 12:36:17.746207') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (465, 275, 'Administrador', 'Nuevo ticket: limpieza tamblero', 'franco ha creado un nuevo ticket', 'TKT-MM99TQYR-R02A', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 11:25:21.624847') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (469, 277, 'Administrador', 'Nuevo ticket: bolsas', 'franco ha creado un nuevo ticket', 'TKT-MM9EBH2Y-ZPXB', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 13:31:07.071889') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (473, 279, 'Administrador', 'Nuevo ticket: aire acondicionado', 'lorena cataldo ha creado un nuevo ticket', 'TKT-MM9I9CG5-HDFF', 'lorena cataldo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 15:21:26.233805') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (483, 284, 'Administrador', 'Nuevo ticket: falla en sistema', 'ledesma estefania ha creado un nuevo ticket', 'TKT-MMB2YME7-DQA6', 'ledesma estefania', true, 1, '2026-04-23 09:51:05.481381', '2026-03-03 17:48:44.022887') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (457, 271, 'Administrador', 'Nuevo ticket: Instalación de mail', 'Guada ha creado un nuevo ticket', 'TKT-MM95OS9C-CZGB', 'Guada', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 09:29:31.562357') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (436, 260, 'Administrador', 'Nuevo ticket: pocelanato y cinta led', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MM3LUJSG-WU7I', 'MARIANA ZAGO', true, 1, '2026-04-23 09:51:05.481381', '2026-02-26 12:15:17.318148') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (446, 265, 'Administrador', 'Nuevo ticket: aire acondicionado de sala de espera no esta funci...', 'jonatan ha creado un nuevo ticket', 'TKT-MM53RDBD-5E1F', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-02-27 13:24:28.221567') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (453, 269, 'Administrador', 'Nuevo ticket: Resonador detuvo escaneo durante examen', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MM6B642U-RV2P', 'David Gutiérrez', true, 1, '2026-04-23 09:51:05.481381', '2026-02-28 09:39:39.593199') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (479, 282, 'Administrador', 'Nuevo ticket: lockers', 'franco ha creado un nuevo ticket', 'TKT-MMAWJBJU-GU3B', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-03 14:48:52.426507') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (822, 473, 'Administrador', 'Nuevo ticket: sistema de ciudad muy lento', 'Erica vanesa Contreras ha creado un nuevo ticket', 'TKT-MO73GD05-GQE1', 'Erica vanesa Contreras', true, 1, '2026-04-23 09:51:05.481381', '2026-04-20 08:10:51.646589') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (824, 474, 'Administrador', 'Nuevo ticket: dispenser de jabon', 'franco ha creado un nuevo ticket', 'TKT-MO77MY3F-ZE5G', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-20 10:07:57.362348') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (826, 475, 'Administrador', 'Nuevo ticket: luz baño eco 2', 'danili ha creado un nuevo ticket', 'TKT-MO7ILXZY-4D3R', 'danili', true, 1, '2026-04-23 09:51:05.481381', '2026-04-20 15:15:06.359117') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (828, 476, 'Administrador', 'Nuevo ticket: lubricar puerttas de maipu', 'franco ha creado un nuevo ticket', 'TKT-MO8UTIMP-OLMB', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-21 13:44:41.260668') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (830, 477, 'Administrador', 'Nuevo ticket: ventilacion', 'franco ha creado un nuevo ticket', 'TKT-MO8UXUP5-A7DD', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-21 13:48:03.515614') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (832, 478, 'Administrador', 'Nuevo ticket: Colocar el panel y zocalos faltantes en el servici...', 'mariela ha creado un nuevo ticket', 'TKT-MOA0DPHB-PMFV', 'mariela', true, 1, '2026-04-23 09:51:05.481381', '2026-04-22 09:08:07.517664') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (487, 286, 'Administrador', 'Nuevo ticket: NO FUNCIONA MOCHILA DE BAÑO DE RAYOS.', 'NATALIA JUAREZ ha creado un nuevo ticket', 'TKT-MMC1YKK7-AUY7', 'NATALIA JUAREZ', true, 1, '2026-04-23 09:51:05.481381', '2026-03-04 10:08:28.274633') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (495, 290, 'Administrador', 'Nuevo ticket: cartel', 'franco ha creado un nuevo ticket', 'TKT-MMDOOIRQ-7Z3L', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-05 13:32:16.660675') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (497, 291, 'Administrador', 'Nuevo ticket: lona', 'franco ha creado un nuevo ticket', 'TKT-MMDOQ58C-LJQ3', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-05 13:33:32.428656') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (499, 292, 'Administrador', 'Nuevo ticket: no funciona la impresora', 'claudia cataldo ha creado un nuevo ticket', 'TKT-MMDP9JM7-O82B', 'claudia cataldo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-05 13:48:37.537524') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (501, 293, 'Administrador', 'Nuevo ticket: mail', 'SHIRLEY PEPA ha creado un nuevo ticket', 'TKT-MMDTA3WB-2HUH', 'SHIRLEY PEPA', true, 1, '2026-04-23 09:51:05.481381', '2026-03-05 15:41:02.288951') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (438, 261, 'Administrador', 'Nuevo ticket: AIRE SPLIT', 'jonatan ha creado un nuevo ticket', 'TKT-MM3MIPU1-GHPR', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-02-26 12:34:04.901968') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (420, 252, 'Administrador', 'Nuevo ticket: SIN SISTEMA', 'DAVID VIDELA ha creado un nuevo ticket', 'TKT-MM114K7H-R2O7', 'DAVID VIDELA', true, 1, '2026-04-23 09:51:05.481381', '2026-02-24 16:59:40.1571') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (430, 257, 'Administrador', 'Nuevo ticket: carteleria', 'franco ha creado un nuevo ticket', 'TKT-MM2BSNMF-C6R3', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-02-25 14:46:06.636743') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (459, 272, 'Administrador', 'Nuevo ticket: Puerta área sistema', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MM96QDFM-JINN', 'Rodolfo VIgon', true, 1, '2026-04-23 09:51:05.481381', '2026-03-02 09:58:45.275454') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (475, 280, 'Administrador', 'Nuevo ticket: MICROFONO DEFECTUOSO', 'GASTON RENALIAS ha creado un nuevo ticket', 'TKT-MMAI9IYY-96EX', 'GASTON RENALIAS', true, 1, '2026-04-23 09:51:05.481381', '2026-03-03 08:09:20.908307') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (491, 288, 'Administrador', 'Nuevo ticket: Dispenser de agua', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MMCAAHK0-4MAE', 'Vargas Aldana Noelia', true, 1, '2026-04-23 09:51:05.481381', '2026-03-04 14:01:41.10501') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (509, 297, 'Administrador', 'Nuevo ticket: Vuelvo a reclamar sobre la impresora de transcripc...', 'Monica ha creado un nuevo ticket', 'TKT-MMF6OZ6Z-WH9N', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-03-06 14:44:17.2226') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (513, 299, 'Administrador', 'Nuevo ticket: impresora rota', 'claudia cataldo ha creado un nuevo ticket', 'TKT-MMGCEMLR-R02J', 'claudia cataldo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-07 10:11:58.217352') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (515, 300, 'Administrador', 'Nuevo ticket: NO FUNCIONA LA IMPRESORA DE LA OFICINA.', 'Gerardo ha creado un nuevo ticket', 'TKT-MMGE5USH-I01T', 'Gerardo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-07 11:01:08.157377') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (517, 301, 'Administrador', 'Nuevo ticket: tapa de gabinete', 'jonatan ha creado un nuevo ticket', 'TKT-MMJ3EFD6-F4N7', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 08:23:10.816898') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (519, 302, 'Administrador', 'Nuevo ticket: lluvia', 'franco ha creado un nuevo ticket', 'TKT-MMJ52ICB-JJ1T', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 09:09:54.027885') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (522, 304, 'Administrador', 'Nuevo ticket: PANTALLA DE NUMERADOR Y QR', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MMJ68SJU-DV9B', 'MARIANA ZAGO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 09:42:46.811107') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (524, 305, 'Administrador', 'Nuevo ticket: Quitar plotter del interior del ascensor.', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MMJ7YM5T-FRAD', 'Lorena Andrea Menegon', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 10:30:51.200106') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (526, 306, 'Administrador', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MMJG9G4K-R1XJ', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 14:23:13.524101') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (528, 307, 'Administrador', 'Nuevo ticket: HUB DE ACCESO', 'CLAUDIO ha creado un nuevo ticket', 'TKT-MMJGW2AO-5L5V', 'CLAUDIO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 14:40:48.687947') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (530, 308, 'Administrador', 'Nuevo ticket: BIDON DE AGUA', 'MARIA DEL CARMEN HERRERA ha creado un nuevo ticket', 'TKT-MMJH7UEV-GG0C', 'MARIA DEL CARMEN HERRERA', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 14:49:58.343576') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (532, 309, 'Administrador', 'Nuevo ticket: foco plafon y gotera en techo.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MMJSSSWI-1H68', 'pablo estrella', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 20:14:11.939252') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (534, 310, 'Administrador', 'Nuevo ticket: luces dicroicas de afuera.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MMJSVWU2-1VN7', 'pablo estrella', true, 1, '2026-04-23 09:51:05.481381', '2026-03-09 20:16:37.011968') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (536, 311, 'Administrador', 'Nuevo ticket: No puedo abrir la ventana para tipear los estudios...', 'Gerardo ha creado un nuevo ticket', 'TKT-MMKP3W22-CAII', 'Gerardo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 11:18:36.957568') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (538, 312, 'Administrador', 'Nuevo ticket: Mamografías', 'Romina ha creado un nuevo ticket', 'TKT-MMKPNGF4-MNG9', 'Romina', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 11:33:49.810256') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (541, 314, 'Administrador', 'Nuevo ticket: ACTUALIZACION DE USUARIO', 'ROMINA AZEGLIO ha creado un nuevo ticket', 'TKT-MMKS9199-C77E', 'ROMINA AZEGLIO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 12:46:35.821813') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (543, 315, 'Administrador', 'Nuevo ticket: reparar manija ventana directorio', 'danilo barresi ha creado un nuevo ticket', 'TKT-MMKU5D1X-W9UL', 'danilo barresi', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 13:39:43.715386') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (545, 316, 'Administrador', 'Nuevo ticket: filtracion de agua tuerquita', 'franco ha creado un nuevo ticket', 'TKT-MMKW9PPN-1FZ1', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 14:39:05.978489') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (547, 317, 'Administrador', 'Nuevo ticket: filtracion de agua 1 piso', 'franco ha creado un nuevo ticket', 'TKT-MMKWBHXF-EGU4', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-10 14:40:29.202805') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (555, 321, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MMMCRXHA-Y0Q9', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-11 15:08:55.883804') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (557, 322, 'Administrador', 'Nuevo ticket: congelado', 'franco ha creado un nuevo ticket', 'TKT-MMNK6KPW-X71J', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-12 11:24:02.711348') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (559, 323, 'Administrador', 'Nuevo ticket: Armario', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MMNKSPCS-SJY1', 'David Gutiérrez', true, 1, '2026-04-23 09:51:05.481381', '2026-03-12 11:41:15.153074') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (561, 324, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MMNLPKM6-ZISW', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-12 12:06:48.620251') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (563, 325, 'Administrador', 'Nuevo ticket: toner', 'carina romagnoli ha creado un nuevo ticket', 'TKT-MMNUXI6T-5O7J', 'carina romagnoli', true, 1, '2026-04-23 09:51:05.481381', '2026-03-12 16:24:55.333772') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (565, 326, 'Administrador', 'Nuevo ticket: Mi maquina esta muy lenta', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MMOSXZKO-HTHR', 'Lorena Andrea Menegon', true, 1, '2026-04-23 09:51:05.481381', '2026-03-13 08:17:04.807898') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (567, 327, 'Administrador', 'Nuevo ticket: Resolución Pantallas Tótem', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MMOTZLM3-JC59', 'Lorena Menegon', true, 1, '2026-04-23 09:51:05.481381', '2026-03-13 08:46:19.58375') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (600, 360, 'Administrador', 'Nuevo ticket: bobinas', 'jonatan ha creado un nuevo ticket', 'TKT-MMP52K2B-589D', 'jonatan', true, 1, '2026-04-23 09:51:05.481381', '2026-03-13 13:56:33.56472') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (602, 361, 'Administrador', 'Nuevo ticket: matafuegos', 'franco ha creado un nuevo ticket', 'TKT-MMP7QIDG-E05G', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-13 15:11:10.10474') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (605, 363, 'Administrador', 'Nuevo ticket: TOTEN', 'CLAUDIO FACCENDINI ha creado un nuevo ticket', 'TKT-MMT28FN2-KNSI', 'CLAUDIO FACCENDINI', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 07:48:13.390159') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (607, 364, 'Administrador', 'Nuevo ticket: TAMAÑO DE LAS FUENTES  EN LOS TOTEN', 'CLAUDIO FACCENDINI ha creado un nuevo ticket', 'TKT-MMT2BGXK-935E', 'CLAUDIO FACCENDINI', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 07:50:35.028215') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (609, 365, 'Administrador', 'Nuevo ticket: NO FUNCIONA MI INTERNO', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MMT3W57J-9GHE', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 08:34:39.217334') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (611, 366, 'Administrador', 'Nuevo ticket: Pintura', 'franco ortiz ha creado un nuevo ticket', 'TKT-MMT7REPP-6IEH', 'franco ortiz', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 10:22:56.795334') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (613, 367, 'Administrador', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MMTG7IVU-AHZ0', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 14:19:25.550786') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (615, 368, 'Administrador', 'Nuevo ticket: cambio de matricula medico derivante', 'Vanesa medina ha creado un nuevo ticket', 'TKT-MMTG868R-V9NX', 'Vanesa medina', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 14:19:55.816745') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (617, 369, 'Administrador', 'Nuevo ticket: No hay sistema', 'Alejandro Montero ha creado un nuevo ticket', 'TKT-MMTMH7IO-10FL', 'Alejandro Montero', true, 1, '2026-04-23 09:51:05.481381', '2026-03-16 17:14:55.073914') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (619, 370, 'Administrador', 'Nuevo ticket: Sistema de mza lento', 'Monica ha creado un nuevo ticket', 'TKT-MMUIWJQ4-KQRJ', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-03-17 08:22:38.442407') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (656, 389, 'Administrador', 'Nuevo ticket: PUBLICO SM', 'Jonatan Luduena ha creado un nuevo ticket', 'TKT-MMYTN4TU-KBR6', 'Jonatan Luduena', true, 1, '2026-04-23 09:51:05.481381', '2026-03-20 08:34:19.719917') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (658, 390, 'Administrador', 'Nuevo ticket: Colocar cerradura en mueble', 'Guadalupe Sanchez ha creado un nuevo ticket', 'TKT-MMYUDQHE-DJCW', 'Guadalupe Sanchez', true, 1, '2026-04-23 09:51:05.481381', '2026-03-20 08:55:00.854986') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (660, 391, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MMZ6IKIF-BQEG', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-20 14:34:41.7856') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (662, 392, 'Administrador', 'Nuevo ticket: alarma', 'franco ha creado un nuevo ticket', 'TKT-MMZ6KM9Q-E07M', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-20 14:36:17.359083') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (664, 393, 'Administrador', 'Nuevo ticket: plafon', 'franco ha creado un nuevo ticket', 'TKT-MMZ6LQ6J-6DS7', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-20 14:37:09.082766') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (666, 394, 'Administrador', 'Nuevo ticket: caldera', 'franco ha creado un nuevo ticket', 'TKT-MN353RWX-OCOW', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-23 09:06:16.762441') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (694, 408, 'Administrador', 'Nuevo ticket: aire', 'franco ha creado un nuevo ticket', 'TKT-MN6ANGWT-JCTQ', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 14:04:52.071972') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (696, 409, 'Administrador', 'Nuevo ticket: vestirdor', 'franco ha creado un nuevo ticket', 'TKT-MN6AOR70-JVZ1', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 14:05:52.062317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (698, 410, 'Administrador', 'Nuevo ticket: puerta', 'franco ha creado un nuevo ticket', 'TKT-MN6APQIP-8YIO', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 14:06:37.84124') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (700, 411, 'Administrador', 'Nuevo ticket: eco 1', 'franco ha creado un nuevo ticket', 'TKT-MN6AQPUP-6AIE', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-25 14:07:23.631565') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (702, 412, 'Administrador', 'Nuevo ticket: NO PUEDO TENER ACCESO DESDE MI COMPU PERSONAL', 'FACUNDO ha creado un nuevo ticket', 'TKT-MN7EHJOO-66AV', 'FACUNDO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-26 08:40:00.39889') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (704, 413, 'Administrador', 'Nuevo ticket: Gestión de cola de espera', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MN7ILOE4-GUBG', 'Lorena Menegon', true, 1, '2026-04-23 09:51:05.481381', '2026-03-26 10:35:11.578652') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (706, 414, 'Administrador', 'Nuevo ticket: consola tecnico y medico', 'vanesa medina ha creado un nuevo ticket', 'TKT-MN7LPIZ7-JNOF', 'vanesa medina', true, 1, '2026-04-23 09:51:05.481381', '2026-03-26 12:02:10.02178') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (708, 415, 'Administrador', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MN912CFG-Z9X4', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-27 11:59:48.480022') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (710, 416, 'Administrador', 'Nuevo ticket: PANTALLA PRIMER PISO RX ADONTOLOGICO', 'VANESA MEDINA ha creado un nuevo ticket', 'TKT-MN938CYZ-ULNO', 'VANESA MEDINA', true, 1, '2026-04-23 09:51:05.481381', '2026-03-27 13:00:28.348374') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (712, 417, 'Administrador', 'Nuevo ticket: CHEQUEAR LA COMPUTADORA DE LORENA USO DE TACLADO Y...', 'Monica ha creado un nuevo ticket', 'TKT-MN96BDBH-5JO7', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-03-27 14:26:47.614393') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (714, 418, 'Administrador', 'Nuevo ticket: cajon', 'franco ha creado un nuevo ticket', 'TKT-MN96VKT2-EAT7', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-27 14:42:30.436881') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (716, 419, 'Administrador', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MN97D7B9-XWWU', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-27 14:56:12.76225') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (718, 420, 'Administrador', 'Nuevo ticket: Rotura de picaporte de puerta nueva de la sala de ...', 'Gerardo ha creado un nuevo ticket', 'TKT-MNAALQXQ-ZHFY', 'Gerardo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-28 09:14:36.472853') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (720, 421, 'Administrador', 'Nuevo ticket: se rompio el picaporte de la puerta', 'claudia cataldo ha creado un nuevo ticket', 'TKT-MNAEU76O-QKHR', 'claudia cataldo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-28 11:13:09.239508') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (722, 422, 'Administrador', 'Nuevo ticket: ESTA ROTO EL PICAPORTE DE LA PUERTA DE TRANSCRIPCI...', 'Monica ha creado un nuevo ticket', 'TKT-MND3EOJU-PYI1', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-03-30 08:16:28.021346') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (724, 423, 'Administrador', 'Nuevo ticket: impresora', 'CECILIA ha creado un nuevo ticket', 'TKT-MND58QAD-OBVB', 'CECILIA', true, 1, '2026-04-23 09:51:05.481381', '2026-03-30 09:07:49.546077') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (726, 424, 'Administrador', 'Nuevo ticket: Imagenes de Impresora', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MND5P8E0-7X8T', 'Vargas Aldana Noelia', true, 1, '2026-04-23 09:51:05.481381', '2026-03-30 09:20:39.497933') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (728, 425, 'Administrador', 'Nuevo ticket: gotera', 'franco ha creado un nuevo ticket', 'TKT-MNDEPEG8-DR0K', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-03-30 13:32:43.902709') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (730, 426, 'Administrador', 'Nuevo ticket: aire de sala de maquinas apagado', 'CECILIA ha creado un nuevo ticket', 'TKT-MNDG8WQN-UO7C', 'CECILIA', true, 1, '2026-04-23 09:51:05.481381', '2026-03-30 14:15:53.681508') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (732, 427, 'Administrador', 'Nuevo ticket: Ajustar bisagra de casillero', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MNEP9PWB-3DLG', 'David Gutiérrez', true, 1, '2026-04-23 09:51:05.481381', '2026-03-31 11:16:14.228077') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (734, 428, 'Administrador', 'Nuevo ticket: Problemas con el envío de estudios por la IA', 'Monica ha creado un nuevo ticket', 'TKT-MNESDND3-PZHN', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-03-31 12:43:16.387798') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (736, 429, 'Administrador', 'Nuevo ticket: BIDON  DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MNEUBZSD-OPWB', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-03-31 13:37:58.404904') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (738, 430, 'Administrador', 'Nuevo ticket: NO ME FUNCIONA LA VINCHA DEL TELEFONO', 'ANDREA BELEN ha creado un nuevo ticket', 'TKT-MNEZF9UG-88XJ', 'ANDREA BELEN', true, 1, '2026-04-23 09:51:05.481381', '2026-03-31 16:00:29.497263') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (740, 431, 'Administrador', 'Nuevo ticket: AGUA', 'maria jose calvo ha creado un nuevo ticket', 'TKT-MNEZKV13-X61Y', 'maria jose calvo', true, 1, '2026-04-23 09:51:05.481381', '2026-03-31 16:04:50.222387') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (742, 432, 'Administrador', 'Nuevo ticket: Arreglo de computadora', 'maximiliano reynaga ha creado un nuevo ticket', 'TKT-MNFY0OJS-ZASH', 'maximiliano reynaga', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 08:08:55.277963') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (744, 433, 'Administrador', 'Nuevo ticket: Vincha', 'erica contreras ha creado un nuevo ticket', 'TKT-MNFY2U4V-02PH', 'erica contreras', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 08:10:35.818617') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (748, 435, 'Administrador', 'Nuevo ticket: cambio picaportes', 'franco ha creado un nuevo ticket', 'TKT-MNG44PD8-VVTU', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 11:00:00.652184') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (750, 436, 'Administrador', 'Nuevo ticket: aire acondicionado perdia agua', 'franco ha creado un nuevo ticket', 'TKT-MNG4OAUC-Z5X1', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 11:15:14.94125') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (752, 437, 'Administrador', 'Nuevo ticket: Cambio de silla tamden', 'franco ha creado un nuevo ticket', 'TKT-MNG4RTBU-9X6K', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 11:17:58.861612') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (756, 440, 'Administrador', 'Nuevo ticket: no puedo arribar o dar finalizado a los pacientes ...', 'GIMENA ha creado un nuevo ticket', 'TKT-MNG8LRW0-HUMG', 'GIMENA', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 13:05:15.52656') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (758, 441, 'Administrador', 'Nuevo ticket: perfume', 'franco ha creado un nuevo ticket', 'TKT-MNGAAFHN-O1AW', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 13:52:25.48476') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (760, 442, 'Administrador', 'Nuevo ticket: silla consola Tc', 'ALDANA VARGAS ha creado un nuevo ticket', 'TKT-MNGAQXEW-8J6P', 'ALDANA VARGAS', true, 1, '2026-04-23 09:51:05.481381', '2026-04-01 14:05:15.197398') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (762, 443, 'Administrador', 'Nuevo ticket: se quemo foco de pasillo, frente salida del ascens...', 'gimena ha creado un nuevo ticket', 'TKT-MNK8QME9-1RY3', 'gimena', true, 1, '2026-04-23 09:51:05.481381', '2026-04-04 08:20:06.426375') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (764, 444, 'Administrador', 'Nuevo ticket: falla de impresora', 'DAVID VIDELA ha creado un nuevo ticket', 'TKT-MNNL44C4-A8C5', 'DAVID VIDELA', true, 1, '2026-04-23 09:51:05.481381', '2026-04-06 16:29:50.102979') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (766, 445, 'Administrador', 'Nuevo ticket: baños publicos de recepcion', 'pablo estrella ha creado un nuevo ticket', 'TKT-MNNTFBDF-5281', 'pablo estrella', true, 1, '2026-04-23 09:51:05.481381', '2026-04-06 20:22:29.369038') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (768, 446, 'Administrador', 'Nuevo ticket: SCANNER PUESTO 1', 'DAVID VIDELA ha creado un nuevo ticket', 'TKT-MNP3W6N2-JOC3', 'DAVID VIDELA', true, 1, '2026-04-23 09:51:05.481381', '2026-04-07 18:03:18.732924') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (770, 447, 'Administrador', 'Nuevo ticket: Impresora planta baja', 'Vargas Aldana Noelia ha creado un nuevo ticket', 'TKT-MNPYTKIS-YAOE', 'Vargas Aldana Noelia', true, 1, '2026-04-23 09:51:05.481381', '2026-04-08 08:29:04.822897') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (772, 448, 'Administrador', 'Nuevo ticket: AIRE CONGELADO', 'JORGELINA ARAYA ha creado un nuevo ticket', 'TKT-MNQAOI1I-HJNE', 'JORGELINA ARAYA', true, 1, '2026-04-23 09:51:05.481381', '2026-04-08 14:01:03.741799') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (774, 449, 'Administrador', 'Nuevo ticket: puerta de ingreso de pacientes a los consultorios,', 'VANESA MEDINA ha creado un nuevo ticket', 'TKT-MNRJIV3D-TZ09', 'VANESA MEDINA', true, 1, '2026-04-23 09:51:05.481381', '2026-04-09 10:56:23.427472') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (778, 451, 'Administrador', 'Nuevo ticket: reparar boton microhondas', 'danilo ha creado un nuevo ticket', 'TKT-MNRL3FQB-W4FX', 'danilo', true, 1, '2026-04-23 09:51:05.481381', '2026-04-09 11:40:22.901886') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (780, 452, 'Administrador', 'Nuevo ticket: no encienden todas las luces de recepcion en plant...', 'lujan claudia ha creado un nuevo ticket', 'TKT-MNSR7HQV-SWDN', 'lujan claudia', true, 1, '2026-04-23 09:51:05.481381', '2026-04-10 07:19:16.012816') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (782, 453, 'Administrador', 'Nuevo ticket: No puedo ingresar a San Martin', 'Monica ha creado un nuevo ticket', 'TKT-MNSXEQ2P-Y37E', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-04-10 10:12:51.093328') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (784, 454, 'Administrador', 'Nuevo ticket: BIDON AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MNT5E8R9-REBW', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-04-10 13:56:25.588489') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (786, 455, 'Administrador', 'Nuevo ticket: Faltan aplicaciones de osde/ impresora de tickets', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MNTF3ORV-GW33', 'Marcelo Castro', true, 1, '2026-04-23 09:51:05.481381', '2026-04-10 18:28:09.290117') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (788, 456, 'Administrador', 'Nuevo ticket: no hay sistema riss', 'franco baigorri ha creado un nuevo ticket', 'TKT-MNUA1TN2-LAKH', 'franco baigorri', true, 1, '2026-04-23 09:51:05.481381', '2026-04-11 08:54:30.383808') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (790, 457, 'Administrador', 'Nuevo ticket: Falla de impresora', 'Monica ha creado un nuevo ticket', 'TKT-MNX7S9LY-TCIP', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 10:14:23.814696') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (794, 459, 'Administrador', 'Nuevo ticket: equipo', 'franco ha creado un nuevo ticket', 'TKT-MNX9PFX0-UIYU', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 11:08:11.239933') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (796, 460, 'Administrador', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MNXBSWXK-0ZOV', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 12:06:52.490248') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (798, 461, 'Administrador', 'Nuevo ticket: lockes', 'franco ha creado un nuevo ticket', 'TKT-MNXEMGM8-10XK', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 13:25:50.270906') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (800, 462, 'Administrador', 'Nuevo ticket: ascensor', 'franco ha creado un nuevo ticket', 'TKT-MNXHDTHV-HBAO', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 14:43:05.899445') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (802, 463, 'Administrador', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MNXHEPQD-1UL5', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 14:43:47.668563') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (804, 464, 'Administrador', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MNXIOKG2-JEF0', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-13 15:19:27.002723') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (806, 465, 'Administrador', 'Nuevo ticket: Estudio', 'Dra Zarza ha creado un nuevo ticket', 'TKT-MNYQBBD2-RIXC', 'Dra Zarza', true, 1, '2026-04-23 09:51:05.481381', '2026-04-14 11:40:51.832405') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (808, 466, 'Administrador', 'Nuevo ticket: No logra escanear el equipo.', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MNYZ5X8P-3C4R', 'Marcelo Castro', true, 1, '2026-04-23 09:51:05.481381', '2026-04-14 15:48:36.771094') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (810, 467, 'Administrador', 'Nuevo ticket: tapa', 'franco ha creado un nuevo ticket', 'TKT-MO04X6IT-L90A', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-15 11:17:32.883764') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (812, 468, 'Administrador', 'Nuevo ticket: acrilico', 'franco ha creado un nuevo ticket', 'TKT-MO04YE23-NBUL', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-15 11:18:29.179665') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (814, 469, 'Administrador', 'Nuevo ticket: AGUA BIDON', 'María del Carmen ha creado un nuevo ticket', 'TKT-MO0FCRUH-ZFW9', 'María del Carmen', true, 1, '2026-04-23 09:51:05.481381', '2026-04-15 16:09:36.39766') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (816, 470, 'Administrador', 'Nuevo ticket: MAIL DE FACTURACION', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MO1M18HO-UI7G', 'FACUNDO PAREDES', true, 1, '2026-04-23 09:51:05.481381', '2026-04-16 12:04:21.581037') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (818, 471, 'Administrador', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MO1TDZCU-6PL7', 'TERESA ROMO', true, 1, '2026-04-23 09:51:05.481381', '2026-04-16 15:30:13.577996') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (820, 472, 'Administrador', 'Nuevo ticket: cartel', 'franco ha creado un nuevo ticket', 'TKT-MO344YOR-TLFS', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-17 13:18:54.766204') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (834, 479, 'Administrador', 'Nuevo ticket: jabonera', 'franco ha creado un nuevo ticket', 'TKT-MOAB86M3-S8JR', 'franco', true, 1, '2026-04-23 09:51:05.481381', '2026-04-22 14:11:45.562738') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (836, 480, 'Administrador', 'Nuevo ticket: Sistema caído', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MOBCA71O-6ZUO', 'David Gutiérrez', true, 1, '2026-04-23 09:51:05.481381', '2026-04-23 07:29:05.22864') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (838, 481, 'Administrador', 'Nuevo ticket: No puedo entrar al cuidad', 'Monica ha creado un nuevo ticket', 'TKT-MOBCAKL7-EXLT', 'Monica', true, 1, '2026-04-23 09:51:05.481381', '2026-04-23 07:29:22.75561') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1151, 651, 'Administrador', 'Nuevo ticket: no se ve el publico', 'gaston renalias ha creado un nuevo ticket', 'TKT-MTSNCCEK-JMAY', 'gaston renalias', false, NULL, NULL, '2026-09-08 09:29:17.984406') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (839, 482, 'Mantenimiento', 'Nuevo ticket: sala de maquinas', 'franco ha creado un nuevo ticket', 'TKT-MOBHDL0J-GTNE', 'franco', true, 10, '2026-04-23 09:56:58.028477', '2026-04-23 09:51:41.352477') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (877, 502, 'Mantenimiento', 'Nuevo ticket: vestidor', 'franco ha creado un nuevo ticket', 'TKT-MOIQSUOC-ZB9E', 'franco', true, 10, '2026-04-30 11:51:49.837012', '2026-04-28 11:49:53.488293') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (893, 510, 'Mantenimiento', 'Nuevo ticket: sensor de agua.', 'jonatan ha creado un nuevo ticket', 'TKT-MOR31T6Z-4LFT', 'jonatan', true, 10, '2026-05-08 12:05:03.651404', '2026-05-04 07:54:56.318293') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (895, 511, 'Mantenimiento', 'Nuevo ticket: pilas', 'franco ha creado un nuevo ticket', 'TKT-MOR5521J-JKCB', 'franco', true, 10, '2026-05-08 12:05:03.651404', '2026-05-04 08:53:26.948901') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1029, 584, 'Mantenimiento', 'Nuevo ticket: no funciona luz led de sala', 'veronica ha creado un nuevo ticket', 'TKT-MS7KFFDG-2LNZ', 'veronica', true, 10, '2026-08-04 15:37:39.475343', '2026-07-30 10:44:50.907461') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1017, 577, 'Mantenimiento', 'Nuevo ticket: mochila de baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS4R67WF-BTXY', 'franco ortiz', true, 10, '2026-08-04 15:37:39.475343', '2026-07-28 11:30:20.093581') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1038, 590, 'Mantenimiento', 'Nuevo ticket: aire', 'franco ortiz ha creado un nuevo ticket', 'TKT-MSF04TKE-WEZE', 'franco ortiz', true, 10, '2026-08-26 15:34:24.989303', '2026-08-04 15:38:53.129731') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (840, 482, 'Administrador', 'Nuevo ticket: sala de maquinas', 'franco ha creado un nuevo ticket', 'TKT-MOBHDL0J-GTNE', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 09:51:41.363647') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (874, 500, 'Administrador', 'Nuevo ticket: ingresos mal cargados de pacientes no puedo genera...', 'Monica ha creado un nuevo ticket', 'TKT-MOIKFPVJ-TJQW', 'Monica', true, 1, '2026-08-29 09:20:40.458597', '2026-04-28 08:51:43.059052') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (890, 508, 'Administrador', 'Nuevo ticket: silla', 'franco ha creado un nuevo ticket', 'TKT-MOLLPOTG-BUR8', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-30 11:50:46.52516') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (936, 531, 'Administrador', 'Nuevo ticket: puerta cambiador', 'Frias Diego ha creado un nuevo ticket', 'TKT-MPE6WG6D-Y02K', 'Frias Diego', true, 1, '2026-08-29 09:20:40.458597', '2026-05-20 12:01:26.720984') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1152, 652, 'Mantenimiento', 'Nuevo ticket: Cable USB para lamparas de escritorio', 'FEDERICO DALLA TORRE ha creado un nuevo ticket', 'TKT-MTSP7PNW-YWOA', 'FEDERICO DALLA TORRE', false, NULL, NULL, '2026-09-08 10:21:41.08621') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1048, 595, 'Sistemas', 'Nuevo ticket: hay q crgar los pacientes de manera manula', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MSI6LRPE-9V0F', 'Gimena Soledad Manrique Olivera', true, 3, '2026-08-11 08:10:09.686652', '2026-08-06 21:03:20.12095') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1045, 593, 'Administrador', 'Nuevo ticket: puerta cambuiador de TAC. puerta entrada. cortinas...', 'estrella pablo ha creado un nuevo ticket', 'TKT-MSGBMI8L-74KQ', 'estrella pablo', true, 1, '2026-08-29 09:20:40.458597', '2026-08-05 13:48:20.268183') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1049, 595, 'Administrador', 'Nuevo ticket: hay q crgar los pacientes de manera manula', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MSI6LRPE-9V0F', 'Gimena Soledad Manrique Olivera', true, 1, '2026-08-29 09:20:40.458597', '2026-08-06 21:03:20.165074') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1153, 652, 'Administrador', 'Nuevo ticket: Cable USB para lamparas de escritorio', 'FEDERICO DALLA TORRE ha creado un nuevo ticket', 'TKT-MTSP7PNW-YWOA', 'FEDERICO DALLA TORRE', false, NULL, NULL, '2026-09-08 10:21:41.14641') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1046, 594, 'Sistemas', 'Nuevo ticket: worklist', 'jonatan ha creado un nuevo ticket', 'TKT-MSHDR11K-6KJE', 'jonatan', true, 3, '2026-08-11 08:10:09.686652', '2026-08-06 07:35:36.638621') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1054, 598, 'Sistemas', 'Nuevo ticket: sin cámaras', 'Ana Bautista ha creado un nuevo ticket', 'TKT-MSNOG496-KBO1', 'Ana Bautista', true, 3, '2026-08-11 08:10:09.686652', '2026-08-10 17:21:40.400837') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1037, 589, 'Compras e Insumos', 'Nuevo ticket: imsumos semanales', 'Rubio Jonatan ha creado un nuevo ticket', 'TKT-MSET99PT-SLHO', 'Rubio Jonatan', true, 11, '2026-08-11 12:54:22.237295', '2026-08-04 12:26:23.400696') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1026, 582, 'Compras e Insumos', 'Nuevo ticket: JERINGAS  5 ML  UNA CAJA', 'María del Carmen ha creado un nuevo ticket', 'TKT-MS6M6W9Y-GXG0', 'María del Carmen', true, 11, '2026-08-11 12:54:34.593894', '2026-07-29 18:46:25.953039') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1056, 599, 'Compras e Insumos', 'Nuevo ticket: placas', 'MARIELA ha creado un nuevo ticket', 'TKT-MSOPS75S-OHSX', 'MARIELA', true, 11, '2026-08-11 12:54:43.343157', '2026-08-11 10:46:49.851467') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1061, 602, 'Compras e Insumos', 'Nuevo ticket: Compra Batería', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MSRGOL6A-63N2', 'Rodolfo VIgon', false, NULL, NULL, '2026-08-13 08:55:23.37963') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1059, 601, 'Sistemas', 'Nuevo ticket: no funciona worklist', 'gimena manrique ha creado un nuevo ticket', 'TKT-MSP2SC4Z-D95M', 'gimena manrique', true, 3, '2026-08-13 11:45:40.76085', '2026-08-11 16:50:51.295136') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1064, 604, 'Compras e Insumos', 'Nuevo ticket: pedido', 'jonatan ha creado un nuevo ticket', 'TKT-MSYV01KY-XWCE', 'jonatan', false, NULL, NULL, '2026-08-18 13:10:35.785432') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1071, 608, 'Compras e Insumos', 'Nuevo ticket: PLACAS', 'MARIELA ha creado un nuevo ticket', 'TKT-MT79MEFK-Z88Y', 'MARIELA', false, NULL, NULL, '2026-08-24 10:22:02.851922') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1078, 612, 'Compras e Insumos', 'Nuevo ticket: materiales', 'jonatan ha creado un nuevo ticket', 'TKT-MT8XM1AA-VPDO', 'jonatan', false, NULL, NULL, '2026-08-25 14:21:22.817681') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1040, 591, 'Mantenimiento', 'Nuevo ticket: se corto una de las cadenas par asubir bajar las c...', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MSG5ISY6-6R83', 'MARIANA ZAGO', true, 10, '2026-08-26 15:34:24.989303', '2026-08-05 10:57:30.481177') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1042, 592, 'Mantenimiento', 'Nuevo ticket: baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MSG8N2JR-CM7G', 'franco ortiz', true, 10, '2026-08-26 15:34:24.989303', '2026-08-05 12:24:47.736214') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1044, 593, 'Mantenimiento', 'Nuevo ticket: puerta cambuiador de TAC. puerta entrada. cortinas...', 'estrella pablo ha creado un nuevo ticket', 'TKT-MSGBMI8L-74KQ', 'estrella pablo', true, 10, '2026-08-26 15:34:24.989303', '2026-08-05 13:48:20.219662') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1050, 596, 'Mantenimiento', 'Nuevo ticket: reposicion de agua', 'mariela ha creado un nuevo ticket', 'TKT-MSIVPRI7-CTKF', 'mariela', true, 10, '2026-08-26 15:34:24.989303', '2026-08-07 08:46:17.22897') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1052, 597, 'Mantenimiento', 'Nuevo ticket: cableado', 'mariela ha creado un nuevo ticket', 'TKT-MSIVR8YQ-HVGM', 'mariela', true, 10, '2026-08-26 15:34:24.989303', '2026-08-07 08:47:26.155539') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1057, 600, 'Mantenimiento', 'Nuevo ticket: gotera', 'franco ortiz ha creado un nuevo ticket', 'TKT-MSOT5UIP-RYKX', 'franco ortiz', true, 10, '2026-08-26 15:34:24.989303', '2026-08-11 12:21:25.481691') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1062, 603, 'Mantenimiento', 'Nuevo ticket: ALTA TEMP EN SALA DE MAQUINA DE BRIVO', 'Javier ha creado un nuevo ticket', 'TKT-MSRRLPRT-7138', 'Javier', true, 10, '2026-08-26 15:34:24.989303', '2026-08-13 14:01:05.13956') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1067, 606, 'Mantenimiento', 'Nuevo ticket: ARREGLAR BANQUETA DEL VESTIDOR', 'NATALIA JUAREZ ha creado un nuevo ticket', 'TKT-MT0OC705-7V6R', 'NATALIA JUAREZ', true, 10, '2026-08-26 15:34:24.989303', '2026-08-19 19:39:37.731904') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1079, 613, 'Mantenimiento', 'Nuevo ticket: perdida de agua en baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTA6SMM2-NT8V', 'franco ortiz', true, 10, '2026-08-26 15:34:24.989303', '2026-08-26 11:26:13.035359') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1081, 614, 'Mantenimiento', 'Nuevo ticket: MAMOGRAFO', 'María del Carmen ha creado un nuevo ticket', 'TKT-MTALNHX3-OGZQ', 'María del Carmen', true, 10, '2026-08-28 10:36:42.96049', '2026-08-26 18:22:07.903165') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1065, 605, 'Sistemas', 'Nuevo ticket: estamos sin camaras', 'gimena ha creado un nuevo ticket', 'TKT-MSYXKWXE-Z2XV', 'gimena', true, 3, '2026-08-29 08:49:19.734299', '2026-08-18 14:22:48.658096') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1069, 607, 'Sistemas', 'Nuevo ticket: impresora hp11002', 'CARINA ROMAGNOLI ha creado un nuevo ticket', 'TKT-MT755ED8-T33Y', 'CARINA ROMAGNOLI', true, 3, '2026-08-29 08:49:19.734299', '2026-08-24 08:16:51.306873') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1072, 609, 'Sistemas', 'Nuevo ticket: CORREO', 'Vanesa Contreras ha creado un nuevo ticket', 'TKT-MT8M1Z6A-C1QD', 'Vanesa Contreras', true, 3, '2026-08-29 08:49:19.734299', '2026-08-25 08:57:51.16308') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1074, 610, 'Sistemas', 'Nuevo ticket: problema de poco espacio en la cpu', 'MARIELA ha creado un nuevo ticket', 'TKT-MT8O3GYV-QP2M', 'MARIELA', true, 3, '2026-08-29 08:49:19.734299', '2026-08-25 09:55:00.175152') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1076, 611, 'Sistemas', 'Nuevo ticket: No hay pase de imagenes del RMN a sistema de visua...', 'Javier Rios ha creado un nuevo ticket', 'TKT-MT8QP12U-4OUA', 'Javier Rios', true, 3, '2026-08-29 08:49:19.734299', '2026-08-25 11:07:45.236663') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (876, 501, 'Administrador', 'Nuevo ticket: colocar camara en el ascensor', 'franco ha creado un nuevo ticket', 'TKT-MOIQRW97-WN9M', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-28 11:49:08.898359') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (878, 502, 'Administrador', 'Nuevo ticket: vestidor', 'franco ha creado un nuevo ticket', 'TKT-MOIQSUOC-ZB9E', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-28 11:49:53.499686') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (892, 509, 'Administrador', 'Nuevo ticket: bacha', 'franco ha creado un nuevo ticket', 'TKT-MOLQ3TS5-H5AS', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-30 13:53:44.481603') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (910, 518, 'Administrador', 'Nuevo ticket: canilla', 'franco ha creado un nuevo ticket', 'TKT-MOX6NWJ4-9ITU', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-08 14:22:42.944179') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (938, 532, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MPFF4X6C-JXQK', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-21 08:39:45.100864') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (996, 563, 'Administrador', 'Nuevo ticket: pintar', 'franco ha creado un nuevo ticket', 'TKT-MRKJE72F-UENK', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-07-14 07:57:11.812084') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (844, 484, 'Administrador', 'Nuevo ticket: Colocar tacos de goma en la camilla del eco 4', 'Federico Dalla Torre ha creado un nuevo ticket', 'TKT-MOBJ223H-1UPP', 'Federico Dalla Torre', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 10:38:42.868346') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (894, 510, 'Administrador', 'Nuevo ticket: sensor de agua.', 'jonatan ha creado un nuevo ticket', 'TKT-MOR31T6Z-4LFT', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-05-04 07:54:56.336151') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (863, 494, 'Administrador', 'Nuevo ticket: aire central', 'franco ha creado un nuevo ticket', 'TKT-MOHA4FLC-VNJZ', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-27 11:15:14.176521') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (846, 485, 'Administrador', 'Nuevo ticket: EQUIPO BRIVO RX', 'CAMILA SIMONE ha creado un nuevo ticket', 'TKT-MOBLK06O-QKWH', 'CAMILA SIMONE', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 11:48:39.433825') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (896, 511, 'Administrador', 'Nuevo ticket: pilas', 'franco ha creado un nuevo ticket', 'TKT-MOR5521J-JKCB', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-04 08:53:26.962016') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (940, 533, 'Administrador', 'Nuevo ticket: filtros de aires acondicionados', 'franco ha creado un nuevo ticket', 'TKT-MPFHIHY4-NFUX', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-21 09:46:17.794486') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1018, 577, 'Administrador', 'Nuevo ticket: mochila de baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS4R67WF-BTXY', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-07-28 11:30:20.141038') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (848, 486, 'Administrador', 'Nuevo ticket: callle', 'franco ha creado un nuevo ticket', 'TKT-MOBQSYR5-GKZG', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 14:15:35.559749') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (898, 512, 'Administrador', 'Nuevo ticket: estante', 'franco ha creado un nuevo ticket', 'TKT-MOVM29KQ-1HAU', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-07 11:58:14.931292') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (912, 519, 'Administrador', 'Nuevo ticket: No se puede ingresar a San Martin', 'Monica ha creado un nuevo ticket', 'TKT-MP16R0RV-A1JW', 'Monica', true, 1, '2026-08-29 09:20:40.458597', '2026-05-11 09:36:13.412751') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (916, 521, 'Administrador', 'Nuevo ticket: refrigerante', 'franco ha creado un nuevo ticket', 'TKT-MP2R4MS8-FF85', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-12 11:54:26.979653') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (918, 522, 'Administrador', 'Nuevo ticket: focos', 'jonatan ha creado un nuevo ticket', 'TKT-MP71FJYR-H0IJ', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-05-15 11:53:57.423475') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (852, 488, 'Administrador', 'Nuevo ticket: pintar', 'franco ha creado un nuevo ticket', 'TKT-MOBQUTQR-LDKR', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 14:17:02.375129') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (867, 496, 'Administrador', 'Nuevo ticket: No funciona el aire acondicionado. Ya cambié las p...', 'Gerardo ha creado un nuevo ticket', 'TKT-MOHAQWLA-3ZQ7', 'Gerardo', true, 1, '2026-08-29 09:20:40.458597', '2026-04-27 11:32:42.642989') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (926, 526, 'Administrador', 'Nuevo ticket: bolsas', 'franco ha creado un nuevo ticket', 'TKT-MPBFAEU4-05YI', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-18 13:32:56.538227') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (942, 534, 'Administrador', 'Nuevo ticket: cloaca', 'franco ha creado un nuevo ticket', 'TKT-MPFIPAFY-OZHD', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-21 10:19:34.267355') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (854, 489, 'Administrador', 'Nuevo ticket: calle', 'franco ha creado un nuevo ticket', 'TKT-MOBQW7YV-ZE8B', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-23 14:18:07.461846') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (884, 505, 'Administrador', 'Nuevo ticket: vestidor', 'franco ha creado un nuevo ticket', 'TKT-MOK879JZ-7BI1', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-04-29 12:44:45.620185') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (900, 513, 'Administrador', 'Nuevo ticket: SILLA ROTA', 'David Gutiérrez ha creado un nuevo ticket', 'TKT-MOVS28GD-UHLF', 'David Gutiérrez', true, 1, '2026-08-29 09:20:40.458597', '2026-05-07 14:46:11.169793') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (914, 520, 'Administrador', 'Nuevo ticket: caldera', 'franco ha creado un nuevo ticket', 'TKT-MP1C53S8-JSDI', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-11 12:07:08.371045') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (920, 523, 'Administrador', 'Nuevo ticket: agua', 'franco ha creado un nuevo ticket', 'TKT-MP78CUTA-VR4B', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-15 15:07:48.569546') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (922, 524, 'Administrador', 'Nuevo ticket: Rotura de cortina', 'Gerardo ha creado un nuevo ticket', 'TKT-MPB5S1YJ-MZGI', 'Gerardo', true, 1, '2026-08-29 09:20:40.458597', '2026-05-18 09:06:43.659748') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (924, 525, 'Administrador', 'Nuevo ticket: calefacion', 'franco ha creado un nuevo ticket', 'TKT-MPBFA092-PHG1', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-18 13:32:37.658604') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (930, 528, 'Administrador', 'Nuevo ticket: baño', 'franco ha creado un nuevo ticket', 'TKT-MPCRH4TZ-1DDV', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-19 12:01:52.170463') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (950, 538, 'Administrador', 'Nuevo ticket: escritorio', 'franco ha creado un nuevo ticket', 'TKT-MPMOLB0D-BQ6S', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-26 10:38:49.632055') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (952, 539, 'Administrador', 'Nuevo ticket: terraza', 'franco ha creado un nuevo ticket', 'TKT-MPO4HNT3-10DJ', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-27 10:51:39.387856') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (958, 542, 'Administrador', 'Nuevo ticket: jabalina', 'jonatan ha creado un nuevo ticket', 'TKT-MPWVZ90E-DJXQ', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-06-02 14:03:19.098752') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (962, 544, 'Administrador', 'Nuevo ticket: agregar a consola servicios', 'marcelo castro ha creado un nuevo ticket', 'TKT-MQ5GW9YF-TMVH', 'marcelo castro', true, 1, '2026-08-29 09:20:40.458597', '2026-06-08 14:11:01.79809') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (964, 545, 'Administrador', 'Nuevo ticket: WIFI', 'Rodolfo VIgon ha creado un nuevo ticket', 'TKT-MQ83FOHR-K4PB', 'Rodolfo VIgon', true, 1, '2026-08-29 09:20:40.458597', '2026-06-10 10:17:30.978317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (966, 546, 'Administrador', 'Nuevo ticket: aire frio calor', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MQI2EXW5-GC0Y', 'MARIANA ZAGO', true, 1, '2026-08-29 09:20:40.458597', '2026-06-17 09:46:38.661666') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (974, 550, 'Administrador', 'Nuevo ticket: Actualizar plotters', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MQJLP3E7-2Q75', 'Lorena Andrea Menegon', true, 1, '2026-08-29 09:20:40.458597', '2026-06-18 11:34:11.103281') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (980, 554, 'Administrador', 'Nuevo ticket: COLOCAR ACCESO A ESCANER', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MQS7QAQK-ZNMU', 'FACUNDO PAREDES', true, 1, '2026-08-29 09:20:40.458597', '2026-06-24 12:13:08.283774') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (982, 555, 'Administrador', 'Nuevo ticket: foco quemado', 'gimena ha creado un nuevo ticket', 'TKT-MQVFXDI3-KPMJ', 'gimena', true, 1, '2026-08-29 09:20:40.458597', '2026-06-26 18:25:53.832402') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1010, 573, 'Administrador', 'Nuevo ticket: pintura', 'franco ha creado un nuevo ticket', 'TKT-MRXSU8UA-D9UI', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-07-23 14:42:37.57428') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (988, 559, 'Administrador', 'Nuevo ticket: luz quemada en pasillo central.', 'estrella pablo ha creado un nuevo ticket', 'TKT-MR2C0UEE-OSSI', 'estrella pablo', true, 1, '2026-08-29 09:20:40.458597', '2026-07-01 14:11:00.418352') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (990, 560, 'Administrador', 'Nuevo ticket: BIDON DE AGUA', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MR3HW0IP-CXJY', 'TERESA ROMO', true, 1, '2026-08-29 09:20:40.458597', '2026-07-02 09:42:59.130203') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1001, 567, 'Administrador', 'Nuevo ticket: Bidon agua', 'TERESA ROMO ha creado un nuevo ticket', 'TKT-MRP0UWHP-Y7NP', 'TERESA ROMO', true, 1, '2026-08-29 09:20:40.458597', '2026-07-17 11:17:09.688496') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1023, 580, 'Administrador', 'Nuevo ticket: luz', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS62A8TS-4Y5A', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-07-29 09:29:09.879431') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1028, 583, 'Administrador', 'Nuevo ticket: publico', 'jonatan ha creado un nuevo ticket', 'TKT-MS7G1FHW-CTER', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-07-30 08:41:59.69313') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1032, 585, 'Administrador', 'Nuevo ticket: SILLA RESPALDO ROTO', 'Gimena Soledad Manrique Olivera ha creado un nuevo ticket', 'TKT-MSAAL7J1-IJI8', 'Gimena Soledad Manrique Olivera', true, 1, '2026-08-29 09:20:40.458597', '2026-08-01 08:32:43.059091') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (902, 514, 'Administrador', 'Nuevo ticket: taller', 'franco ha creado un nuevo ticket', 'TKT-MOVSY11V-UOW7', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-07 15:10:54.565036') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (928, 527, 'Administrador', 'Nuevo ticket: mueble donde guardamos material de contraste. el c...', 'gimena ha creado un nuevo ticket', 'TKT-MPBPUM7E-XO5Z', 'gimena', true, 1, '2026-08-29 09:20:40.458597', '2026-05-18 18:28:35.409306') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (932, 529, 'Administrador', 'Nuevo ticket: recambio de cartucho impresora', 'Marcelo Castro ha creado un nuevo ticket', 'TKT-MPD2EL8U-2GJY', 'Marcelo Castro', true, 1, '2026-08-29 09:20:40.458597', '2026-05-19 17:07:48.82307') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (954, 540, 'Administrador', 'Nuevo ticket: control de aire', 'franco ha creado un nuevo ticket', 'TKT-MPOEJNYU-5JMR', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-27 15:33:08.969212') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (960, 543, 'Administrador', 'Nuevo ticket: Se cayo es sistema de turnos', 'Alejandro Montero ha creado un nuevo ticket', 'TKT-MPYCVA4O-R11J', 'Alejandro Montero', true, 1, '2026-08-29 09:20:40.458597', '2026-06-03 14:43:53.451108') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (968, 547, 'Administrador', 'Nuevo ticket: canilla del baño', 'julieta venturin ha creado un nuevo ticket', 'TKT-MQI3STJJ-I34X', 'julieta venturin', true, 1, '2026-08-29 09:20:40.458597', '2026-06-17 10:25:25.603302') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (976, 551, 'Administrador', 'Nuevo ticket: puerta cocina', 'ledesma estefania ha creado un nuevo ticket', 'TKT-MQLIP8B5-D1G1', 'ledesma estefania', true, 1, '2026-08-29 09:20:40.458597', '2026-06-19 19:45:50.907407') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1012, 574, 'Administrador', 'Nuevo ticket: luz', 'franco ha creado un nuevo ticket', 'TKT-MRXSV91L-UY5I', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-07-23 14:43:24.370897') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1021, 579, 'Administrador', 'Nuevo ticket: baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS629LOS-C341', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-07-29 09:28:39.899699') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (906, 516, 'Administrador', 'Nuevo ticket: tapicero', 'franco ha creado un nuevo ticket', 'TKT-MOX0UT6J-L7SP', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-08 11:40:07.493726') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (946, 536, 'Administrador', 'Nuevo ticket: cambio luz', 'danilo ha creado un nuevo ticket', 'TKT-MPH2GQC9-H503', 'danilo', true, 1, '2026-08-29 09:20:40.458597', '2026-05-22 12:20:33.488849') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (985, 557, 'Administrador', 'Nuevo ticket: WIFI Inestable', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MQZ7K3XO-4KX8', 'FACUNDO PAREDES', true, 1, '2026-08-29 09:20:40.458597', '2026-06-29 09:42:42.632142') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (992, 561, 'Administrador', 'Nuevo ticket: No funciona el control/aire de la recepción del 4 ...', 'Gerardo ha creado un nuevo ticket', 'TKT-MR9EDKF0-JJC5', 'Gerardo', true, 1, '2026-08-29 09:20:40.458597', '2026-07-06 12:51:16.600604') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1003, 568, 'Administrador', 'Nuevo ticket: terraza', 'franco ha creado un nuevo ticket', 'TKT-MRP27NRW-FYDP', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-07-17 11:55:04.275719') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1014, 575, 'Administrador', 'Nuevo ticket: reflector', 'franco ortiz ha creado un nuevo ticket', 'TKT-MRXSVWCZ-CX9G', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-07-23 14:43:54.571497') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (858, 491, 'Administrador', 'Nuevo ticket: PEDIDO DE TECLADO BOX 2', 'CARINA ROMAGNOLI ha creado un nuevo ticket', 'TKT-MOEFBN0V-W3N8', 'CARINA ROMAGNOLI', true, 1, '2026-08-29 09:20:40.458597', '2026-04-25 11:17:29.974617') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (872, 499, 'Administrador', 'Nuevo ticket: bot - expiro la contraseña', 'carina romagnoli ha creado un nuevo ticket', 'TKT-MOIK44EH-9H0J', 'carina romagnoli', true, 1, '2026-08-29 09:20:40.458597', '2026-04-28 08:42:42.015032') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (904, 515, 'Administrador', 'Nuevo ticket: tapicero', 'franco ha creado un nuevo ticket', 'TKT-MOX0U6GT-4H5T', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-08 11:39:38.091457') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (934, 530, 'Administrador', 'Nuevo ticket: silla de recepcion', 'franco ha creado un nuevo ticket', 'TKT-MPE4WU5C-0U69', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-20 11:05:45.610665') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (956, 541, 'Administrador', 'Nuevo ticket: termotanque y marco de chapa.', 'pablo estrella ha creado un nuevo ticket', 'TKT-MPPYPMP7-85TZ', 'pablo estrella', true, 1, '2026-08-29 09:20:40.458597', '2026-05-28 17:45:25.755543') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (970, 548, 'Administrador', 'Nuevo ticket: NO PUEDO IMPRIMIR LAS RESONANCIAS', 'gimena ha creado un nuevo ticket', 'TKT-MQIJS9NT-7QL1', 'gimena', true, 1, '2026-08-29 09:20:40.458597', '2026-06-17 17:52:53.727319') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1039, 590, 'Administrador', 'Nuevo ticket: aire', 'franco ortiz ha creado un nuevo ticket', 'TKT-MSF04TKE-WEZE', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-08-04 15:38:53.168238') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1043, 592, 'Administrador', 'Nuevo ticket: baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MSG8N2JR-CM7G', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-08-05 12:24:47.827343') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (908, 517, 'Administrador', 'Nuevo ticket: ordenar', 'franco ha creado un nuevo ticket', 'TKT-MOX0VYHF-JKYK', 'franco', true, 1, '2026-08-29 09:20:40.458597', '2026-05-08 11:41:01.027262') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (948, 537, 'Administrador', 'Nuevo ticket: PUERTA', 'ANA ha creado un nuevo ticket', 'TKT-MPH8QC27-M1X1', 'ANA', true, 1, '2026-08-29 09:20:40.458597', '2026-05-22 15:15:59.221377') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1016, 576, 'Administrador', 'Nuevo ticket: Pop up', 'Lorena Andrea Menegon ha creado un nuevo ticket', 'TKT-MS358GXP-RCPM', 'Lorena Andrea Menegon', true, 1, '2026-08-29 09:20:40.458597', '2026-07-27 08:28:27.44549') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (972, 549, 'Administrador', 'Nuevo ticket: CAMBIO DE OFICINA', 'FACUNDO PAREDES ha creado un nuevo ticket', 'TKT-MQJEJYXB-WEUJ', 'FACUNDO PAREDES', true, 1, '2026-08-29 09:20:40.458597', '2026-06-18 08:14:14.610912') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (994, 562, 'Administrador', 'Nuevo ticket: NO FUNCIONA EL VISUAL', 'CONTRERAS ERICA VANESA ha creado un nuevo ticket', 'TKT-MRJ7HUZA-M83Z', 'CONTRERAS ERICA VANESA', true, 1, '2026-08-29 09:20:40.458597', '2026-07-13 09:36:21.298568') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1005, 569, 'Administrador', 'Nuevo ticket: Computadora', 'Lorena Menegon ha creado un nuevo ticket', 'TKT-MRT8PQ60-8LH0', 'Lorena Menegon', true, 1, '2026-08-29 09:20:40.458597', '2026-07-20 10:08:09.646771') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1025, 581, 'Administrador', 'Nuevo ticket: estante', 'franco ortiz ha creado un nuevo ticket', 'TKT-MS68G89G-7UGQ', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-07-29 12:21:46.821066') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1030, 584, 'Administrador', 'Nuevo ticket: no funciona luz led de sala', 'veronica ha creado un nuevo ticket', 'TKT-MS7KFFDG-2LNZ', 'veronica', true, 1, '2026-08-29 09:20:40.458597', '2026-07-30 10:44:50.937968') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1034, 586, 'Administrador', 'Nuevo ticket: Problema para cerrar estudios en el sistema de Ciu...', 'Gerardo ha creado un nuevo ticket', 'TKT-MSAGJN7T-N5F6', 'Gerardo', true, 1, '2026-08-29 09:20:40.458597', '2026-08-01 11:19:27.83172') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1041, 591, 'Administrador', 'Nuevo ticket: se corto una de las cadenas par asubir bajar las c...', 'MARIANA ZAGO ha creado un nuevo ticket', 'TKT-MSG5ISY6-6R83', 'MARIANA ZAGO', true, 1, '2026-08-29 09:20:40.458597', '2026-08-05 10:57:30.799164') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1047, 594, 'Administrador', 'Nuevo ticket: worklist', 'jonatan ha creado un nuevo ticket', 'TKT-MSHDR11K-6KJE', 'jonatan', true, 1, '2026-08-29 09:20:40.458597', '2026-08-06 07:35:36.686056') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1051, 596, 'Administrador', 'Nuevo ticket: reposicion de agua', 'mariela ha creado un nuevo ticket', 'TKT-MSIVPRI7-CTKF', 'mariela', true, 1, '2026-08-29 09:20:40.458597', '2026-08-07 08:46:17.441628') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1053, 597, 'Administrador', 'Nuevo ticket: cableado', 'mariela ha creado un nuevo ticket', 'TKT-MSIVR8YQ-HVGM', 'mariela', true, 1, '2026-08-29 09:20:40.458597', '2026-08-07 08:47:26.1943') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1055, 598, 'Administrador', 'Nuevo ticket: sin cámaras', 'Ana Bautista ha creado un nuevo ticket', 'TKT-MSNOG496-KBO1', 'Ana Bautista', true, 1, '2026-08-29 09:20:40.458597', '2026-08-10 17:21:40.507749') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1058, 600, 'Administrador', 'Nuevo ticket: gotera', 'franco ortiz ha creado un nuevo ticket', 'TKT-MSOT5UIP-RYKX', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-08-11 12:21:25.520413') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1060, 601, 'Administrador', 'Nuevo ticket: no funciona worklist', 'gimena manrique ha creado un nuevo ticket', 'TKT-MSP2SC4Z-D95M', 'gimena manrique', true, 1, '2026-08-29 09:20:40.458597', '2026-08-11 16:50:51.348075') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1063, 603, 'Administrador', 'Nuevo ticket: ALTA TEMP EN SALA DE MAQUINA DE BRIVO', 'Javier ha creado un nuevo ticket', 'TKT-MSRRLPRT-7138', 'Javier', true, 1, '2026-08-29 09:20:40.458597', '2026-08-13 14:01:05.211376') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1066, 605, 'Administrador', 'Nuevo ticket: estamos sin camaras', 'gimena ha creado un nuevo ticket', 'TKT-MSYXKWXE-Z2XV', 'gimena', true, 1, '2026-08-29 09:20:40.458597', '2026-08-18 14:22:48.705321') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1068, 606, 'Administrador', 'Nuevo ticket: ARREGLAR BANQUETA DEL VESTIDOR', 'NATALIA JUAREZ ha creado un nuevo ticket', 'TKT-MT0OC705-7V6R', 'NATALIA JUAREZ', true, 1, '2026-08-29 09:20:40.458597', '2026-08-19 19:39:37.837351') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1070, 607, 'Administrador', 'Nuevo ticket: impresora hp11002', 'CARINA ROMAGNOLI ha creado un nuevo ticket', 'TKT-MT755ED8-T33Y', 'CARINA ROMAGNOLI', true, 1, '2026-08-29 09:20:40.458597', '2026-08-24 08:16:51.417531') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1073, 609, 'Administrador', 'Nuevo ticket: CORREO', 'Vanesa Contreras ha creado un nuevo ticket', 'TKT-MT8M1Z6A-C1QD', 'Vanesa Contreras', true, 1, '2026-08-29 09:20:40.458597', '2026-08-25 08:57:51.208805') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1075, 610, 'Administrador', 'Nuevo ticket: problema de poco espacio en la cpu', 'MARIELA ha creado un nuevo ticket', 'TKT-MT8O3GYV-QP2M', 'MARIELA', true, 1, '2026-08-29 09:20:40.458597', '2026-08-25 09:55:00.230124') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1077, 611, 'Administrador', 'Nuevo ticket: No hay pase de imagenes del RMN a sistema de visua...', 'Javier Rios ha creado un nuevo ticket', 'TKT-MT8QP12U-4OUA', 'Javier Rios', true, 1, '2026-08-29 09:20:40.458597', '2026-08-25 11:07:45.293166') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1080, 613, 'Administrador', 'Nuevo ticket: perdida de agua en baño', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTA6SMM2-NT8V', 'franco ortiz', true, 1, '2026-08-29 09:20:40.458597', '2026-08-26 11:26:13.074377') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1082, 614, 'Administrador', 'Nuevo ticket: MAMOGRAFO', 'María del Carmen ha creado un nuevo ticket', 'TKT-MTALNHX3-OGZQ', 'María del Carmen', true, 1, '2026-08-29 09:20:40.458597', '2026-08-26 18:22:07.955754') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1154, 653, 'Sistemas', 'Nuevo ticket: Problemas con el correo no puedo abrirlo', 'Monica ha creado un nuevo ticket', 'TKT-MTSQFBBR-3M19', 'Monica', false, NULL, NULL, '2026-09-08 10:55:35.360612') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1083, 615, 'Mantenimiento', 'Nuevo ticket: PILAS', 'DANTE ha creado un nuevo ticket', 'TKT-MTHCH9QD-PF1E', 'DANTE', true, 10, '2026-08-31 11:52:54.575995', '2026-08-31 11:39:44.060728') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1087, 617, 'Compras e Insumos', 'Nuevo ticket: placas', 'mariela ha creado un nuevo ticket', 'TKT-MTILRQ5B-PT6F', 'mariela', false, NULL, NULL, '2026-09-01 08:47:34.627951') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1088, 618, 'Sistemas', 'Nuevo ticket: Prevención salud', 'julieta venturin ha creado un nuevo ticket', 'TKT-MTIM92C5-L512', 'julieta venturin', true, 3, '2026-09-02 08:04:17.512274', '2026-09-01 09:01:03.573031') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1084, 615, 'Administrador', 'Nuevo ticket: PILAS', 'DANTE ha creado un nuevo ticket', 'TKT-MTHCH9QD-PF1E', 'DANTE', true, 1, '2026-09-02 08:11:05.145586', '2026-08-31 11:39:44.13064') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1094, 621, 'Mantenimiento', 'Nuevo ticket: bolsas', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTIX0F8F-CP9K', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-01 14:02:16.114646') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1096, 622, 'Mantenimiento', 'Nuevo ticket: mal olor', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTIX2E44-E4S7', 'franco ortiz', true, 10, '2026-09-07 11:06:58.651423', '2026-09-01 14:03:48.021548') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1109, 630, 'Mantenimiento', 'Nuevo ticket: esta rota la tapa del inodoro', 'cecilia alfaro ha creado un nuevo ticket', 'TKT-MTK0YWCA-6M2K', 'cecilia alfaro', true, 10, '2026-09-07 11:06:58.651423', '2026-09-02 08:40:49.627829') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1155, 653, 'Administrador', 'Nuevo ticket: Problemas con el correo no puedo abrirlo', 'Monica ha creado un nuevo ticket', 'TKT-MTSQFBBR-3M19', 'Monica', false, NULL, NULL, '2026-09-08 10:55:35.405676') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1085, 616, 'Mantenimiento', 'Nuevo ticket: DISPENSER DE ALCOHOL', 'MATIAS ha creado un nuevo ticket', 'TKT-MTHHRYZL-0J8L', 'MATIAS', true, 10, '2026-09-01 14:01:38.048046', '2026-08-31 14:08:01.415317') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1092, 620, 'Mantenimiento', 'Nuevo ticket: Cerradura Puerta', 'GERMAN VIGON ha creado un nuevo ticket', 'TKT-MTISREK0-2F2X', 'GERMAN VIGON', true, 10, '2026-09-01 14:01:38.048046', '2026-09-01 12:03:16.89746') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1098, 623, 'Compras e Insumos', 'Nuevo ticket: agujas core biopsia 14ga x 10', 'MARIA DEL CARMEN HERRERA ha creado un nuevo ticket', 'TKT-MTIXU2DG-ZXPC', 'MARIA DEL CARMEN HERRERA', false, NULL, NULL, '2026-09-01 14:25:19.139968') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1099, 624, 'Compras e Insumos', 'Nuevo ticket: Materiales', 'jonatan ha creado un nuevo ticket', 'TKT-MTIY610Z-84JD', 'jonatan', false, NULL, NULL, '2026-09-01 14:34:37.267558') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1100, 625, 'Compras e Insumos', 'Nuevo ticket: PROFILÁCTICOS SIN LÁTEX', 'María del Carmen ha creado un nuevo ticket', 'TKT-MTJ9TT9W-WLT8', 'María del Carmen', false, NULL, NULL, '2026-09-01 20:01:02.742544') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1090, 619, 'Sistemas', 'Nuevo ticket: mouse', 'JONATAN ha creado un nuevo ticket', 'TKT-MTIQ67PM-XFSQ', 'JONATAN', true, 3, '2026-09-02 08:04:25.865004', '2026-09-01 10:50:49.013636') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1086, 616, 'Administrador', 'Nuevo ticket: DISPENSER DE ALCOHOL', 'MATIAS ha creado un nuevo ticket', 'TKT-MTHHRYZL-0J8L', 'MATIAS', true, 1, '2026-09-02 08:11:05.145586', '2026-08-31 14:08:01.455553') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1089, 618, 'Administrador', 'Nuevo ticket: Prevención salud', 'julieta venturin ha creado un nuevo ticket', 'TKT-MTIM92C5-L512', 'julieta venturin', true, 1, '2026-09-02 08:11:05.145586', '2026-09-01 09:01:03.617947') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1091, 619, 'Administrador', 'Nuevo ticket: mouse', 'JONATAN ha creado un nuevo ticket', 'TKT-MTIQ67PM-XFSQ', 'JONATAN', true, 1, '2026-09-02 08:11:05.145586', '2026-09-01 10:50:49.0866') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1093, 620, 'Administrador', 'Nuevo ticket: Cerradura Puerta', 'GERMAN VIGON ha creado un nuevo ticket', 'TKT-MTISREK0-2F2X', 'GERMAN VIGON', true, 1, '2026-09-02 08:11:05.145586', '2026-09-01 12:03:16.927381') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1095, 621, 'Administrador', 'Nuevo ticket: bolsas', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTIX0F8F-CP9K', 'franco ortiz', true, 1, '2026-09-02 08:11:05.145586', '2026-09-01 14:02:16.14889') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1097, 622, 'Administrador', 'Nuevo ticket: mal olor', 'franco ortiz ha creado un nuevo ticket', 'TKT-MTIX2E44-E4S7', 'franco ortiz', true, 1, '2026-09-02 08:11:05.145586', '2026-09-01 14:03:48.069396') ON CONFLICT DO NOTHING;
INSERT INTO public.notifications VALUES (1110, 630, 'Administrador', 'Nuevo ticket: esta rota la tapa del inodoro', 'cecilia alfaro ha creado un nuevo ticket', 'TKT-MTK0YWCA-6M2K', 'cecilia alfaro', true, 1, '2026-09-02 09:51:01.956376', '2026-09-02 08:40:49.66681') ON CONFLICT DO NOTHING;


--
-- Data for Name: push_metrics; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: push_subscriptions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: report_cache; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: shared_reports; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.shared_reports VALUES (2, 'bcf457afe0c0f27bebf2cbe78d9efc19248386d04eef21b9', 'Reporte 30d - Imagen Diagnóstica', '30d', 'all', 1, '2026-08-29 09:30:21.113063', '2026-09-05 12:30:21.112', true, 3, '2026-08-29 10:50:43.956202') ON CONFLICT DO NOTHING;


--
-- Data for Name: shared_tasks_boards; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.shared_tasks_boards VALUES (2, 'b185899dc1a0d69b323dc1dd0ea8ecae41c12885d95bc5e8', 'Auditoría Pública de Mantenimiento', 'Mantenimiento', 1, '2026-09-09 13:52:18.353', true, '2026-09-02 10:52:18.353498', '2026-09-02 10:52:18.353498') ON CONFLICT DO NOTHING;
INSERT INTO public.shared_tasks_boards VALUES (3, '3d107d49e3729b25ab4ec4291faf5172ac7fd203a2a8b083', 'Tablero de Tareas de Soporte Técnico - Imagen Diagnóstica', 'Sistemas', 3, '2026-09-09 13:57:48.531', true, '2026-09-02 10:57:48.532247', '2026-09-02 10:57:48.532247') ON CONFLICT DO NOTHING;
INSERT INTO public.shared_tasks_boards VALUES (4, '436b1ecbb198e12ccee30c05a0ec203eba980223fe18c95c', 'Tablero de Tareas y Mantenimiento - Imagen Diagnóstica', 'Mantenimiento', 10, '2026-09-14 14:59:49.653', true, '2026-09-07 11:59:49.654314', '2026-09-07 11:59:49.654314') ON CONFLICT DO NOTHING;


--
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.system_config VALUES ('areas_migrated_v2', 'true', '2026-01-16 13:12:02.727087') ON CONFLICT DO NOTHING;
INSERT INTO public.system_config VALUES ('default_users_created', 'true', '2026-01-16 13:35:38.605644') ON CONFLICT DO NOTHING;


--
-- Data for Name: ticket_updates; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ticket_updates VALUES (2, 38, 3, 'comment', 'Aguardamos por la computadora para poder revisarla y ver cual es el problema', '2026-01-21 09:41:39.884061') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (3, 34, 3, 'comment', 'Se quitó el elástico y colocó un suplemento interno para que el sistema funcione, el arreglo es provisorio, estamos a la espera de la multifunción que está en reparación', '2026-01-21 09:42:51.946653') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (4, 39, 3, 'comment', 'Problema resuelto', '2026-01-21 10:52:06.852203') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (5, 33, 3, 'comment', 'Nos comunicamos vía telefónica y a partir del día martes vendrán, confirman en el transcurso de la semana', '2026-01-21 11:05:44.195006') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (6, 37, 3, 'comment', 'Creada y segura. Ningún usuario puede entrar que no sean los solicitados', '2026-01-21 11:49:27.741084') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (7, 36, 3, 'comment', 'El día de mañana coordinaremos Rodolfo y Matías, día y horario en que se puede realizar sin afectar el servicio.', '2026-01-21 11:55:56.934308') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (8, 42, 3, 'comment', 'ya quedo funcionando . Saludos Matias', '2026-01-22 11:21:28.421304') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (9, 51, 3, 'comment', 'Hay un problema de red en general, servicios externos no cargan o cargan lento', '2026-01-23 08:04:05.993961') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (10, 52, 10, 'comment', 'se le hizo un carga de gas', '2026-01-23 08:44:14.83684') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (11, 51, 3, 'comment', 'Sistema reestablecido', '2026-01-23 09:17:01.279889') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (12, 55, 3, 'comment', 'Se corrigió el problema de red y telefónico.', '2026-01-23 11:34:14.8606') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (13, 46, 3, 'comment', 'Se mantiene ya que son mas de 10', '2026-01-23 11:41:41.243873') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (14, 38, 3, 'comment', 'Se elimino software innecesario y se actualizaron controladores, la pc muestra buenos signos, funciona veloz y sin trabas, para tareas de oficina tiene desempeño óptimo.', '2026-01-23 11:44:43.215502') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (15, 57, 11, 'comment', 'ya fueron pedidos, llegan el martes', '2026-01-23 11:55:21.547447') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (16, 48, 10, 'comment', 'se hablo con claudio y dijo que lo tienen que venir a ver el carpintero', '2026-01-23 13:47:42.486566') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (17, 50, 10, 'comment', 'se remplazo la cerradura', '2026-01-23 13:58:35.805722') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (18, 61, 10, 'comment', 'trabajo realizado', '2026-01-23 15:51:15.862721') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (19, 63, 3, 'comment', 'solucionado', '2026-01-24 11:12:24.079677') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (20, 60, 3, 'comment', 'Solucionado . Saludos', '2026-01-24 11:13:14.244448') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (21, 67, 3, 'comment', 'Se eliminó el usuario comprometido "juanivgc@gmail.com" y otro usuario adicional de la misma empresa/agencia para evitar posible nuevo conflicto. De esta manera, también se elimino el contenido del usuario comprometido y el contenido del usuario restante fue vinculado a Lorena Menegon ( no estaba comprometido ).

Se creo usuario para Rodolfo Vigon con propiedad Administrador para gestión de wordpress ( idiagnostica.com.ar )

Saludos!', '2026-01-26 10:25:25.265028');
INSERT INTO public.ticket_updates VALUES (22, 59, 11, 'comment', 'ya fue comprado', '2026-01-26 11:31:23.846102') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (23, 71, 10, 'comment', 'se destapo la manguera', '2026-01-27 08:58:00.672294') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (24, 68, 3, 'comment', 'Informado el error a Visual Medica para su corrección', '2026-01-27 09:55:27.572609') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (25, 68, 3, 'comment', 'Solucionado, error en la ruta, faltaba protocolo https', '2026-01-27 10:35:22.294429') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (26, 33, 3, 'comment', 'Cámara instalada', '2026-01-27 10:37:22.883188') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (27, 75, 10, 'comment', 'se logro destapar el caño del aire central', '2026-01-27 12:22:25.346126') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (28, 76, 10, 'comment', 'se le coloco un pasador en el piso. quedo operativo', '2026-01-27 12:48:29.373945') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (29, 81, 10, 'comment', 'se cambio llave y dicroica', '2026-01-28 10:13:27.671692') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (30, 43, 3, 'comment', 'se instalo e configuro el ecografo , lo uso Doctora Martinez el día Martes 27', '2026-01-29 08:51:31.328093') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (31, 89, 3, 'comment', 'Se cambio cable por uno nuevo', '2026-01-30 09:15:28.072299') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (32, 94, 3, 'comment', 'Telecom en Mendoza tuvo problema y el firewall perdió la ruta por defecto en la tabla de teco, se aplicó la solución y ya funcionan nuevamente.

Sergio.', '2026-01-31 08:52:25.990869');
INSERT INTO public.ticket_updates VALUES (33, 95, 3, 'comment', 'Se iniciaron nuevamente los servidores que por el corte de luz estaban apagados. Sistema reestablecido

Matias', '2026-01-31 08:56:32.098031');
INSERT INTO public.ticket_updates VALUES (34, 96, 3, 'comment', 'Gestionado 

Matias', '2026-01-31 09:01:31.924783');
INSERT INTO public.ticket_updates VALUES (35, 100, 3, 'comment', 'Gestionado

Rodolfo', '2026-01-31 11:19:16.20409');
INSERT INTO public.ticket_updates VALUES (36, 103, 3, 'comment', 'Problema reportado a VM, a la espera de revisión y corrección del error', '2026-02-02 10:02:27.577045') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (37, 103, 3, 'comment', 'informes normalizados, estaremos monitorizando el sistema', '2026-02-02 12:39:21.040036') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (38, 105, 3, 'comment', 'Solucionado

Sergio', '2026-02-02 13:31:00.692829');
INSERT INTO public.ticket_updates VALUES (39, 109, 3, 'comment', 'Solución aplicada

Matias', '2026-02-03 09:00:08.774846');
INSERT INTO public.ticket_updates VALUES (40, 111, 10, 'comment', 'se corrigio una fase y quedo operativo', '2026-02-03 09:32:56.174952') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (41, 112, 10, 'comment', 'se compro nuevo control por que el otro no tenia arreglo', '2026-02-03 10:56:28.590702') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (42, 83, 10, 'comment', 'se coloco zapatillas para la pc. se cambiar tomas corrientes por nuevos ( en los tomas antiguos habían varios cables sueltos que provocaron un corto circuito al abrirse)', '2026-02-03 10:58:07.335563') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (43, 146, 10, 'comment', 'se destapo la cámara de cloacas por que tenia muchos papeles', '2026-02-03 11:38:32.608117') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (44, 151, 3, 'comment', 'Al parecer ambas no existen o están dadas de baja', '2026-02-04 09:49:49.774963') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (45, 153, 3, 'comment', 'El equipo no tenia cable de red, ya se volvió a conectar

Matias', '2026-02-04 10:42:01.630367');
INSERT INTO public.ticket_updates VALUES (46, 152, 3, 'comment', 'Hubo un error de inicio de sesión, se reconectó

Matias', '2026-02-04 11:14:00.087548');
INSERT INTO public.ticket_updates VALUES (47, 154, 3, 'comment', 'Se realizó limpieza de ambos equipos, se intercambiaron y se conecto UPS en eco 1 como se requirió.

Rodolfo', '2026-02-04 13:31:43.729628');
INSERT INTO public.ticket_updates VALUES (48, 155, 3, 'comment', 'Se conecto al usuario a la carpeta pública

Rodolfo', '2026-02-04 13:34:19.014445');
INSERT INTO public.ticket_updates VALUES (49, 157, 3, 'comment', 'PC SAN MARTIN; llevada a ciudad para mantenimiento/reparación 

Rodolfo', '2026-02-04 13:36:08.508637');
INSERT INTO public.ticket_updates VALUES (50, 150, 3, 'comment', 'El fallo se encontró en el servidor y afecto al área en general', '2026-02-05 08:25:40.000582') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (51, 149, 3, 'comment', 'Un fallo en el servidor afecto en general al área', '2026-02-05 08:26:02.45193') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (52, 145, 10, 'comment', 'los zócalos los pegamos, al portón le colocamos silicona. al cartel le encontramos la fuente quemada, se debería cambiar', '2026-02-05 12:47:10.956541') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (53, 163, 10, 'comment', 'se cerro la salida de aire de rx', '2026-02-05 15:33:25.106338') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (54, 87, 11, 'comment', 'se esta evaluando como anda la actual', '2026-02-05 20:17:34.466811') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (55, 164, 10, 'comment', 'se volvio a atar la lona ya que el viento anterior la descolgo', '2026-02-06 08:22:25.534704') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (56, 164, 10, 'comment', 'se volvio a atar la lona ya que el viento anterior la descolgo', '2026-02-06 08:22:28.408516') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (57, 164, 10, 'comment', 'se volvio a atar la lona ya que el viento anterior la descolgo', '2026-02-06 08:22:30.803423') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (58, 164, 10, 'comment', 'se volvio a atar la lona ya que el viento anterior la descolgo', '2026-02-06 08:22:31.313419') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (59, 164, 10, 'comment', 'se volvio a atar la lona ya que el viento anterior la descolgo', '2026-02-06 08:22:31.558776') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (60, 36, 3, 'comment', 'Se cambió UPS de servidores, el UPS antiguo se va a verificar su estado debido a que mostraba un alerta. Se ordenó equipos.

Tarea realizada el día 31/01/2026. Matias', '2026-02-06 08:50:42.976263');
INSERT INTO public.ticket_updates VALUES (61, 168, 10, 'comment', 'se camabio luz de emergencia por una nueva.ya esta operativo', '2026-02-06 11:20:38.61551') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (62, 171, 10, 'comment', 'se pinto el pasamanos central', '2026-02-09 08:18:41.43327') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (116, 245, 3, 'comment', 'ya quedo instaldo. Saludos . Mati', '2026-02-23 12:57:17.476882') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (117, 224, 10, 'comment', 'tenia una fuga en el filtro. ya esta operativo', '2026-02-24 08:15:55.331739') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (118, 247, 3, 'comment', 'por favor podrias describirnos que peso va en cada equipo ??', '2026-02-24 10:34:37.549727') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (63, 172, 3, 'comment', 'La cuenta lujanc@idiagnostica.com.ar no estaba creada por inactividad superior a los 6 meses, se volvió a crear y de esta manera, se pudo recuperar contraseña de bot que fue modificada por error por otro usuario en la gestión de contraseñas de google.

Solución aplicada: Creación de lujanc@idiagnostica.com.ar, cambio de contraseña mediante recuperación vía email.

Mail y Bot accesibles para el usuario', '2026-02-09 08:54:33.369645');
INSERT INTO public.ticket_updates VALUES (64, 162, 3, 'comment', 'Se modificó el idioma a español

Matias', '2026-02-09 08:57:38.164856');
INSERT INTO public.ticket_updates VALUES (65, 177, 3, 'comment', 'Informado a VM', '2026-02-09 11:20:58.446934') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (66, 165, 10, 'comment', 'se llevo a que le cambiaran la base', '2026-02-09 11:59:04.638199') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (67, 178, 10, 'comment', 'se cambio cerradura rota por una nueva', '2026-02-09 13:31:38.770926') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (68, 177, 3, 'comment', 'El problema consiste en que la carga de paciente fue manual, entonces, el sistema carga ese tipo de datos y no el ID real ( DNI paciente ) que viene mediante Worklist. Para editar dicha información se debe utilizar la opción "Editar datos dicom" en el listado de estudios previo a informe.

Desde informes, me comunican que ya fueron cerrados los estudios con éste error, es decir, no se muestra correctamente el ID. 

Recomendamos validar datos de paciente previo a cierre de informes para evitar inconvenientes futuros.

Rodolfo Vigón', '2026-02-10 08:07:37.073571');
INSERT INTO public.ticket_updates VALUES (69, 189, 3, 'comment', 'El error surge debido a incompatibilidad con sistema operativo ( Windows 7 sin soporte ) la computadora de alto campo es de bajas especificaciones y debe ser reemplazada.

Se procederá a realizar el cambio de PC e instalación de Workstation, dependiendo de Visual Medica para activación de licencia.

1. Se armará el equipo nuevo e instalarán los programas necesarios
2. Una vez el equipo configurado se enviará la petición a VM con los accesos de conexión remota
3. Una vez configurado el sistema por VM se instalará la nueva PC
4. Se conectará la nueva PC al equipo Konica Minolta

Rodolfo Vigón', '2026-02-11 09:57:29.027082');
INSERT INTO public.ticket_updates VALUES (70, 190, 3, 'comment', 'Todos los turnos dados salen como AUSENTE, estoy verificando que esa información no sea erronea', '2026-02-11 11:31:45.821255') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (71, 183, 10, 'comment', 'se quito las manchas de humedad de las columnas y se enmasillo.', '2026-02-11 11:52:10.458507') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (72, 190, 3, 'comment', 'Verificar que los estudios ya estén cargados', '2026-02-11 12:35:47.484972') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (73, 190, 3, 'comment', 'Los estudios NO habían sido cargados al sistema PACS, lo cual derivó a que no pudieran hacer los informes y entrega del mismo.

Matias se encargo de subir cada estudio

Verificado cada estudio por Rodolfo y Matias

Ticket cerrado', '2026-02-11 13:55:43.277095');
INSERT INTO public.ticket_updates VALUES (74, 191, 10, 'comment', 'se logro pegar de vuelta el aluminio', '2026-02-11 13:57:11.273724') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (75, 193, 10, 'comment', 'cuando fui no vi la falla. pero al parecer tenia un cable flojo. se ajusto', '2026-02-11 15:08:08.0004') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (76, 194, 3, 'comment', 'se resetio la contrasela el usuario es alfaro y la contraseña Alfaro.01', '2026-02-11 15:43:10.249833') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (77, 194, 3, 'comment', 'saludos Matias', '2026-02-11 15:43:31.704865') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (78, 192, 3, 'comment', 'Se envio la foto que aparece el paciente en visualizadro web . saludos Matias', '2026-02-11 15:44:22.758696') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (79, 197, 3, 'comment', 'Caso asignado a Visual Medica para su resolución', '2026-02-12 10:29:23.879508') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (80, 197, 3, 'comment', 'Ticket de asignación VM 80302', '2026-02-12 10:33:30.702599') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (81, 201, 3, 'comment', 'Fe de erratas:

UPS APC 550 instalada', '2026-02-12 11:36:28.907924');
INSERT INTO public.ticket_updates VALUES (82, 181, 10, 'comment', 'se reparo la cortina. se sugiere que se manipulen con cuidado las cortinas.
el plafon fue remplazado', '2026-02-12 12:58:51.942695');
INSERT INTO public.ticket_updates VALUES (83, 145, 10, 'comment', 'se cambio la fuente del letrero', '2026-02-12 12:59:14.953384') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (84, 207, 3, 'comment', 'Se notificó sobre el corte del sistema debido a una actualización', '2026-02-13 07:54:03.927136') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (85, 207, 3, 'comment', 'Se notificó sobre el corte del sistema debido a una actualización', '2026-02-13 07:54:06.637091') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (86, 206, 3, 'comment', 'Hoy 9 AM abordaré este caso para encontrar donde está el fallo', '2026-02-13 07:55:01.180342') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (87, 170, 3, 'comment', 'se lo coloco la tapa del la cpu, saludos Matias', '2026-02-13 08:34:28.290741') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (88, 157, 3, 'comment', 'pc en reparacion', '2026-02-13 08:48:24.216041') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (89, 200, 3, 'comment', 'buen dia deberian coantactarse con el area comercial  de primera instancia para verificar ,por que se dio de baja esa apliicacion o no esta funcional.Si esta todo bien desde lo comercial contactaremos al area tecnica. Saludos cordiales', '2026-02-13 08:58:16.735711') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (90, 212, 3, 'comment', 'Hubo un reinicio de sistema debido a fallos, ya esta operativo', '2026-02-13 10:38:43.523335') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (91, 206, 3, 'comment', 'Reunión abordada y temas tratados, una nueva reunión se dará lugar el día Miércoles 18/02/2026 a las 09:00 Am para definición de nuevo flujo de trabajo.

Rodolfo Vigón', '2026-02-13 10:39:56.387436');
INSERT INTO public.ticket_updates VALUES (92, 210, 3, 'comment', 'Sistema reestablecido, hubo un fallo y VM ya lo resolvió', '2026-02-13 10:41:21.502375') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (93, 211, 3, 'comment', 'Error de servidor solucionado', '2026-02-13 11:12:48.557025') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (94, 213, 3, 'comment', 'Lo mas probable es que el paciente no se tomo del worklist .se tiene que llamar al soporte del equipo y pedir si lo pueden enviar al paciente . GONZALEZ, ISRAEL dni	54919218', '2026-02-13 13:52:40.946058') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (95, 213, 3, 'comment', 'el páciente se puede visualizar en el visualizador web , pero aparece sin numero de acceso ,saludos Mati', '2026-02-13 15:29:31.846635') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (96, 220, 3, 'comment', 'Se cambió vincha', '2026-02-18 10:54:39.5844') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (97, 222, 3, 'comment', 'Se cambió clave', '2026-02-18 10:55:02.267423') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (98, 223, 10, 'comment', 'se cambio lampara bipin', '2026-02-18 12:14:27.715217') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (99, 221, 10, 'comment', 'se pinto la parte de resonador y el vestidor.', '2026-02-18 12:15:09.502424') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (100, 189, 3, 'comment', 'resonador del cuarto piso ya puede imprimir . Saludos Mati', '2026-02-19 08:32:41.369932') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (101, 225, 3, 'comment', 'se cambio el camble . probemos con ese a ver si funciona mejor . Saludos Mati', '2026-02-19 08:51:00.618614') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (102, 206, 3, 'comment', 'El problema de informes fue resuelto el día de ayer y estaremos monitorizando si correcto funcionamiento', '2026-02-19 09:40:16.8085') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (103, 221, 10, 'comment', 'se termino de pintar sala de espera', '2026-02-19 11:51:11.012633') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (104, 230, 3, 'comment', 'Buen día, este pedido debe realizarse al área correspondiente de call center no a sistemas, de todas maneras lo pasamos', '2026-02-20 09:07:31.594303') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (105, 226, 3, 'comment', 'se conecto la carpeta solicitada . Saludos Mati', '2026-02-20 10:21:51.001265') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (106, 233, 10, 'comment', 'se cambio por un cartel nuevo', '2026-02-20 11:56:19.627795') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (107, 234, 10, 'comment', 'se cambiaron por nuevos', '2026-02-20 11:56:37.415529') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (108, 236, 10, 'comment', 'se había salido la manguera de desagote', '2026-02-20 11:58:57.942845') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (109, 237, 3, 'comment', 'Los documentos de la plataforma YAM se firman de manera digital, mediante el botón superior derecho "Firmar" de color verde', '2026-02-21 08:05:04.955895') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (110, 157, 3, 'comment', 'Reparada', '2026-02-21 09:46:06.14833') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (111, 241, 10, 'comment', 'se encontro caño de agua pluvial abierto. se compro y se coloco una tapa', '2026-02-23 10:44:33.645497') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (112, 243, 10, 'comment', 'se hablo con Claudio y estamos esperando la aprobación para intervenir detrás del mueble', '2026-02-23 10:45:36.316679') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (113, 237, 3, 'comment', 'Me confirman que los pasos están en el instructivo que fue compartido, para la instalación del programa editable, estaré pasando para instalarlo y explicar su uso', '2026-02-23 11:23:39.757015') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (114, 231, 10, 'comment', 'ya se pidio presupuesto. ahora a esperar que me lo manden', '2026-02-23 12:04:13.045919') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (115, 224, 10, 'comment', 'ya llame al andres. me dijo que mañana viene', '2026-02-23 12:04:37.452413') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (119, 248, 3, 'comment', 'lo esta verificamos con Mariana Zago , y esta funcionado para resonancias y tomografia. Saludos Mati', '2026-02-24 12:17:26.268024') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (120, 246, 10, 'comment', 'el agua provenía de un aire acondicionado del tercer piso del laboratorio. se había salido la manguera de la cañería. se volvio a colocar y poner pegamento para que no se salga devuelta', '2026-02-24 15:12:01.295176') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (121, 243, 10, 'comment', 'se realizaron pruebas simulando lluvia en sectores para ver la filtracion. se logro encontrar la filtracion, se encuentra entre el edificio del vecino y el de imagen,', '2026-02-24 15:13:21.570692') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (122, 250, 10, 'comment', 'se le coloco una pequeña perilla en los lockers nuevos', '2026-02-25 12:45:07.323678') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (123, 256, 3, 'comment', 'Se estaba accediendo a una carpeta errónea, ya está solucionado

Matias', '2026-02-26 09:44:46.460824');
INSERT INTO public.ticket_updates VALUES (124, 261, 10, 'comment', 'se le reviso la presiones de gas y tenia bajo. se le coloco gas y quedo bien', '2026-02-26 13:12:04.007532') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (125, 231, 10, 'comment', 'listo ya se solicito el presupuesto', '2026-02-26 13:42:37.30523') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (126, 262, 3, 'comment', 'El sistema esta estable, cual fue el error? Podría comunicarse al interno 660? Gracias', '2026-02-27 09:00:18.394669') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (127, 243, 10, 'comment', 'se le coloco membrana liquida para que se filtre entre las grietas y tape.', '2026-02-27 11:37:25.224719') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (128, 266, 10, 'comment', 'se le coloco un nuevo tornillo a la silla', '2026-02-27 14:39:34.421995') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (129, 272, 10, 'comment', 'En atención a su distinguida solicitud relativa a la optimización tribológica del sistema articulado de cierre de acceso peatonal (comúnmente denominado “puerta”), me permito informar que he procedido a realizar un análisis preliminar del conjunto bisagra-marco-hoja, identificando como variable crítica el coeficiente de fricción dinámico generado por la interacción metal-metal en condiciones de microvibración estructural.

Tras una inspección visual y auditiva (incluyendo evaluación espectroacústica del chirrido intermitente), se determinó la presencia de fricción adhesiva con probable déficit de película lubricante en el eje de rotación cilíndrico.}

Se aplicó agente lubricante de alta penetración, se realizaron ciclos de calibración mecánica y se validó el desempeño post-intervención.
Resultado: sistema silencioso, fricción controlada y desempeño óptimo dentro de parámetros domésticos internacionales.

La puerta se encuentra oficialmente en condiciones de operación premium.', '2026-03-02 10:38:32.800822');
INSERT INTO public.ticket_updates VALUES (130, 271, 3, 'comment', 'se le conecto el acceso a laos mails', '2026-03-02 11:14:31.352432') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (131, 274, 10, 'comment', 'se le cambio por una cerradura nueva', '2026-03-02 12:03:16.326327') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (132, 278, 10, 'comment', 'se cambio en el segundo piso y salida de genera', '2026-03-02 13:55:48.992431') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (133, 280, 3, 'comment', 'Se cambió micrófono', '2026-03-03 09:38:18.916954') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (134, 284, 3, 'comment', 'Es una falla del equipo, recomendamos reiniciar la computadora cuando pase eso para que el sistema del equipo se reestablezca. Estamos a la espera del soporte técnico de la marca', '2026-03-04 07:59:58.760629') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (167, 284, 3, 'comment', 'Se verifico el worklist , y se libero espacio en el disco . Saludos Mati', '2026-03-04 08:54:01.542436') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (168, 286, 10, 'comment', 'se le cambio el elemento dañado por uno nuevo. ya quedo operativo', '2026-03-04 14:30:14.616321') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (169, 285, 3, 'comment', 'Es un bug de la previsualización del programa Outlook, al abrir el email se ve el horario correcto', '2026-03-05 08:26:28.976106') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (170, 238, 10, 'comment', 'se cambiaron 2 plafones por nuevos', '2026-03-05 13:29:36.329196') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (171, 260, 10, 'comment', 'se pego la tira led.', '2026-03-05 13:30:08.696224') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (172, 287, 10, 'comment', 'se termino de colocar membrana liquida en la posible filtracion de agua del consultorio de tercer piso', '2026-03-06 13:02:35.732849') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (173, 295, 10, 'comment', 'se lijo y coloco masilla. ahora queda esperar que se seque la masilla para pintar', '2026-03-06 13:04:03.824516') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (174, 296, 10, 'comment', 'ya se llamo al tapicero el sábado pasa a retirar', '2026-03-06 14:00:51.11245') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (175, 249, 10, 'comment', 'el sabado se lleva a tapizar', '2026-03-06 14:01:14.629197') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (176, 300, 3, 'comment', 'Debido a un fallo de impresión, no podían procesarse nuevas, se limpió la fila e imprime normalmente.

Rodolfo', '2026-03-09 08:19:36.936015');
INSERT INTO public.ticket_updates VALUES (177, 299, 3, 'comment', 'Debido a un fallo de impresión, no podían procesarse nuevas, se limpió la fila e imprime normalmente.

Rodolfo', '2026-03-09 08:19:57.457301');
INSERT INTO public.ticket_updates VALUES (178, 297, 3, 'comment', 'Debido a un fallo de impresión, no podían procesarse nuevas, se limpió la fila e imprime normalmente.

Rodolfo', '2026-03-09 08:20:33.521113');
INSERT INTO public.ticket_updates VALUES (179, 292, 3, 'comment', 'Debido a un fallo de impresión, no podían procesarse nuevas, se limpió la fila e imprime normalmente.

Rodolfo', '2026-03-09 08:20:41.80201');
INSERT INTO public.ticket_updates VALUES (180, 298, 3, 'comment', 'Problema físico, estamos a la espera de que llegue el componente roto ( captor de papel ) para la reparación', '2026-03-09 08:34:54.667537') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (181, 304, 3, 'comment', 'se reinicio , funciono la pantalla gracias a la ayuda de Mariana . Saludos Mati', '2026-03-09 09:51:34.327286') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (182, 302, 10, 'comment', 'al parecer dejaron un poco abierta la ventana y entro agua por ahi', '2026-03-09 09:57:32.230693') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (183, 298, 3, 'comment', 'repuesto cambiado probar si esta tomando las hojas bien . Saludos .Mati', '2026-03-09 12:28:35.627056') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (184, 293, 3, 'comment', 'se realizo pruebas de envieo de correo salieron y llegaron sin problemas. Saludos .Mati', '2026-03-09 12:45:12.644798') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (185, 307, 3, 'comment', 'Solicito listado de prestadores activos para modificarlos en HUB. Sancor removido', '2026-03-10 08:14:40.014708') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (186, 315, 10, 'comment', 'se compro una nueva manija y se cambio.', '2026-03-10 14:36:07.142172') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (187, 310, 10, 'comment', 'estaban quemadas. se cambiaron por nuevas', '2026-03-11 13:54:59.524974') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (188, 260, 10, 'comment', 'se saco el porcelanato y se volvio a pegar', '2026-03-11 13:55:42.145354') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (189, 319, 3, 'comment', 'se agrego el llamador de ecografia al usuario razeglio. Saludos Mati', '2026-03-11 14:19:28.580051') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (190, 364, 3, 'comment', 'Se hizo el sábado 14/03', '2026-03-16 08:47:19.633272') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (191, 363, 3, 'comment', 'Ya se pidieron los materiales a reemplazar para la TV, tema totem fue solucionado el día 14/03', '2026-03-16 08:48:01.63564') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (192, 362, 11, 'comment', 'SE AUTORIZA LA COMPRA EN ELECTROSOF', '2026-03-16 08:52:24.813777') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (193, 368, 3, 'comment', 'quedo  matricula  cambiada tal lo solicitado Borgia Laura .Saludos Mati', '2026-03-16 14:26:53.656802') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (194, 374, 3, 'comment', 'Se agrandó el tamaño en Ciudad ( PB y P1 ).

Cabe aclarar que es lo más grande que se puede mediante zoom, si se desea agrandar mas pero que no se pierda de la pantalla, debe ser editado en su código, para ello, hay que comunicarlo a VM para que lo ajuste en base a la resolución de pantalla.

Respecto a Maipú tiene un solo botón que es de recepción, pero esta mal estilizado y ajustado a la pantalla. 

En síntesis, en ambos casos se debe cambiar el CSS', '2026-03-17 11:17:26.614439');
INSERT INTO public.ticket_updates VALUES (195, 372, 10, 'comment', 'se limpio los filtros de los split', '2026-03-17 12:11:13.941332') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (196, 370, 3, 'comment', 'la instancia de Microsoft Word en el servidor quedo abierta y bloqueaba la nueva, entonces mostraba un error que no permitía modificar el informe', '2026-03-18 09:17:56.411258') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (197, 378, 10, 'comment', 'se enmasillo la pared para pintar', '2026-03-18 14:53:59.509719') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (198, 363, 3, 'comment', 'Se automatizó la carga de Cartel llamador en TV, garantizando así que se muestre si o si, ya que si por algún motivo se cierra, vuelve a levantar solo a los 5 segundos mediante script', '2026-03-20 09:34:47.110371') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (199, 389, 3, 'comment', 'ya se conecto el publico . saludos MATI', '2026-03-20 10:20:56.582697') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (200, 398, 3, 'comment', 'Se añadió correo electrónico', '2026-03-26 08:35:48.903462') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (201, 396, 3, 'comment', 'se esta evaluando hacer un cableado para agregar un telefono', '2026-03-26 16:05:13.379006') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (202, 414, 3, 'comment', 'consola agregada. saludos Mati', '2026-03-26 16:12:01.426512') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (203, 424, 3, 'comment', 'Se reporto el problema al soporte técnico de la impresora', '2026-03-30 10:49:08.542328') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (204, 423, 3, 'comment', 'Se reporto el problema al soporte técnico de la impresora', '2026-03-30 10:49:13.015793') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (205, 434, 3, 'comment', 'Se reemplazó la PC', '2026-04-01 10:46:45.385017') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (206, 438, 11, 'comment', 'ya pedidas llegan viernes', '2026-04-06 11:11:06.021794') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (207, 446, 3, 'comment', 'Reparado y funcionando', '2026-04-08 08:28:12.869355') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (208, 447, 3, 'comment', 'Lo técnicos vendrán nuevamente para verificar el equipo', '2026-04-09 08:09:15.042012') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (209, 413, 3, 'comment', 'Visual Medica confirma que el sistema no permite este tipo de modificaciones', '2026-04-09 08:10:37.652502') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (210, 447, 3, 'comment', 'Los técnicos realizaron la visita y se encuentra operativa nuevamente.', '2026-04-10 08:16:46.634115') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (211, 456, 3, 'comment', 'sistema reestablecido', '2026-04-11 09:33:51.172215') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (212, 455, 3, 'comment', 'Aplicaciones instaladas y listas para usar, se configuro también, la impresora brother y ya se puede imprimir con normalidad', '2026-04-11 09:34:19.730362') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (213, 453, 3, 'comment', 'Solucionado', '2026-04-11 09:34:35.633226') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (214, 450, 3, 'comment', 'Nos comunicamos con el soporte y estamos a la espera', '2026-04-11 09:35:02.493352') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (215, 416, 3, 'comment', 'El boton va de la mano con un piso en concreto, debe ir con PB o P1, pero no con ambos, recomiendo dejarlo tal cual está para que el número sea retirado en PB ( cuando entran ) por los pacientes', '2026-04-11 09:35:56.792423') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (216, 465, 3, 'comment', 'El estudio es Eco TV', '2026-04-14 11:41:17.4145') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (217, 466, 3, 'comment', 'El scanner funciona correctamente', '2026-04-15 10:32:52.975246') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (218, 465, 3, 'comment', 'se modificaros los estudios se volvieron enviar al pacs y se pudo informar . Saludos Mati', '2026-04-16 08:28:39.388965') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (219, 484, 10, 'comment', 'no se encontro regatones del tamaño de las patas de la camilla pero se mando a fabricar en 3d para probar', '2026-04-30 15:42:59.893196') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (220, 200, 3, 'comment', 'Cierro hasta que se avance nuevamente', '2026-05-05 08:55:22.352788') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (221, 519, 3, 'comment', 'Hay inconvenientes en general en la sede, estamos trabajando en ello', '2026-05-11 09:38:39.977132') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (222, 545, 3, 'comment', 'Se cambió AP de gerencia', '2026-07-15 08:06:59.311373') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (223, 607, 3, 'comment', 'Estamos a la espera de las impresoras en servicio técnico y será reemplazada', '2026-08-27 08:38:13.792911') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (224, 614, 10, 'comment', 'se le cargo agua', '2026-08-28 11:45:52.637088') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (225, 607, 3, 'comment', 'Se instaló impresora nueva, se retiro la dañada para enviar a servicio técnico', '2026-08-29 08:49:48.449727') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (226, 618, 3, 'comment', 'Activado', '2026-09-02 09:15:18.701825') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (235, 630, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por mantenimiento@tiquetera.com', '2026-09-02 11:13:54.538341') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (236, 630, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por mantenimiento@tiquetera.com', '2026-09-02 11:13:55.858944') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (237, 635, 3, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Sistemas', '2026-09-03 09:29:38.805319') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (238, 635, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-03 09:49:59.052684') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (239, 636, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-03 14:20:21.57232') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (240, 634, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Mantenimiento', '2026-09-03 14:20:38.582429') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (241, 634, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-03 14:20:40.847491') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (242, 630, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-03 14:20:51.886846') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (243, 636, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-03 14:49:28.805471') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (244, 637, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Mantenimiento', '2026-09-03 14:49:36.273476') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (245, 637, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-03 14:49:38.182015') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (246, 638, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Mantenimiento', '2026-09-03 14:50:35.624934') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (247, 638, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-03 14:50:38.054449') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (248, 638, 10, 'comment', 'no se cambio el cable por que no hacia falta. parece ser otra la falla', '2026-09-03 14:50:59.407482') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (249, 638, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-03 14:51:03.83939') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (250, 640, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Mantenimiento', '2026-09-03 15:20:27.023869') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (251, 639, 3, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Sistemas', '2026-09-04 08:13:36.672763') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (252, 640, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-04 08:27:25.886564') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (253, 641, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-04 08:34:36.602046') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (254, 641, 10, 'status_change', '🔄 Estado cambiado de "En Progreso" a "Abierto" por Mantenimiento', '2026-09-04 08:34:43.011622') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (255, 642, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-04 09:05:04.702333') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (256, 639, 3, 'comment', 'El problema se presenta en la pc box 2, la cual es host de la impresora, la PC tiene fallas aisladas, se quitará para examen el día lunes 07/09', '2026-09-04 09:06:16.69281') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (257, 640, 10, 'status_change', '🔓 Ticket reabierto por Mantenimiento (Estado: Abierto)', '2026-09-04 10:05:30.570512') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (258, 640, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-04 10:05:36.97914') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (259, 643, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-04 10:19:01.264497') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (260, 640, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-04 10:19:06.189661') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (261, 643, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-04 10:57:28.398661') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (262, 644, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Mantenimiento', '2026-09-04 10:58:27.814601') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (263, 644, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-04 10:58:30.015066') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (264, 645, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-07 08:01:39.955351') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (265, 639, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-07 08:01:46.054118') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (266, 646, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-07 08:06:59.257555') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (267, 647, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-07 09:17:50.146939') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (268, 641, 10, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Mantenimiento', '2026-09-07 09:17:53.714678') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (269, 647, 10, 'status_change', '🔒 Ticket cerrado por Mantenimiento', '2026-09-07 09:53:49.914294') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (270, 641, 10, 'status_change', '🔄 Estado cambiado de "En Progreso" a "Abierto" por Mantenimiento', '2026-09-07 09:53:59.597621') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (271, 648, 10, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Mantenimiento', '2026-09-07 12:06:36.58118') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (272, 649, 3, 'comment', 'aparece para visualizar e inromar de manera correcta . saludos', '2026-09-07 15:27:26.392203') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (273, 649, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-07 15:27:41.992367') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (274, 651, 3, 'comment', 'solucion', '2026-09-08 09:31:56.19889') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (275, 651, 3, 'priority_change', '⚠️ Prioridad cambiada de "Media" a "Baja" por Sistemas', '2026-09-08 09:31:59.275416') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (276, 651, 3, 'status_change', '🔒 Ticket cerrado por Sistemas', '2026-09-08 09:32:05.932212') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (277, 602, 11, 'status_change', '🔓 Ticket reabierto por Compras e Insumos (Estado: Abierto)', '2026-09-08 10:30:34.38625') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (278, 602, 11, 'status_change', '🔒 Ticket cerrado por Compras e Insumos', '2026-09-08 10:30:40.601453') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (279, 617, 11, 'status_change', '🔒 Ticket cerrado por Compras e Insumos', '2026-09-08 10:46:50.554889') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (280, 625, 11, 'status_change', '🔒 Ticket cerrado por Compras e Insumos', '2026-09-08 10:47:53.849398') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (281, 624, 11, 'status_change', '🔄 Estado cambiado de "Abierto" a "En Progreso" por Compras e Insumos', '2026-09-08 10:48:16.191816') ON CONFLICT DO NOTHING;
INSERT INTO public.ticket_updates VALUES (282, 624, 11, 'status_change', '🔒 Ticket cerrado por Compras e Insumos', '2026-09-08 10:48:18.947403') ON CONFLICT DO NOTHING;


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tickets VALUES (64, 'TKT-MKV15P4B-CJNY', 'NO PODEMOS INGRESAR A SAN MARTIN', 'TRATO DE INGRESAR Y NO SE PUEDE', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-01-26 07:34:13.749681', '2026-01-27 08:12:15.294457', '[]', 'TRANSCIPCIÓN', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (68, 'TKT-MKVKFZ9C-1PF1', 'problema en sistema de mendoza maquina segundo piso', 'no se puede copiar y pegar plantillas en sistema  de mendoza del segundo piso, despues que hubo problemas en el sistema', 'closed', 'medium', 'Sistemas', 'lorena cataldo', 'claudiacataldo01@gmail.com', 3, '2026-01-26 16:34:06.15399', '2026-01-27 10:35:34.883788', '[]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (33, 'TKT-MKMT4P7U-NZLM', 'CAMARA EN SALA DE MANTENIMIENTO', 'QUE PASO CON CAMPAGNNA Y LA INSTALACION DE LA CAMARA', 'closed', 'medium', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-01-20 13:27:20.87674', '2026-01-27 10:37:26.539064', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (43, 'TKT-MKPEI33C-WFNA', 'REEMPLZAO DE ECOGRAFO', 'FAVOR DISPONER EL CAMBIO DE ECOGRAFO Y CONFIGURACION  ANTES DEL RETIRO DEL EQUIPO PRESTADO', 'closed', 'medium', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-01-22 09:01:09.674001', '2026-01-29 08:51:34.611653', '[]', 'SEDE MAIIPU', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (36, 'TKT-MKMX3ZW7-ICQY', 'UPS', 'CUANDO VAN A INSTALAR LA UPS QUE CORRESPONDE AL RACK Y ORDENAR LOS CABLES', 'closed', 'medium', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-01-20 15:18:46.529864', '2026-02-06 08:50:46.119859', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (278, 'TKT-MM9EWC9B-JL07', 'carteleria de puerta', 'cambiar los cartes de tire y empuje por nuevo por q estan degastados', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-02 13:47:20.591914', '2026-03-02 13:55:54.159531', '[]', 'puertas', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (282, 'TKT-MMAWJBJU-GU3B', 'lockers', 'se le coloco una pequeña perilla a los lockers de rx', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-03 14:48:52.411512', '2026-03-03 15:20:48.382104', '[]', 'rx', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (31, 'TKT-MKLG52DO-MVZH', 'SEPI', 'se detecto que un modulo no estaba funcionando y se constato que no tenia gas por una perdida. se le llamo a Andrés.', 'closed', 'high', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-19 14:35:56.750865', '2026-01-19 14:36:11.372417', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (32, 'TKT-MKLG6HD7-GSKE', 'luces del frente', 'limpiar luces del frente que tienen insectos en su interior', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-19 14:37:02.830209', '2026-01-19 14:37:37.249241', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (35, 'TKT-MKMT9X1D-YMEJ', 'UPS', 'COLOCACION DE LA UPS QUE CORRESPONDE Y ORDENAMIENTO DEL RACK', 'closed', 'medium', 'Mantenimiento', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 10, '2026-01-20 13:31:24.290553', '2026-01-20 14:46:05.767196', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (23, 'TKT-MKL7S29C-C498', 'Estante flotante', 'Solicito la colocación de estante flotante en el área de sistemas', 'closed', 'low', 'Mantenimiento', 'Rodolfo Vigon', 'vigonr@idiagnostica.com.ar', 10, '2026-01-19 10:41:53.138871', '2026-01-21 09:32:31.910561', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (34, 'TKT-MKMT64RO-U8A4', 'IMPRESORA ATADA CON ELASTIQUIN', 'QUE PASO CON ESO  EL PROBLEMA NO QUEDO SOLUCIONADO', 'closed', 'medium', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-01-20 13:28:27.686676', '2026-01-21 09:42:50.882931', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (39, 'TKT-MKO2G2Y3-K4X5', 'IMPRESORA', 'NECESITO  QUE LA RECONFIGUREN  CUANDO TOMA EL PAPEL DE LA BANDEJA PRINCIPAL  LA IMPRESION SE CORRE O DESPLAZA Y NO SALE CENTRADA Y POR DEFECTO USAMOS LA BANDEJA EXTERNA', 'closed', 'medium', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-01-21 10:35:54.603991', '2026-01-21 10:52:10.162756', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (37, 'TKT-MKNXSFWW-8I85', 'Solicitud de carpeta con clave', 'Buen dia equipo, necesito una carpeta en le publico compartida con Lorena Menegon con clave', 'closed', 'medium', 'Sistemas', 'Guadalupe Sanchez', 'sanchezg@idiagnostica.com.ar', 3, '2026-01-21 08:25:33.201872', '2026-01-21 11:49:30.485603', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (42, 'TKT-MKOH4NTE-G541', 'TELEFONO SIN FUNCIONAR', 'No funciona el telefono del consultorio 6. no recibe llamadas.', 'closed', 'medium', 'Sistemas', 'Marcelo Castro', 'castrom@idiagnostica.com.ar', 3, '2026-01-21 17:26:56.020739', '2026-01-22 11:21:45.728773', '[]', 'ECOGRAFIA: CONSULTORIO 6', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (47, 'TKT-MKPLNSJN-O43M', 'pintura', 'paredes manchadas', 'closed', 'low', 'Mantenimiento', 'MARIELA', 'marielaajaya@gmail.com', 10, '2026-01-22 12:21:33.253625', '2026-01-22 14:02:46.137687', '[]', 'oficina workstation de rayos', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (49, 'TKT-MKPNYVX7-O6I0', 'TEMPERATURA ELEVADA', 'LA TEMPERATURA DE LA SALA DE RESONANCIA ESTÁ EN 25º', 'closed', 'high', 'Mantenimiento', 'JORGELINA ARAYA', 'ninajaraya@gmail.com', 10, '2026-01-22 13:26:10.07705', '2026-01-22 15:49:43.657639', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (52, 'TKT-MKQTBLNU-VKUV', 'aire', 'aire acondicionado eco 6 no enfria bien', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-23 08:43:47.564704', '2026-01-23 08:44:29.346561', '[]', 'eco 6', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (51, 'TKT-MKQQOJHP-GRD5', 'NO SE PUEDE INGRESAR A MAIPU', 'MAIPU NO FUNCIONA EL INGRESO', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-01-23 07:29:52.440374', '2026-01-23 09:17:04.129295', '[]', 'TRANSCIPCIÓN', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (45, 'TKT-MKPG6J4F-SMWL', 'sacar cable canal', 'El cable canal esta en el piso, debajo de la ventana', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-01-22 09:48:09.80922', '2026-01-23 09:29:13.093512', '[]', 'sala de densitometria', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (53, 'TKT-MKQVOYXP-IEQX', 'agua', 'agua', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-23 09:50:10.527522', '2026-01-23 09:50:24.348401', '[]', 'call center', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (54, 'TKT-MKQZ09DU-3A26', 'Informe de tareas', 'Se cambió:

1.  Mouse de Gerardo en 4to piso
2. Mouse recepción 1er piso Box 3
3. Computadora recepción 1er piso Box 3
4. Computadora informes ( Romina A )
5. Mouses y mouse pad en Call Center ( 7 )
6. Teclado Guadalupe S
7. Computadora de resonancia
8. Actualización de componentes a German V
9. Actualización de componentes a Veronica B
10. Cambio de monitor en recepción 1er Piso Box1
11. Cambio de disco a notebook HP 
12. Limpieza de software innecesario y actualización de controladores Notebook Guadalupe S ( Maipú )
13. Cambio de cable de red en facturación ( SM )
14. Se instaló nuevo Rack para servidores ( SM )
15. Gestión de usuarios de acceso a servidores ( SM )
16. Optimización de red wifi ID - SM ( SM )', 'closed', 'medium', 'Sistemas', 'Rodolfo', 'mail@mail.com', 3, '2026-01-23 11:22:56.132808', '2026-01-23 11:23:23.262911', '[]', 'Recepción', NULL);
INSERT INTO public.tickets VALUES (55, 'TKT-MKQZ8N7K-26WW', 'NO ANDAN LOS TELEFONOS', 'HH', 'closed', 'high', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-01-23 11:29:27.297606', '2026-01-23 11:34:24.677974', '[]', 'CALL CENTER', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (46, 'TKT-MKPI7Q7Y-G9MV', 'Obras sociales', 'Insertar obras sociales como accesos de hub para mejor desempeño de recepciones sin necesidad de logear en chrome para tener los marcadores guardados', 'closed', 'low', 'Sistemas', 'Rodolfo', 'mail@mail.com', 3, '2026-01-22 10:45:04.895254', '2026-01-23 11:41:45.491771', '[]', 'Recepciones', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (38, 'TKT-MKNYAKEV-J8XU', 'Computadora Maipú', 'Chicos, necesito que por favor revisen la computadora que utilizo en Maipú, ya que la semana pasada me costo mucho trabajar por que tarda en abrir los archivos, de echo hoy que tendría que haber ido no pude', 'closed', 'medium', 'Sistemas', 'Guadalupe Sanchez', 'sanchezg@idiagnostica.com.ar', 3, '2026-01-21 08:39:38.840254', '2026-01-23 11:44:47.172971', '[]', NULL, NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (56, 'TKT-MKQZA7F0-X1EO', 'PERDIDA DE AGUA', 'FAVOR CONTROLAR DESAGUES', 'closed', 'medium', 'Mantenimiento', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 10, '2026-01-23 11:30:40.141702', '2026-01-23 13:46:42.124849', '[]', 'TERRAZA CALLE NECOCHEA', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (44, 'TKT-MKPG4KNY-HYFE', 'cambiar el foco', 'La luz esta muy baja, amarilla', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-01-22 09:46:38.494816', '2026-01-23 13:47:07.276353', '[]', 'oficina de odontologia', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (48, 'TKT-MKPLQ0E2-8JFH', 'pegar los socalos', 'Estan presentados, y se caen, no estan pegados.', 'closed', 'low', 'Mantenimiento', 'MARIELA', 'marielaajaya@gmail.com', 10, '2026-01-22 12:23:16.731037', '2026-01-23 13:47:50.223745', '[]', 'sala de rayos', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (50, 'TKT-MKPPF1XJ-5VR9', 'picaporte', 'picaporte de la puerta de patio planta baja', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-22 14:06:43.982868', '2026-01-23 13:58:48.4468', '[]', 'mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (60, 'TKT-MKR7ORMI-PBRR', 'NO FUNCIONA WEB DE SAN MARTIN', 'no responde la web de sucursal san martin', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-01-23 15:25:56.443179', '2026-01-24 11:13:20.440016', '[]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (57, 'TKT-MKQZVTHS-4APK', 'Solicitud de compra', 'Se necesita realizar un pedido de 4 teclados de PC, para reemplazar los teclados viejos de informes, se especifica el modelo y adjunto link directo de compra. ya que tienen los botones multimedia que necesitan para trabajar eficiientemente.

Link 👉 https://www.mercadolibre.com.ar/teclado-verbatim-usb-wired-multimedia-cableado-98109/p/MLA24553065#reviews

Saludos!', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo', 'vigonr@idiagnostica.com.ar', 11, '2026-01-23 11:47:28.530517', '2026-01-26 10:00:49.90856', '[]', 'Informes', NULL);
INSERT INTO public.tickets VALUES (61, 'TKT-MKR7QRA5-JQ0F', 'luz de un consultorio, baño personal', 'solicito cambiar luz de un consultorio que esta quemado, ver mochila de baño y pegar zocalo de consultorio al lado de recepcion', 'closed', 'low', 'Mantenimiento', 'Fernando', 'rodriguezf@idiagnostica.com.ar', 10, '2026-01-23 15:27:29.310704', '2026-01-23 15:51:22.512411', '[]', 'genera salud', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (67, 'TKT-MKV4PZ39-P6PO', 'Error apartado "Novedades" en la web', 'Al cargar el apartado novedades la pagina no responde. mensaje: Esta página no funciona.', 'closed', 'high', 'Sistemas', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-01-26 09:13:58.631731', '2026-01-26 10:25:28.330066', '[]', 'MKT, Gestión de grillas, Call Center', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (63, 'TKT-MKSDKYUL-IW2Z', 'Ingreso a San Martín.', 'Chicos estaba tipeando un estudio y el sistema no me permite cerrarlo, salí e intenté volver a logearme pero no puedo.
Esto en la computadora de Mónica en transcripción.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-01-24 10:58:43.06309', '2026-01-24 11:12:27.517949', '[]', 'TRANSCIPCIÓN', NULL);
INSERT INTO public.tickets VALUES (62, 'TKT-MKSD86IS-O01U', 'Sistema de San Martín', 'Buenos Días: en la computadora de Mónica no se puede ingresar al sistema de San Martín.
Gracias!', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-01-24 10:48:46.470804', '2026-01-24 11:12:41.432402', '[]', 'TRANSCIPCIÓN', NULL);
INSERT INTO public.tickets VALUES (66, 'TKT-MKV3L277-H7PX', 'Ingreso a San Martin', 'Buenos Días! Chicos no puedo ingresar al sistema de San Martín desde mi computadora, en el cuarto piso.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-01-26 08:42:09.76598', '2026-01-27 08:12:10.680439', '[]', 'Transcripción', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (65, 'TKT-MKV1CUBW-3T6Z', 'VISUALIZADOR SAN MARTIN', 'NO FUNCIONA VISUALIZADOR DE SAN MARTIN EN MI PC', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-01-26 07:39:47.095261', '2026-01-27 08:12:12.448204', '[]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (70, 'TKT-MKWHS4KH-W2IM', 'WEB SAN MARTIN', 'No conecta visualizador web', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-01-27 08:07:20.227801', '2026-01-27 08:12:17.256614', '[]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (69, 'TKT-MKWGY0VW-CHIR', 'SAN MARTIN NO SE PUEDE INGRESAR', 'TRATO DE INGRESAR A SAN MARTIN Y NO SE PUEDE', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-01-27 07:43:55.782859', '2026-01-27 08:12:19.12789', '[]', 'TRANSCIPCIÓN', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (71, 'TKT-MKWJKTMF-MPRP', 'aire acondicionado', 'aire de del recepción del 4 piso pierde agua', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-27 08:57:38.680109', '2026-01-27 08:58:05.941685', '[]', '4 piso', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (73, 'TKT-MKWOR9QL-HJGU', 'lluvia agua', 'se inundo la cocina. se logro destapar el desagüe interviniendo en mamografía', 'closed', 'high', 'Mantenimiento', 'cristian', 'mantenimiento@tiquetera.com', 10, '2026-01-27 11:22:37.583844', '2026-01-27 11:22:52.875477', '[]', 'cocina', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (74, 'TKT-MKWOSJ6D-B8EF', 'aires', 'limpieza de turbina de eco 6', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-27 11:23:36.470598', '2026-01-27 11:23:47.703956', '[]', 'eco 6', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (75, 'TKT-MKWQVMYU-E68F', 'aire central', 'el aire central esta goteando', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-27 12:22:00.58427', '2026-01-27 12:22:29.122811', '[]', 'aire central', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (76, 'TKT-MKWRMPLG-1FDR', 'Puerta del patio pb', 'no cierra queda abierta', 'closed', 'medium', 'Mantenimiento', 'Fernando', 'rodriguezf@idiagnostica.com.ar', 10, '2026-01-27 12:43:03.702263', '2026-01-27 12:48:34.065673', '[]', 'gerencia', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (72, 'TKT-MKWK8OUH-15UI', 'disparador del equipo', 'colocar el disparador en la pared', 'closed', 'low', 'Mantenimiento', 'MARIELA', 'marielaajaya@gmail.com', 10, '2026-01-27 09:16:12.235211', '2026-01-27 13:55:08.797988', '[]', 'sala de rayos', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (78, 'TKT-MKWXE2BM-2DU9', 'equipo pausado por temperatura', 'se congela equipo de aire no refrigera sala de resonador', 'closed', 'high', 'Mantenimiento', 'gimena', 'gimenasolmanrique@gmail.com', 10, '2026-01-27 15:24:17.988416', '2026-01-27 16:56:19.686043', '[]', 'alto campo', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (79, 'TKT-MKWY8CWO-7Q1V', 'se pausa equipo por aumento de temperatura', 'se congela un equipo de aire y n i refrigera bien sala de resonador', 'closed', 'medium', 'Mantenimiento', 'gimena', 'gimenasolmanrique@gmail.com', 10, '2026-01-27 15:47:51.391527', '2026-01-27 16:56:24.461777', '[]', 'RMN 4to piso', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (80, 'TKT-MKXYU924-ZLOT', 'Dipenser', 'CAMBIO DE BIDON  DISPENSE RESONADOR PLANTA BAJA', 'closed', 'low', 'Mantenimiento', 'Vargas Aldana Noelia', 'aldanavargas@icloud.com', 10, '2026-01-28 08:52:39.006713', '2026-01-28 09:11:05.22083', '[]', 'Tomografia', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (82, 'TKT-MKY0PWOF-J0LY', 'aires de patio', 'limpieza de los aires de planta baja y primer piso del patio', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-28 09:45:15.569089', '2026-01-28 09:45:27.353824', '[]', 'mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (81, 'TKT-MKXZRJV3-R8MG', 'Problemas con la luz del cambiador', 'Problemas con la luz del cambiador', 'closed', 'medium', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-01-28 09:18:32.657787', '2026-01-28 10:13:33.109904', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (84, 'TKT-MKY2YB7F-2I6M', 'colocar servilletero', 'poner servilletero en la oficina y tacho de basura.', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-01-28 10:47:46.88056', '2026-01-28 12:03:20.709139', '[]', 'oficina workstation de rayos', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (85, 'TKT-MKY5QEAA-KJFL', 'puerta', 'se solto una madera de el marco de la puerta', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-01-28 12:05:36.468621', '2026-01-28 13:36:11.655238', '[]', 'dental', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (86, 'TKT-MKYB7H4I-BOEP', 'Compra de tapones de oídos  descartables para resonadores', 'Compra de tapones de oídos  descartables para resonadores.', 'closed', 'medium', 'Compras e Insumos', 'Estefania Gervilla', 'estefigervilla93@gmail.com', 11, '2026-01-28 14:38:51.39165', '2026-01-29 11:12:03.889252', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (77, 'TKT-MKWRON2L-TM9T', 'Sucursal Maipu', 'Consultorio 1 tanden de acompañantes le falta un tornillo a un asiento', 'closed', 'low', 'Mantenimiento', 'Fernando', 'rodriguezf@idiagnostica.com.ar', 10, '2026-01-27 12:44:33.743887', '2026-01-29 13:47:43.581941', '[]', 'gerencia', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (88, 'TKT-MKZL4X0Y-PV99', 'Instalación de impresora', 'Buen dia, necesito por favor que me instalen en mi PC la impresora de la oficina de informes y la Konica del primer piso. Muchas gracias', 'closed', 'medium', 'Sistemas', 'Romina Azeglio', 'romiazeglio@gmail.com', 3, '2026-01-29 12:04:34.355015', '2026-01-30 11:41:53.056456', '[]', 'Informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (95, 'TKT-ML28V6G3-0RXA', 'No hay internet', 'Estábamos sin luz. volvió pero el internet no', 'closed', 'medium', 'Sistemas', 'Sede Maipu', 'mail@mail.com', 3, '2026-01-31 08:44:23.149454', '2026-01-31 08:56:47.491316', '[]', 'Sede Maipu', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (83, 'TKT-MKY2WX3T-7Q37', 'poner la zapatilla de enchufes', 'corregir los enchufes que estan en la zapatilla', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-01-28 10:46:41.948361', '2026-02-03 10:58:09.971338', '[]', 'oficina workstation de rayos', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (148, 'TKT-ML6YRZ0X-D4NZ', 'bolsas', 'llevar bolsas a mamografia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-03 16:00:48.274163', '2026-02-03 16:01:02.656207', '[]', 'mamografria', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (164, 'TKT-ML9TBZO3-DYAU', 'lona', 'colocar bien la lona del exterior', 'closed', 'low', 'Mantenimiento', 'danilo barresi', 'barresid@idiagnostica.com.ar', 10, '2026-02-05 15:51:43.066581', '2026-02-06 08:22:39.064277', '[]', 'maipu', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (169, 'TKT-MLB6R5XB-MDCR', 'cartel en magnet monitor', 'cartel indica interior sin red
es donde controlamos helio y temperatura', 'closed', 'medium', 'Mantenimiento', 'GIMENA', 'gimenasolmanrique@gmail.com', 10, '2026-02-06 14:55:12.193391', '2026-02-06 15:13:25.416491', '[]', 'brivo', NULL);
INSERT INTO public.tickets VALUES (635, 'TKT-MTLFM2GR-U5H8', 'No carga work list en resonador abierto', 'No carga work list en resonador abierto, sin embargo hay pase de imagenes a PACS', 'closed', 'medium', 'Sistemas', 'Javier Rios', 'jarios160@gmail.com', 3, '2026-09-03 08:18:31.420911', '2026-09-03 09:49:59.012966', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (173, 'TKT-MLF4ZFP7-PG8R', 'Prueba de campo sede', 'Este es un ticket de prueba para verificar que el campo sede se guarda correctamente en la base de datos.', 'closed', 'medium', 'Sistemas', 'Usuario Prueba', 'prueba@test.com', 3, '2026-02-09 09:16:43.582714', '2026-02-09 11:21:03.728386', '[]', 'Inform�tica', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (270, 'TKT-MM6GWX0Z-FVCR', 'ventana de recepcion', 'la ventana de la recepcion no cerraba bien, se le ajusto los tornillos', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-28 12:20:28.212988', '2026-02-28 12:20:36.991956', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (209, 'TKT-MLKT7HQX-E7NA', 'impresora Minolta', 'se traba las hojas como ya pasaba anteriormente', 'closed', 'medium', 'Mantenimiento', 'pepa shirley', 'pepas@idiagnostica.com', 10, '2026-02-13 08:33:41.145691', '2026-02-13 15:17:03.750467', '[]', 'recepción', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (213, 'TKT-MLL0GWF7-65Y7', 'GONZALEZ, ISRAEL dni	54919218. no se sube imagen al visual', 'GONZALEZ, ISRAEL dni	54919218. no se sube imagen al visual', 'closed', 'medium', 'Sistemas', 'veronicappriano', 'verinew33@gmail.com', 3, '2026-02-13 11:56:57.380517', '2026-02-13 15:29:35.684413', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (180, 'TKT-MLFGMGIM-I2EL', 'caja', 'cortar una bandeja para que entre en el cajon', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-09 14:42:33.503256', '2026-02-09 14:56:05.279221', '[]', 'recepción tercer piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (634, 'TKT-MTKDNNFE-3S9W', 'pala', 'arreglar una palita de basura', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-02 14:35:59.84614', '2026-09-03 14:20:40.818461', '[]', 'maestranza', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (214, 'TKT-MLL8EA8N-RO1Q', 'baño', 'pegar la jabonera que se mueve del baño de la recepción', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-13 15:38:52.260043', '2026-02-13 15:43:37.627994', '[]', '2 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (216, 'TKT-MLL8MLLX-2B89', 'Mouse roto', 'solicito cambio de mouse de una de las computadoras de recepción. no funciona..', 'closed', 'low', 'Mantenimiento', 'PAEZ NATALIA', 'paezn@idiagnostica.com.ar', 10, '2026-02-13 15:45:20.231544', '2026-02-13 15:52:19.899468', '[]', 'recepción', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (625, 'TKT-MTJ9TT9W-WLT8', 'PROFILÁCTICOS SIN LÁTEX', 'HAY PACIENTES QUE SON ALÉRGICAS AL LÁTEX, DEBE HABER EN CADA CONSULTORIO DONDE SE REALIZAN TRANSVAGINAL GUANTES Y PROFILACTICOS 
 SIN LÁTEX', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-09-01 20:01:02.718152', '2026-09-08 10:47:53.818428', '[]', 'SECTOR  DE ECOGRAFIAS', 'Ciudad');
INSERT INTO public.tickets VALUES (183, 'TKT-MLGOKV56-ZNNV', 'columna', 'reparar la columnas que estaban con humedad. y volver a pintar', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-10 11:13:02.251596', '2026-02-11 11:52:16.568815', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (198, 'TKT-MLJCX1EV-DYL4', 'Camara', 'Se cambio la camara del call center', 'closed', 'medium', 'Sistemas', 'Matias', 'mail@mail.com', 3, '2026-02-12 08:09:53.394575', '2026-02-12 08:09:58.527234', '[]', 'Call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (195, 'TKT-MLIHLLJC-P4F2', 'se me cae la ventana de la computadora permanentemente, por favor chequear eso', 'estoy usando la computador por ejemplo en la venta del bot y de la nada se me cae la ventana del bot y anda bastante lento', 'closed', 'medium', 'Sistemas', 'claudia raiano', 'Raianoc@idiagnostica.com.ar', 3, '2026-02-11 17:33:11.499766', '2026-02-12 10:06:12.727107', '[]', 'call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (201, 'TKT-MLJK4HBH-6FE3', 'UPS', 'Se instaló UP apc 200 en el consultorio 3', 'closed', 'medium', 'Sistemas', 'Matias', 'mail@mail.com', 3, '2026-02-12 11:31:37.997845', '2026-02-12 11:31:44.032784', '[]', 'Consultorio 3', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (293, 'TKT-MMDTA3WB-2HUH', 'mail', 'el correo electronico me rechaza los mail que envio,', 'closed', 'medium', 'Sistemas', 'SHIRLEY PEPA', 'pepas@idiagnostica.com.ar', 3, '2026-03-05 15:41:02.26942', '2026-03-09 12:45:16.668198', '[]', 'facturación', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (207, 'TKT-MLK1H5QQ-KRY8', 'se cayo sistema', 'desde las 16 hs se cayo el sistema, si bien los de recepción podían cargar el paciente, pero no podían adjuntar el pedido o RP
por ende agregue en donde escribimos el diagnostico, q estudio era cada uno', 'closed', 'medium', 'Sistemas', 'jessica johanna azcurra', 'jessicaazcurra@hotmail.com', 3, '2026-02-12 19:37:22.933851', '2026-02-13 07:54:14.400984', '[]', 'Tomografia', 'Ciudad');
INSERT INTO public.tickets VALUES (212, 'TKT-MLKUUTM4-8YXV', 'Sin sistema de Mendoza en compu del 4', 'Sin sistema de Mendoza en compu del 4', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-02-13 09:19:49.234168', '2026-02-13 10:38:46.236123', '[]', 'Transcripción', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (211, 'TKT-MLKUK4XV-E8M8', 'No funciona el sistema', 'No podemos transcribir informes', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-02-13 09:11:30.694297', '2026-02-13 11:12:51.598887', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (205, 'TKT-MLK15OEW-CJ9C', 'No se cargan las ordenes medicas.', 'No se cargan las ordenes medicas.', 'closed', 'medium', 'Sistemas', 'Valentina', 'valeendileo@gmail.com', 3, '2026-02-12 19:28:27.25343', '2026-02-13 12:17:18.515295', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (204, 'TKT-MLK101WM-5RZ2', 'no puedo ver pedidos medicos', 'no se puede escanear ordenes por ello no se que es lo que debe hacerse el paciente ,,,si solicitan alguna secuencia o el porque del pedido', 'closed', 'medium', 'Sistemas', 'Gimena Soledad Manrique Olivera', 'gimenasolmanrique@gmail.com', 3, '2026-02-12 19:24:04.803981', '2026-02-13 12:17:26.809607', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (220, 'TKT-MLRXI4IT-ST82', 'Vincha', 'La vincha funciona mal, necesita reposición.', 'closed', 'medium', 'Sistemas', 'maria jose calvo', 'mariajosecalvo02@gmail.com', 3, '2026-02-18 08:08:18.932289', '2026-02-18 10:54:42.023025', '[]', 'Call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (222, 'TKT-MLRZ4HZB-R8G2', 'clave de medical workstation', 'No puedo ingresar con mi clave', 'closed', 'medium', 'Sistemas', 'JORGELINA ARAYA', 'ninajaraya@gmail.com', 3, '2026-02-18 08:53:42.409793', '2026-02-18 10:55:06.131365', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (223, 'TKT-MLRZV8S3-K8XA', 'luz baño', 'se quemo una luz en el baño', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-18 09:14:30.197317', '2026-02-18 12:14:36.714553', '[]', 'eco 1', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (219, 'TKT-MLRWRQ77-631I', 'ERROR 500', 'visualizador mendoza: Error 500', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-18 07:47:47.335619', '2026-02-19 08:20:45.712503', '[]', 'informes', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (217, 'TKT-MLMC78L1-AA84', 'NO HAY SISTEMA EN CIUDAD - ERROR 500', 'NO HAY SISTEMA EN CIUDAD - ERROR 500', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-02-14 10:13:08.151781', '2026-02-19 08:20:56.690474', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (225, 'TKT-MLS6P241-IEQ0', 'cambio de cable de audio', 'necesito por favor un nuevo cable extensor de audio para la PC del 2do piso ya que el que esta no funciona bien, y se escuchan muy entrecortados los audios.', 'closed', 'medium', 'Sistemas', 'ROMINA AZEGLIO', 'romiazeglio@gmail.com', 3, '2026-02-18 12:25:38.931537', '2026-02-19 08:51:04.702362', '[]', 'informes', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (206, 'TKT-MLK18LQV-CEN1', 'tenemos muchos reclamos de informes y sobre todo de cone bean', 'tenemos muchos reclamos de informes y sobre todo de cone bean', 'closed', 'medium', 'Sistemas', 'facundo benito', 'benitof@idiagnostica.com.ar', 3, '2026-02-12 19:30:43.772414', '2026-02-19 09:40:19.712695', '[]', 'call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (221, 'TKT-MLRY29MH-CR6H', 'pintura', 'pintar la sala de espera 4 piso y vestidores', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-18 08:23:58.650653', '2026-02-19 11:51:24.927891', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (224, 'TKT-MLRZW8QJ-HUCT', 'aire acondicionado', 'el aire del eco 6 no enfría', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-18 09:15:16.798005', '2026-02-24 12:16:23.153085', '[]', 'eco 6', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (171, 'TKT-MLB9A036-PN7N', 'escalera', 'pintar de negro el pasamanos', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-06 16:05:50.324386', '2026-02-09 08:18:45.91755', '[]', 'escalera', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (59, 'TKT-MKR0DRCG-NYG6', 'Compra de router', 'Se solicita la compra del router Mikrotik para reemplazar lo que actualmente maneja una PC, es necesaria la compra para optimizar las redes del sistema.

Esta compra es inteligente ya que optimiza el flujo de trabajo y libera una computadora para ser reutilizada en otra área.

Link 👉 https://www.mercadolibre.com.ar/router-mikrotik-rb4011igsrm-10-puertos-lan-gigabit-negro/p/MLA14743213#polycard_client=search-desktop&search_layout=grid&position=1&type=product&tracking_id=d9071214-4926-43c3-ad0b-f52b8e0d2e82&wid=MLA877482497&sid=search', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo', 'vigonr@idiagnostica.com.ar', 11, '2026-01-23 12:01:25.553346', '2026-01-29 12:28:46.418078', '[]', 'Sistemas en MAIPÚ', NULL);
INSERT INTO public.tickets VALUES (653, 'TKT-MTSQFBBR-3M19', 'Problemas con el correo no puedo abrirlo', 'No puedo usar el correo de la empresa, no me deja abrirlo', 'open', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-09-08 10:55:35.32048', '2026-09-08 10:55:35.32048', '[]', 'INFORMES', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (157, 'TKT-ML890Z0R-EK9Z', 'Computadora', 'la pc se apaga se reinicia, no podemos usarla', 'closed', 'medium', 'Sistemas', 'Sede San Martin', 'mail@mail.com', 3, '2026-02-04 13:35:30.507952', '2026-02-21 09:46:09.524316', '[]', 'Resonancia', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (89, 'TKT-MKZLFUYJ-LYQ0', 'CAMBIO DE CABLE', 'SE DESCONECTA INTERNET DE LA COMPUTADORA DE POLETTO', 'closed', 'medium', 'Sistemas', 'MARIELA', 'marielaajaya@gmail.com', 3, '2026-01-29 12:13:04.905368', '2026-01-30 09:15:31.352675', '[]', 'ODONTOLOGIA', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (90, 'TKT-MKZLYR95-7ARG', 'Falla de Temperatura', 'Estaba empezando el segundo estudio en el paciente Castro, Héctor y el equipo no inicia por pérdida de comunicación con canal 2 del regulador de temperatura. Se reinicia. Jonatan informado. Temperatura en gabinetes es normal.', 'closed', 'medium', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-01-29 12:27:46.554536', '2026-01-30 09:44:44.744711', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (92, 'TKT-ML0UQXQ4-ZQMZ', 'Llave de luz y enchufe', 'La caja de la llave de luz y enchufe en el área del ingreso se ha soltado de la pared. Esta colgando de los cables.', 'closed', 'medium', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-01-30 09:21:24.413731', '2026-01-30 10:06:09.395134', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (93, 'TKT-ML0X5FKB-ARQP', 'No podemos ingresar al sistema de San Martín', 'Buenos Días Chicos: desde mi computadora en el 4 piso y la computadora de Mónica en el primero no podemos ingresar al sistema de San Martín para transcribir informes.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-01-30 10:28:39.948084', '2026-01-30 11:41:49.293073', '[]', 'Transcripción', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (91, 'TKT-ML0TAIPP-LQEN', 'Cable canal', 'Colocar cable canal en el área de odontología para cableado de red', 'closed', 'low', 'Mantenimiento', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 10, '2026-01-30 08:40:38.84627', '2026-01-30 14:53:22.013306', '[]', 'Odontología', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (94, 'TKT-ML28TGSU-E1AO', 'Telefonos no funcionan', 'Estamos sin telefonos ip internos y salida en el call', 'closed', 'medium', 'Sistemas', 'SM', 'mail@mail.com', 3, '2026-01-31 08:43:03.257462', '2026-01-31 08:52:28.938946', '[]', 'Sede San Martin', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (96, 'TKT-ML29GZS8-MIM4', 'Servidor', 'Aproximadamente a las 18:40 se dió soporte a sede SM por problemas en los servidores', 'closed', 'medium', 'Sistemas', 'SM', 'mail@mail.com', 3, '2026-01-31 09:01:20.948655', '2026-01-31 10:10:47.362422', '[]', 'Sede San Martin', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (100, 'TKT-ML2EDX5I-TIDA', 'Cambio de PC', 'Se realizó un cambio de PC para el consultorio 1, la PC cuenta con mejores especificaciones que la antigua que será reasignada. Se mantuvo el disco viejo como secundario, en caso de tener que bootear o acceder a archivos.', 'closed', 'medium', 'Sistemas', 'Rodolfo VIgon', 'mail@mail.com', 3, '2026-01-31 11:18:55.647562', '2026-01-31 11:19:20.93178', '[]', 'Consultorio 1 - Primer piso', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (102, 'TKT-ML52ARV8-KL0S', 'SISTEMA MENDOZA', 'DESDE EL VIERNES LA PAGINA SE CAE CUANDO SE INTENTA GUARDAR EL INFORME, QUEDANDO EL MISMO BLOQUEADO', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-02 08:03:52.015418', '2026-02-02 08:34:29.758826', '["/uploads/tickets/ticket-1770030231948-247887919.png"]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (101, 'TKT-ML524CP1-MFV6', 'No podemos cerrar estudios se cierra la pagina y no podemos avanzar problema avisado el sábado y ahora se junta que los médicos no pueden firmar estudio.', 'se pasa el informe cuando queremos guardar se cierra el sistema', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-02-02 07:58:52.86395', '2026-02-02 08:34:30.686738', '[]', 'TRANSCIPCIÓN', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (99, 'TKT-ML2C54QK-9HXI', 'Error al cerrar estudios', 'Nos salta un error al cerrar estudios. Ya genere un ticket anterior por esto, solo adjunto imagen del error.', 'closed', 'medium', 'Sistemas', 'Romina Azeglio', 'romiazeglio@gmail.com', 3, '2026-01-31 10:16:06.333199', '2026-02-02 08:34:31.805263', '["/uploads/tickets/ticket-1769865366323-43715245.jpeg"]', 'Informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (98, 'TKT-ML2C37DS-X8R4', 'Error al cerrar estudios', 'Nos salta un error con algunos estudios (en gral mamografia y RM hasta el momento), que luego de transcribirlos salta un error y no cierra el estudio, lo deja bloqueado por el usuario.', 'closed', 'medium', 'Sistemas', 'Romina Azeglio', 'romiazeglio@gmail.com', 3, '2026-01-31 10:14:36.449585', '2026-02-02 08:34:35.158408', '[]', 'Informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (97, 'TKT-ML29YPPV-X4BV', 'Falla de Escaner', 'Equipo falla en inicio de estudio de Rodilla con bobina de extremidad. Se reinicia sin resultado y se apaga. Funciona para siguiente paciente. (Col. Lumbar). Muestra "FALLA DE ESCANER"  en el registro del equipo.', 'closed', 'medium', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-01-31 09:15:07.701619', '2026-02-02 09:44:04.366998', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (104, 'TKT-ML5BNBW3-LPGO', 'tablero', 'el sábado se realizo el traspaso del tablero de la terraza al tablero nuevo en la sala de maquinas del alto campo, se interrumpio por la lluvia el traspaso pero quedo operativo el 80%. 
el lunes se termino de hacer las ultimas conexiones, 
ya esta operativo  al 100%', 'closed', 'high', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-02 12:25:34.333644', '2026-02-02 12:25:46.519233', '["/uploads/tickets/ticket-1770045934121-96300900.jpeg", "/uploads/tickets/ticket-1770045934198-57776182.jpeg"]', 'mantenimiento', NULL);
INSERT INTO public.tickets VALUES (103, 'TKT-ML53U26V-EQT5', 'SISTEMA MZA NO GUARDA INFOR', 'nuevamente dejó de funcionar el sistema de mendoza para guardar informes, se arregla y se vuelve a caer', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-02 08:46:51.419319', '2026-02-02 12:39:25.815497', '[]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (105, 'TKT-ML5DHJBW-SEDU', 'No cargan imagenes', 'No cargan las imagenes de los equipos al sistema', 'closed', 'medium', 'Sistemas', 'Sede Maipu', 'mail@ejemplo.com', 3, '2026-02-02 13:17:03.2626', '2026-02-02 13:31:03.171124', '[]', 'Imagenes en gral', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (106, 'TKT-ML5ERPCC-DL5S', 'LIMPIEZA', 'FAVOR DE SACAR LA TIERRA Y POLVO Y DEMAS DESDE EL VIERNES DESPUES DEL TEMPORAL, EL TECLADO, IMPOSIBLE DE USAR.', 'closed', 'low', 'Mantenimiento', 'ANDREA BELEN DURAN', 'gestionart@idiagnostica.com.ar', 10, '2026-02-02 13:52:57.229327', '2026-02-02 14:01:11.102627', '[]', 'CALL CENTER', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (107, 'TKT-ML5HTDU2-V375', 'Solicitud de reenvio de estudio CONE BEAM', 'Reenvio de estudios', 'closed', 'medium', 'Sistemas', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-02-02 15:18:14.475005', '2026-02-03 07:44:49.023697', '["/uploads/tickets/ticket-1770056294427-43592648.jpeg"]', 'MKT, Gestión de grillas, Call Center', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (109, 'TKT-ML6HEEX8-3GLB', 'No entran pacientes', 'No estan entrando los pacientes al equipo', 'closed', 'medium', 'Sistemas', 'Sede Ciudad', 'mail@ejemplo.com', 3, '2026-02-03 07:54:22.221566', '2026-02-03 09:00:11.686442', '[]', 'Resonancia', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (108, 'TKT-ML6FZEIF-6XKJ', 'HOJAS MEMBRETADAS -IMPRESORA', '-NECESITO HOJAS MEMBRETADAS PARA TRANSCRIPCIÓN
-HOJAS PARA IMPRESORA DEL 1ER PISO', 'closed', 'medium', 'Compras e Insumos', 'Monica', 'veram@idiagnostica.com.ar', 11, '2026-02-03 07:14:42.274695', '2026-02-03 10:37:58.449041', '[]', 'TRANSCIPCIÓN', NULL);
INSERT INTO public.tickets VALUES (146, 'TKT-ML6OQ0EW-RQ6I', 'cloacas', 'limpiar la cámara de cloacas', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-03 11:19:20.601202', '2026-02-03 11:38:36.168625', '[]', 'mantenimiento', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (636, 'TKT-MTLJ7A1S-3TMG', 'alarma en tablero de sepi', 'bajo flujo de agua.', 'closed', 'medium', 'Mantenimiento', 'emmanuel muñoz', 'emmanuelmym25@gmail.com', 10, '2026-09-03 09:58:59.883743', '2026-09-03 14:49:28.784524', '[]', 'resonancia magnetica nuclear', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (111, 'TKT-ML6JRBTU-MH88', 'Área calurosa', 'A primera hora hacia mucho calor en el área. 26°. Aires apagados que no encendían.', 'closed', 'medium', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-02-03 09:00:23.971222', '2026-02-03 09:33:04.72293', '[]', 'alto campo', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (172, 'TKT-MLF44WLK-QYUC', 'Bot', 'No puedo ingresar al bot', 'closed', 'medium', 'Sistemas', 'Claudia Lujan', 'lujanc@idiagnostica.com.ar', 3, '2026-02-09 08:52:59.146926', '2026-02-09 08:54:38.251187', '[]', 'Recepción', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (112, 'TKT-ML6N9VDE-B42U', 'arreglar o cambiar control remoto de persiana metalica', 'arreglar o cambiar control remoto de persiana metalica', 'closed', 'medium', 'Mantenimiento', 'Danilo Barresi', 'barresid@idiagnostica.com.ar', 10, '2026-02-03 10:38:47.956359', '2026-02-03 10:56:34.312096', '[]', 'recepcion', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (178, 'TKT-MLFD62NR-34B5', 'No cierra el locker de uno de los cambiadores.', 'Se rompio la cerradura de uno de los locker', 'closed', 'medium', 'Mantenimiento', 'Alejandro Monterop', 'alejdromonterof@gmail.com', 10, '2026-02-09 13:05:50.201313', '2026-02-09 13:31:45.67375', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (151, 'TKT-ML80EISG-ZEE4', 'Error 404', 'Hay paginas que no puedo consultar. 
https://www.cpcemza.org.ar/prestadores/index.php
https://mendoza.id-estudios.com.ar/vmportalmedico/login.php

Es un tema de las páginas o de bloqueo interno', 'closed', 'medium', 'Sistemas', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-02-04 09:34:06.112906', '2026-02-04 09:49:56.741164', '[]', 'MKT, Gestión de grillas, Call Center', NULL);
INSERT INTO public.tickets VALUES (215, 'TKT-MLL8LTUB-AF46', 'tablero', 'colocarle etiquetas a el tablero nuevo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-13 15:44:44.244017', '2026-02-26 11:31:38.490773', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (153, 'TKT-ML82TAT7-2R4Y', 'Equipo no conectado', 'El equipo no carga pacientes ni imagenes', 'closed', 'medium', 'Sistemas', 'Sede Maipu', 'mail@mail.com', 3, '2026-02-04 10:41:34.866733', '2026-02-04 10:42:15.263359', '[]', 'Consultorio 1', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (152, 'TKT-ML82OU0P-C989', 'Google Drive', 'No conecta la cuenta en la aplicación de google drive', 'closed', 'medium', 'Sistemas', 'Sede Ciudad', 'mail@mail.com', 3, '2026-02-04 10:38:06.457995', '2026-02-04 11:14:08.122225', '[]', 'Odontología', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (154, 'TKT-ML88U0YA-TN9I', 'Intercambio', 'Debido a la necesidad de un software de cardiologia, es necesario intercambiar las PC de eco 1 y 3, tambien colocar UPS y hacer limpieza de ambas', 'closed', 'medium', 'Sistemas', 'Sede San Martin', 'mail@mail.com', 3, '2026-02-04 13:30:06.420317', '2026-02-04 13:31:51.434444', '[]', 'Eco 1 y 3', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (155, 'TKT-ML88YVRH-O7YL', 'carpeta publica', 'no tengo acceso al publico', 'closed', 'medium', 'Sistemas', 'Daniela', 'mail@mail.com', 3, '2026-02-04 13:33:52.974241', '2026-02-04 13:34:22.507636', '[]', 'Informes San Martin', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (184, 'TKT-MLGPZEVZ-UXHE', 'aire', 'limpieza de turbia y filtros del aire acondicionado', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-10 11:52:20.64051', '2026-02-10 12:03:38.271378', '[]', 'tomo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (156, 'TKT-ML8900KB-7H5Z', 'DESPACHAR CAJAS', 'HOLA FRANCO, NECESITO BAJAR A PLANTA BAJA LAS CAJAS QUE DEJO EL INGENIERO QUE VAN A RETIRAR DE OCASA.
GRACIAS.', 'closed', 'medium', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-02-04 13:34:45.853', '2026-02-04 14:41:35.07812', '[]', 'RMN 4to piso', NULL);
INSERT INTO public.tickets VALUES (150, 'TKT-ML7XDVD6-C193', 'Fallo de red.', 'El equipo no se conecta con la red y no envía los estudios.', 'closed', 'medium', 'Sistemas', 'David Gutiérrez', 'davidguti1405@yahoo.com', 3, '2026-02-04 08:09:36.923646', '2026-02-05 08:25:19.627362', '[]', 'RESONADOR BAJO CAMPO', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (149, 'TKT-ML7WZKST-JL8J', 'NO CARGA WORKLIST Y NO PASAN LAS IMAGENS A AL WEB', 'NO ESTAN PASANDO LAS IMAGENES AL PACS Y NO SE ESTAN CARGANDO LAS IMAGENES EN EL WORKLIST ESTO SUCEDE DESDE AYER.', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-02-04 07:58:30.039162', '2026-02-05 08:26:01.492729', '[]', 'RESONANCIA Y TOMOGRAFIA', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (187, 'TKT-MLHYS35B-VYR9', 'No anda el sistema HUB', 'Ni me deja ingresar', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-02-11 08:46:21.553528', '2026-02-11 08:47:31.481308', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (186, 'TKT-MLHY6TME-77WS', 'visualizador MZA', 'ERROR 500 - No cierra estudios', 'closed', 'high', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-11 08:29:49.440345', '2026-02-11 08:47:40.028041', '[]', 'informes', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (190, 'TKT-MLI3VH3B-O9LQ', 'URGENTE - GRILLA PERDIDA', 'no aparecen en el sistema los estudios realizados el miercoles pasados por el Dr Ahumada.  Adjunto imagen del consultorio', 'closed', 'high', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-11 11:08:57.674697', '2026-02-11 13:55:52.38282', '["/uploads/tickets/ticket-1770818937662-923639546.png"]', 'informes', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (193, 'TKT-MLIAG8GU-Y3HL', 'problema de luces', 'luces del bajo campo están parpadeando y cambiando de color', 'closed', 'medium', 'Mantenimiento', 'cecilia belen alfaro', 'chechualf@gmail.com', 10, '2026-02-11 14:13:03.967606', '2026-02-11 15:34:25.139563', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (192, 'TKT-MLI7DQNC-WM71', 'RX PANORAMICA', 'la odontologa belen doyle, mereclama reiteradas veces una rx panoramica, que no puede visualizarla en el visual para ser informada. se vuelve a enviar desde nuestro puesto, pero sigue sin impactar en sistema.
paciente del dia 05/02  PEREZ IVAN DNI 40890006', 'closed', 'medium', 'Sistemas', 'ANDREA DURAN', 'belu29326@gmail.com', 3, '2026-02-11 12:47:08.715381', '2026-02-11 15:44:25.96829', '[]', 'oficina de odontologia', 'Ciudad');
INSERT INTO public.tickets VALUES (196, 'TKT-MLJC4UQG-S71K', 'cambio de tonner', 'solicito cambio de tonner', 'closed', 'medium', 'Sistemas', 'lujan claudia', 'lujanc@idiagnostica.com.ar', 3, '2026-02-12 07:47:58.373888', '2026-02-12 07:56:39.142318', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (199, 'TKT-MLJDNFZJ-DFNC', 'REVISAR MAIL y CAMBIAR IDIOMA DE OFFICE', 'Aparentemente, los mensajes enviados a otros dominios no se estan enviando. Solo nos damos cuanta ya que las art vuelve a pedir lo mismo. 

Y el office se encuentra en ingles si lo podemos cambiar a español.

adjunto anydesk.

Saludos', 'closed', 'medium', 'Sistemas', 'Orellano Lautaro', 'jluduena@idiagnostica.com.ar', 3, '2026-02-12 08:30:25.328919', '2026-02-12 10:06:10.57075', '["/uploads/tickets/ticket-1770895825135-527258513.jpg"]', 'Call', 'San Martín');
INSERT INTO public.tickets VALUES (202, 'TKT-MLJKVHA6-4J19', 'Automatización', 'Se corrigió un error en el sistema automatizado de alojamiento de links en planilla Google Sheets por el cual no se ejecutaba la automatización al 100%

El error se encontró en la configuración del paso 7 de la automatización y ya fue corregido. Ticket de seguimiento', 'closed', 'medium', 'Sistemas', 'Rodolfo', 'mail@mail.com', 3, '2026-02-12 11:52:37.57827', '2026-02-12 11:52:42.939164', '[]', 'Odontología e Informes', 'Ciudad');
INSERT INTO public.tickets VALUES (181, 'TKT-MLFISGK9-WWIP', 'plafón y cortina roller.', 'buenas tardes! para informar el mantenimiento de cortina roller en recepcion y plafón caído en el pasillo del resonandor (colocar foco y plafón).', 'closed', 'low', 'Mantenimiento', 'pablo estrella', 'estrellap@idiagnostica.com.ar', 10, '2026-02-09 15:43:12.735048', '2026-02-12 12:58:55.458336', '["/uploads/tickets/ticket-1770662592487-176055161.jpeg", "/uploads/tickets/ticket-1770662592545-622947120.jpeg"]', 'recepcion y pasillo resonador.', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (145, 'TKT-ML6OHBF0-XVBO', 'pegado de zocalos y reparacion filtraciones maipu, ver luz cartel principal', 'arreglar y pegar los zocalos en gerencia que por las lluvias se han despegado . Por otro lado ver de solucionar las filtraciones que pasan por el porton metalico del fondo. 
Ver luz cartel principal de maipu por la lluvia se corto la mitad', 'closed', 'medium', 'Mantenimiento', 'Danilo Barresdi', 'barresid@idiagnostica.com.ar', 10, '2026-02-03 11:12:34.957823', '2026-02-12 12:59:18.02621', '[]', 'gerencia Maipu', NULL);
INSERT INTO public.tickets VALUES (170, 'TKT-MLB73U9I-ILIU', 'cpu no tiene tapa', 'cpu sin tapa lateral', 'closed', 'medium', 'Sistemas', 'GIMENA', 'gimenadolmanrique@gmail.com', 3, '2026-02-06 15:05:03.608059', '2026-02-13 08:34:33.317588', '[]', 'brivo', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (637, 'TKT-MTLTKNBC-ZVDC', 'cloaca', 'colocar un caño para que respire la cloaca', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-03 14:49:19.753663', '2026-09-03 14:49:38.163933', '[]', 'mantenimiento', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (166, 'TKT-MLAUJ2XN-XNFL', 'CORTINA / AGUA/ PAVA ELECTRICA', 'ARREGLAR LA CORTINA DE LA VENTANA/ PAVA ELECTRICA FALLA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-02-06 09:12:59.677501', '2026-02-06 12:18:29.168722', '[]', 'CALL CENTER', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (275, 'TKT-MM99TQYR-R02A', 'limpieza tamblero', 'sopletear el tablero principal del para mantenimiento preventivo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-02 11:25:21.605945', '2026-03-02 12:03:01.804289', '[]', 'tablero principal', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (161, 'TKT-ML9C40EB-15NE', 'VISUALIZADOR MZA', 'La web se cae cuando intenta guardar un informe: error 500', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-05 07:49:37.298325', '2026-02-05 08:27:42.449552', '[]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (162, 'TKT-ML9CS6YT-QPE5', 'VER PAQUETE OFFICE', 'El paquete office principalmente word, se encuentra en ingles se necesita si lo puden poden en español, dificulta el tipeo. Saludos. 
Interno 508', 'closed', 'medium', 'Sistemas', 'Rodriguez Daniela', 'jluduena@idiagnostica.com.ar', 3, '2026-02-05 08:08:25.543981', '2026-02-09 08:57:42.747323', '[]', 'informes', NULL);
INSERT INTO public.tickets VALUES (218, 'TKT-MLMHY49Z-T7LX', 'NOS DA NUEVAMENTE ERROR 500', 'NOS DA NUEVAMENTE ERROR 500.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-02-14 12:54:00.361375', '2026-02-19 08:21:06.423159', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (163, 'TKT-ML9R664T-ZRNE', 'Aire acondicionado', 'se siente mucho frio en rayos y vestidores de reso del bajo', 'closed', 'medium', 'Mantenimiento', 'Vanesa Medina', 'rodriguezf@idiagnostica.com.ar', 10, '2026-02-05 14:51:12.274604', '2026-02-05 15:33:31.490175', '[]', 'planta baja', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (160, 'TKT-ML9BO9WN-T8IJ', 'NECESITAMOS CAFE Y AZUCAR', 'CAFÉ Y AZUCAR', 'closed', 'medium', 'Compras e Insumos', 'Monica', 'veram@idiagnostica.com.ar', 11, '2026-02-05 07:37:23.14047', '2026-02-05 20:17:09.327837', '[]', 'TRANSCIPCIÓN', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (200, 'TKT-MLJGZOE3-8VS4', 'Portal Médico', 'En el año 2021 desarrollamos el portal para médicos. Necesitamos conocer el estamo del mismo para mejorarlo y ponerlo en funcionamiento. 
https://mendoz2615174289a.id-estudios.com.ar/vmportalmedico/application/views/index.php
Usuario: Administrativo
Clave: Admin', 'closed', 'medium', 'Sistemas', 'Lorena Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-02-12 10:03:54.942521', '2026-05-05 08:55:25.776467', '["/uploads/tickets/ticket-1770901432414-795790681.jpg", "/uploads/tickets/ticket-1770901433940-862770353.jpg"]', 'MKT, Gestión de grillas, Call Center', 'Ciudad');
INSERT INTO public.tickets VALUES (110, 'TKT-ML6HWV69-3K46', 'VISUALIZADOR MZA', 'Buen día, persiste el problema en el visualizador MZA (no guarda informe) se arregla, funciona un tiempo y se vuelve a caer la web', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-02-03 08:08:43.090489', '2026-02-06 09:06:53.350515', '["/uploads/tickets/ticket-1770116923086-408333928.png"]', 'informes', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (203, 'TKT-MLJMVVNU-VIM3', 'Mantenimiento y limpieza de aires en sala de maquina y sala de trabajo', 'polvo en sala de maquina y aires', 'closed', 'low', 'Mantenimiento', 'emmanuel muñoz', 'emmanuelmym25@gmail.com', 10, '2026-02-12 12:48:55.459808', '2026-02-26 12:13:54.068582', '[]', 'tomografía y resonancia', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (165, 'TKT-ML9VT93W-49HQ', 'Cambio de silla', 'Silla del operador Facundo Benito se encuentra rota', 'closed', 'low', 'Mantenimiento', 'Martin Klimisch', 'klimischa@idiagnostica.com.ar', 10, '2026-02-05 17:01:07.678897', '2026-02-09 13:55:41.317204', '[]', 'Call Center', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (168, 'TKT-MLAZ2FQK-7MGB', 'luz de emergencia', 'se encontró luz de emergencia encendida', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-06 11:20:01.19738', '2026-02-06 11:20:42.53371', '[]', 'eco 5', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (177, 'TKT-MLF9EPSV-6239', 'Error en ID', 'Se muestran ID erróneos en CR

Solo del día 03/02 y uno del 04/02', 'closed', 'medium', 'Sistemas', 'Rodolfo VIgon', 'mail@mail.com', 3, '2026-02-09 11:20:34.98732', '2026-02-10 08:07:40.650924', '["/uploads/tickets/ticket-1770646834969-147737278.png"]', 'Informes', 'Ciudad');
INSERT INTO public.tickets VALUES (179, 'TKT-MLFF45RV-3CCO', 'CONECCION A LA RED DE WORKSTATION', 'Hola Rodolfo, Matías la semana pasada desconecto la red de la workstation del 4to piso y no la volvió a conectar, x esto las imágenes del resonador no pasan a la AW3 .', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-02-09 14:00:20.157012', '2026-02-10 11:02:02.415372', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (182, 'TKT-MLGJJCZC-BXOW', 'PEDIDO BIDON AGUA', 'BIDON DE AGUA PARA DISPENSER', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-02-10 08:51:53.989874', '2026-02-10 11:11:53.804673', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (185, 'TKT-MLGUV18S-ADWX', 'se salio un soporte de escalera que usan pacientes para subir a camilla', 'se salio un soporte de escalera que usan pacientes para subir a camilla', 'closed', 'low', 'Mantenimiento', 'gimena', 'gimenasolmanrique@gmail.com', 10, '2026-02-10 14:08:54.414339', '2026-02-10 15:01:47.728251', '[]', 'bajo campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (188, 'TKT-MLHZJZXL-DTUI', 'Contraseña', 'No puedo entrar, no sabemos la contraseña.', 'closed', 'medium', 'Sistemas', 'Sede Maipu', 'mail@mail.com', 3, '2026-02-11 09:08:03.754016', '2026-02-11 09:08:08.161341', '[]', 'Recepción', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (191, 'TKT-MLI66VO4-5ZE9', 'protector de pared para camillas', 'arreglar protector de pared para camillas del cuarto piso que se  despego', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-11 12:13:49.012995', '2026-02-11 15:34:39.839383', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (194, 'TKT-MLIALO7K-27S0', 'no funciona usuario en workstation', 'no puedo ingresar a workstation', 'closed', 'medium', 'Sistemas', 'cecilia belen alfaro', 'chechualf@gmail.com', 3, '2026-02-11 14:17:17.649896', '2026-02-11 15:43:14.171721', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (167, 'TKT-MLAUJC00-REN1', 'Stock de fuentes', 'Solicito abastecimiento de fuentes, ya que estamos bajo de stock.

Recomiendo compra 👉 https://www.mercadolibre.com.ar/fuente-de-alimentacion-550w-atx-ventilador-80mm-lnz-px550-fs-3-sata-2-molex/p/MLA43925609?pdp_filters=item_id%3AMLA1540775273#origin=share&sid=share&wid=MLA1540775273

Mejor precio, buena calidad, posibilidad de cuotificación.

Solicito 4 unidades.', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 11, '2026-02-06 09:13:11.425381', '2026-02-12 10:46:46.888613', '[]', 'Sistema', NULL);
INSERT INTO public.tickets VALUES (159, 'TKT-ML8960OR-AM7T', 'Publico', 'El publico tiene muy poco almacenamiento', 'closed', 'medium', 'Sistemas', 'Sede San Martin', 'mail@mail.com', 3, '2026-02-04 13:39:25.950782', '2026-02-13 08:35:59.528105', '["/uploads/tickets/ticket-1770223165831-659090640.jpeg"]', 'sede', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (208, 'TKT-MLKRSL2E-T2G1', 'AIRES', 'Buen día Franco y Cristian, esta mañana encontré los dos aires del cuarto de maquinas del resonador alto campo apagados con sus respectivas térmicas bajadas. Luego de subirlas encendieron correctamente, hay que resolver este inconveniente, la temperatura en el sector de gabinetes estaba en 32 grados. gracias.', 'closed', 'medium', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-02-13 07:54:06.427873', '2026-02-13 09:03:44.308037', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (210, 'TKT-MLKUHNBR-AU4O', 'no se puede generar el QR', 'se sale siempre del sistema y no podemos gererar QR y tambien cuando tenemos mucha gente no pueden sacar núnero para su atención', 'closed', 'medium', 'Sistemas', 'lujan claudia', 'lujanc@idiagnostica.com.ar', 3, '2026-02-13 09:09:34.5567', '2026-02-13 10:41:19.726973', '[]', 'tokem planta baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (197, 'TKT-MLJCFBV6-493V', 'No se pueden comenzar ni cerrar los estudios', 'Los estudios quedan en automático y no se pueden cerrar', 'closed', 'medium', 'Sistemas', 'jorgelina', 'ninajaraya@gmail.com', 3, '2026-02-12 07:56:07.125593', '2026-02-13 12:17:43.799283', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (226, 'TKT-MLTJX5Y9-LSBR', 'Sin Acceso', 'Sin acceso a la carpeta Sanchez Menegon en disco público', 'closed', 'medium', 'Sistemas', 'Lorena Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-02-19 11:23:38.338849', '2026-02-20 10:21:56.98787', '["/uploads/tickets/ticket-1771511018323-164865355.jpg"]', 'MKT, Gestión de grillas, Call Center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (638, 'TKT-MTLTM2UA-BJZH', 'cable', 'cambiar un cable vga por uno de hdmi en eco 3 por ruido en el ecografo', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-03 14:50:26.531232', '2026-09-03 14:51:03.80874', '[]', 'eco 3', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (272, 'TKT-MM96QDFM-JINN', 'Puerta área sistema', 'Chilla como la chilindrina, un wd40 y vamos andando, gracias!', 'closed', 'low', 'Mantenimiento', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 10, '2026-03-02 09:58:45.25405', '2026-03-02 10:38:40.933919', '[]', 'Sistemas', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (279, 'TKT-MM9I9CG5-HDFF', 'aire acondicionado', 'no podemos colocar el aire central esta duro la manija para poder abrirlo', 'closed', 'low', 'Mantenimiento', 'lorena cataldo', 'claudiacataldo01@gmail.com', 10, '2026-03-02 15:21:26.214814', '2026-03-02 15:36:07.07163', '[]', 'transcripción', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (281, 'TKT-MMARNAP6-Q44E', 'caño colgando', 'se encontro un caño colgando que estaba peligroso que estaba sostenido por 2 cable de red, se averiguo sis e podia cortar el cable y se descubrio que el cable es antiguo y estaba fuera de servicio y se procedió q cortarlo. tambien se encontraron cables en el primer piso cortados y tambien se sacaron', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-03 12:31:59.850977', '2026-03-03 14:51:15.081611', '[]', 'terraza', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (284, 'TKT-MMB2YME7-DQA6', 'falla en sistema', 'En la consola de rayos no se pueden ver nuevos pacientes y tampoco cargar imagenes de los estudios realizados.', 'closed', 'medium', 'Sistemas', 'ledesma estefania', 'ledesmae@idiagnostica.com.ar', 3, '2026-03-03 17:48:44.002001', '2026-03-04 08:54:04.775943', '[]', 'servicio de rayos', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (285, 'TKT-MMC0XSXD-FJDN', 'mail', 'el horario de llegada de los mails no coincide con el horario real que figura en el mail', 'closed', 'medium', 'Sistemas', 'Vanesa Contreras', 'gestionart@idiagnostica.com.ar', 3, '2026-03-04 09:39:52.761191', '2026-03-05 08:26:32.121211', '[]', 'art', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (291, 'TKT-MMDOQ58C-LJQ3', 'lona', 'se desprendio un poco la lona por el viento. se volvio a colocar precintos y dejarla en orden. tambien se cortaron plantas secas que estaban en la tela', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-05 13:33:32.414998', '2026-03-05 14:48:51.550102', '[]', 'lona', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (294, 'TKT-MMEX24PC-TXMT', 'PEDIDO AGUA', 'PEDIDO BIDON DE AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-03-06 10:14:34.70754', '2026-03-06 13:01:21.852148', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (287, 'TKT-MMC75PKG-1TV4', 'filtracion de agua', 'buscar y arreglar la filtracion de agua que afecta al techo del tercer piso en el consultorio 17 .
se coloco membrana y una chapa para tapar bien un espacio que puede ser en donde entra agua. tambien se coloco membrana liquida en la terraza a la salida del call center.
tambien se coloco espuma para sellar algunos lugares. no queda unos retoques y colocar membrana por dentro de la sala de maquinas.', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-04 12:33:59.354058', '2026-03-06 13:02:41.430215', '["/uploads/tickets/ticket-1772638437708-459046047.jpeg", "/uploads/tickets/ticket-1772638437873-417228022.jpeg", "/uploads/tickets/ticket-1772638439089-618258060.jpeg"]', 'terraza', 'Ciudad');
INSERT INTO public.tickets VALUES (300, 'TKT-MMGE5USH-I01T', 'NO FUNCIONA LA IMPRESORA DE LA OFICINA.', 'NO FUNCIONA LA IMPRESORA DE LA OFICINA.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-03-07 11:01:08.140332', '2026-03-09 08:19:40.520611', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (299, 'TKT-MMGCEMLR-R02J', 'impresora rota', 'hace tres dias les hice el reclamo que no funciona la impresiora marca un error y nadie vino a verla', 'closed', 'medium', 'Sistemas', 'claudia cataldo', 'claudiacataldo01@gmail.com', 3, '2026-03-07 10:11:58.203308', '2026-03-09 08:19:55.923115', '[]', 'transcripción', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (297, 'TKT-MMF6OZ6Z-WH9N', 'Vuelvo a reclamar sobre la impresora de transcripción', 'MARCA UN ERROR Y NO IMPRIME', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-03-06 14:44:17.205458', '2026-03-09 08:20:32.104904', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (292, 'TKT-MMDP9JM7-O82B', 'no funciona la impresora', 'no funciona la impresiona la, impresora marca error de fusor', 'closed', 'medium', 'Sistemas', 'claudia cataldo', 'claudiacataldo01@gmail.com', 3, '2026-03-05 13:48:37.521618', '2026-03-09 08:20:39.458674', '[]', 'transcripción', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (268, 'TKT-MM683HFW-0E81', 'Compra de teclado', 'Solicito la compra de teclado para notebook HP Compaq 

http://mercadolibre.com.ar/teclado-para-notebook-hp-compaq-21n0f3ar-21n001ar-21n122ar/up/MLAU279479211?pdp_filters=item_id%3AMLA785377230&matt_tool=89488245#origin=whatsapp&sid=whatsapp&wid=MLA785377230', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo', 'vigonr@idiagnostica.com.ar', 11, '2026-02-28 08:13:38.070601', '2026-03-09 09:40:22.721872', '[]', 'Sistema', 'Ciudad');
INSERT INTO public.tickets VALUES (87, 'TKT-MKZEXCT9-NEQT', 'Compra nueva PC', 'Solicito la aprobación para compra de PC nueva para Dr. Tercero en plan de actualización y renovación de computadoras del establecimiento

El objetivo es cubrir 2x1, es decir, con la compra nueva enfocada en el consultorio de Tercero, la computadora vieja será reemplazo a PC de informes ( pc obsoleta ) de esta manera, se optimiza la compra y gestión de recursos.

Saludos!

Link del pedido 👉 https://compragamer.com/carro-compras?paso=11&tipo=49&cpu=13369&mother=18990&ccpu=2093&mem=7523&video=10259&gab=18260&pasoCarrito=revision&listado_prod=1-13369,1-18990,1-2093,1-7523,1-10259,1-18260,1-4671&sort=lower_price', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 11, '2026-01-29 09:10:43.871904', '2026-03-09 09:41:10.19795', '["/uploads/tickets/ticket-1769688643839-192641847.jpeg"]', 'Consultorios', NULL);
INSERT INTO public.tickets VALUES (302, 'TKT-MMJ52ICB-JJ1T', 'lluvia', 'entro agua por la ventana.', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-09 09:09:54.011836', '2026-03-09 09:57:39.339771', '[]', 'tuerquita', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (301, 'TKT-MMJ3EFD6-F4N7', 'tapa de gabinete', 'Hola franco , podes colocarle la tapa al gabinete del cuarto de maquinas del alto campo, solo eso gracias..', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-03-09 08:23:10.796758', '2026-03-09 09:57:49.69656', '[]', '4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (298, 'TKT-MMGCCFOC-V41H', 'Revisar impresora', 'Buen dia, por favor cuando puedas revisen mi impresora ya que me esta costando imprimir.


Saludos.', 'closed', 'medium', 'Sistemas', 'Guadalupe Sanchez', 'sanchezg@idiagnostica.com.ar', 3, '2026-03-07 10:10:15.90993', '2026-03-09 12:28:42.468517', '[]', 'RRHH', 'Ciudad');
INSERT INTO public.tickets VALUES (273, 'TKT-MM96R45I-LF36', 'Aires de Mamo y Facturacion', 'Mamo: ha empezado a tirar agua
Facturacion: esta largando mal olor', 'closed', 'low', 'Mantenimiento', 'Enrique', 'orellanoe@idiagnostica.com.ar', 10, '2026-03-02 09:59:19.879812', '2026-03-14 10:01:54.357749', '[]', 'Faturacion/Mamo', 'San Martín');
INSERT INTO public.tickets VALUES (296, 'TKT-MMF54DSX-W77M', 'almohadas', 'llevar a tapizar almohadas de resonancia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-06 14:00:16.740898', '2026-05-08 14:21:58.527754', '[]', 'reso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (227, 'TKT-MLTLP2II-YO9D', 'NECESITAMOS BIDON DE AGUA', 'AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-02-19 12:13:19.868792', '2026-02-19 13:38:55.301188', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (229, 'TKT-MLTS08YW-RIBW', 'IMPRESORA', 'NO FUNCIONA LA IMPRESORA, EN LA PARTE DE LOS RODILLOS DONDE SALE MAL IMPRESO Y HACE RUIDO.', 'closed', 'medium', 'Mantenimiento', 'SHIRLEY PEPA', 'pepas@idiagnostica.com.ar', 10, '2026-02-19 15:09:59.14684', '2026-02-19 15:19:37.394805', '[]', 'facturación', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (274, 'TKT-MM98MLYC-4XYJ', 'cerradura de lockerts', 'reparación de lockerts, paciente rompió la cerradura.', 'closed', 'medium', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-03-02 10:51:48.901816', '2026-03-02 12:03:18.667467', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (230, 'TKT-MLUU5QHK-TZCP', 'limite de peso de los pacintentes de reso y tac', 'solicito quede como dato obligatorio al mometo de dar los turnos de reso y tac registrar kg y talla  del paciente ya que en tomografia el limite es 115kg y en reso 120kg, nos pasa que no se lo preguntan al paciente al momenro de dar el turno y cuando llegas a hacer el estudio lo pesamos y si pasa el limite el estudio no s epuede realizar , por ende perdemos un turno y el paciente siempre se va enojado con la queja de que no se lo consultaron al momento de pedir el turno.', 'closed', 'medium', 'Sistemas', 'MARIANA ZAGO', 'zagom@idiagnostica.com.ar', 3, '2026-02-20 08:58:00.538142', '2026-02-20 09:07:40.256745', '[]', 'turnos para resonador y tomografia', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (276, 'TKT-MM9EAW6M-S2GI', 'agua', 'llevar un agua a mamografia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-02 13:30:39.983457', '2026-03-02 13:34:34.101685', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (238, 'TKT-MLV64WC4-L92R', '2 luces funcionan intermitentes dentro de resonancia', '2 luces funcionan intermitentes dentro de resonancia', 'closed', 'low', 'Mantenimiento', 'sebastian', 'seba.hys@hotmail.com', 10, '2026-02-20 14:33:16.854844', '2026-03-05 13:29:43.674686', '[]', 'tomografía y resonancia', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (233, 'TKT-MLV0GQYX-STPV', 'cartel de matafuego', 'cambiar el cartel donde se apoya el matafuego por que esta viejo amarillo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-20 11:54:32.075294', '2026-02-20 11:56:22.173737', '["/uploads/tickets/ticket-1771599271992-104690310.jpeg"]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (234, 'TKT-MLV0HSMC-7KWH', 'tomas', 'cambiar tomas y teclas por q estan amarillas', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-20 11:55:20.869347', '2026-02-20 11:56:39.901955', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (228, 'TKT-MLTQ237N-4HU4', 'no se borra el de los pacientes ya realizados', 'en el listado del resonador sigue apareciendo el nombre de los pacientes ya realizados y en ocaciones se duplica.', 'closed', 'medium', 'Sistemas', 'cecilia alfaro', 'chechualf@gmail.com', 3, '2026-02-19 14:15:25.767997', '2026-03-11 14:15:47.280126', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (247, 'TKT-MM0KCBGW-DXIQ', 'Sistema RIS Ciudad', 'Buen día, por favor necesitamos que se agregue como dato obligatorio el peso del paciente para RMN, TAC y Densitometría.', 'closed', 'medium', 'Sistemas', 'Martín Adrián Klimisch', 'klimischa@idiagnostica.com.ar', 3, '2026-02-24 09:09:48.56243', '2026-04-07 08:21:50.42977', '[]', 'Call Center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (249, 'TKT-MM0LMEED-8QT4', 'Arreglo de silla', 'Equipo buen día, por favor retirar silla de oficina de recursos humanos para tapizar', 'closed', 'low', 'Mantenimiento', 'Guada', 'sanchezg@idiagnostica.com.ar', 10, '2026-02-24 09:45:38.535929', '2026-04-30 11:51:05.990675', '[]', 'RRHH', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (236, 'TKT-MLV0LKNL-CM8B', 'aire acoindicionado', 'el aire acondicionado de tercer piso en odontología pierde agua', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-20 11:58:17.170677', '2026-02-20 12:11:58.549453', '[]', '3 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (235, 'TKT-MLV0KL12-TDZO', 'aire', 'el aire acondicionado pierde agua', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-20 11:57:31.001244', '2026-02-20 13:05:39.415027', '[]', 'bajo campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (189, 'TKT-MLI0APME-LV6O', 'CONFIGURACION DE IMPRESORAS', 'NECESITO URGENTE QUE LAS IMAGENES DEL TOMOGRAFO  DEL RESONADOR DE ARTICULACIONES Y EL RESONADOR ALTO CAMPO  PUEDAS SER IMPRESAS EN LA MAQUINA MINOLTA ANTES DEL VIERNES NO PODEMOS CONTINUAR DE ESA MANERA', 'closed', 'high', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-02-11 09:28:50.105432', '2026-02-20 14:37:04.98755', '[]', 'RESONANCIAS Y TOMOGRAFIA', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (239, 'TKT-MLVH9JGM-OWZI', 'se rompió una  cerradura del Locke el segundo cambiador', 'rotura de cerradura del locker en el segundo cambiador', 'closed', 'medium', 'Mantenimiento', 'gimena manrique', 'gimenasolmanrique@gmail.com', 10, '2026-02-20 19:44:49.232407', '2026-02-21 09:36:38.830783', '[]', 'RMN 4to piso alto campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (240, 'TKT-MLWAO5IZ-IXKP', 'No hay sistema', 'No puedo ver ni actualizar la lista de turnos.', 'closed', 'medium', 'Sistemas', 'Alejandro Montero', 'alejdromonterof@gmail.com', 3, '2026-02-21 09:27:59.86935', '2026-02-23 07:57:55.58051', '[]', 'Sistema de turnos', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (232, 'TKT-MLV0D1F8-KYV6', 'zocalos', 'limpiar los zócalos que tienen pintura', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-20 11:51:38.997025', '2026-02-23 08:33:46.48927', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (242, 'TKT-MLZ41Q45-X98C', 'tablero lluvia', 'entra agua cerca del tablero', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-23 08:45:54.294346', '2026-02-23 10:43:37.204697', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (241, 'TKT-MLZ4122E-WITS', 'lluvia', 'entra agua en la sala de maquina del bajo campo', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-23 08:45:23.127566', '2026-02-23 10:44:37.119003', '[]', 'bajo campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (244, 'TKT-MLZ4Q8WA-5HJT', 'internos no operativos', 'No salen las llamadas pero si ingresan.', 'closed', 'medium', 'Sistemas', 'florencia benavides', 'benavidesf@idiagnostica.com.ar', 3, '2026-02-23 09:04:58.380033', '2026-02-23 10:57:37.630083', '[]', 'recepcion 1P', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (237, 'TKT-MLV2Q9S8-7C01', 'pdf editable', 'Necesito que la computadora tenga la función de los pdf editable, ya que entro al sistema YAM y necesito modificar y completar los formularios de la empresa y no puedo descargar el PDF y editarlos.', 'closed', 'medium', 'Sistemas', 'Romina Barani', 'rominabarani28@gmail.com', 3, '2026-02-20 12:57:55.595621', '2026-02-23 11:23:42.340199', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (245, 'TKT-MLZ60XR7-7R38', 'CAMARAS.', 'Buen Dia Matías y Rodolfo, en el resonador de articulaciones se instalo computadora nueva, gracias x eso¡¡ Les pido si pueden instalar las cámaras a la pc. Gracias.', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-02-23 09:41:16.773773', '2026-02-23 12:57:20.770904', '[]', 'RESONADOR DE ARTICULACIONES', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (248, 'TKT-MM0KGD3F-9LNJ', 'Sistema RIS Maipú', 'Buen día, por favor necesitamos que se agregue como dato obligatorio el peso del paciente para RMN, TAC y Densitometría.', 'closed', 'medium', 'Sistemas', 'Martín Adrián Klimisch', 'klimischa@idiagnostica.com.ar', 3, '2026-02-24 09:12:57.292231', '2026-02-24 12:17:38.958828', '[]', 'Call Center', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (246, 'TKT-MLZ8FCIC-56R9', 'gotea en densitometria', 'esta goteando el techo de densitometria', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-23 10:48:28.319455', '2026-02-24 15:12:04.657921', '[]', 'densitometria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (251, 'TKT-MM0YLO3U-K7VX', 'PUBLICO', 'NO ME HAN AGREGADO EL PUBLICO LOCAL NUEVO, Y NO TENGO NINGUNO .. URGENTE', 'closed', 'medium', 'Sistemas', 'SHIRLEY PEPA', 'pepas@idiagnostica.com.ar', 3, '2026-02-24 15:48:59.468426', '2026-02-25 08:52:08.089667', '[]', 'facturación', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (250, 'TKT-MM0RW0DH-CEXB', 'lockers', 'Hola franco, te pido si podes colocar manijas para los lockerts nuevos en total son 6. 
Y buscar lugar para ubicar los lockers viejos.', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-02-24 12:41:04.614122', '2026-02-25 12:45:10.700305', '[]', 'resonancia', 'Ciudad');
INSERT INTO public.tickets VALUES (231, 'TKT-MLV0CEUO-GUJN', 'presupuesto', 'solicitar presupuesto para acrilico en rx', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-20 11:51:09.746902', '2026-02-26 13:42:40.497823', '[]', 'rx', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (252, 'TKT-MM114K7H-R2O7', 'SIN SISTEMA', 'SE INTENTA INGRESAR PACIENTE PERO SE CUELGA EL SISTEMA', 'closed', 'medium', 'Sistemas', 'DAVID VIDELA', 'cromagnoli@idiagnostica.com.ar', 3, '2026-02-24 16:59:40.141022', '2026-02-25 07:53:18.053546', '[]', 'RECEPCION', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (266, 'TKT-MM564NA9-8MGI', 'SILLA', 'AJUSTAR SILLA DE ODONTOLOGIA', 'closed', 'low', 'Mantenimiento', 'VERONICA POBLETE', 'verinew33@gmail.com', 10, '2026-02-27 14:30:46.886186', '2026-02-27 14:39:38.879624', '[]', 'ODONTOLOGIA', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (254, 'TKT-MM263P6Y-SJ4Z', 'negatoscopio', 'negatoscopio fallaba la ficha. se le quito la ficha y se soldó directo en su interior', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-25 12:06:44.170864', '2026-02-25 12:06:57.426549', '[]', 'eco 3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (267, 'TKT-MM566Y24-R7ZM', 'CLAVO SOBRESALE LA MESA', 'ARANDELA QUE SOBRESALE DE LA MESA DE IMPRESIÓN Y PUEDE LASTIMARLOS', 'closed', 'low', 'Mantenimiento', 'VERONICA BRASILI', 'verho2010@gmail.com', 10, '2026-02-27 14:32:34.159916', '2026-02-27 15:11:38.953827', '[]', 'WORK STATION', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (255, 'TKT-MM2654Z4-WBLK', 'dicroica', 'dicroica caida. se volvió a colocar una traba', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-25 12:07:51.281147', '2026-02-25 12:08:08.093199', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (269, 'TKT-MM6B642U-RV2P', 'Resonador detuvo escaneo durante examen', 'Resonador detuvo escaneo durante examen. Estaba el ingeniero en proceso de servicio. Controlamos un par de posibles soluciones pero tuvo que ser reiniciado. Arrancó sin problemas aparentes.', 'closed', 'medium', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-02-28 09:39:39.571306', '2026-03-02 10:55:18.304277', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (271, 'TKT-MM95OS9C-CZGB', 'Instalación de mail', 'Buen dia equipo, necesito que por favor instalen el mail de ART en la computadora de mamografia.


Gracias', 'closed', 'medium', 'Sistemas', 'Guada', 'sanchezg@idiagnostica.com.ar', 3, '2026-03-02 09:29:31.5394', '2026-03-02 11:14:36.164364', '[]', 'mamografia', 'Ciudad');
INSERT INTO public.tickets VALUES (257, 'TKT-MM2BSNMF-C6R3', 'carteleria', 'colocar carteles  en  la puerta de la ups', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-25 14:46:06.617523', '2026-02-25 15:24:30.502344', '[]', 'ups', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (277, 'TKT-MM9EBH2Y-ZPXB', 'bolsas', 'llevar bolsas a mamografia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-02 13:31:07.067623', '2026-03-02 13:31:19.646777', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (264, 'TKT-MM521EZ7-9ESW', 'puerta', 'arreglar el picaporte del la puerta del segundo piso que esta duro.', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-27 12:36:17.685609', '2026-03-02 15:45:54.308648', '[]', '2 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (280, 'TKT-MMAI9IYY-96EX', 'MICROFONO DEFECTUOSO', 'El consultorio donde se realiza cardiología tiene su microfono  defectuoso o mal configurado desde hace mucho tiempo. Si se alejan un poco el Dr del mic en el dictado se rompe el audio.  
Escuchar audio de paciente MONTENEGRO DANIEL (20748741) para tener una idea de como se escucha.', 'closed', 'medium', 'Sistemas', 'GASTON RENALIAS', 'gastonrenalias79@gmail.com', 3, '2026-03-03 08:09:20.855656', '2026-03-03 09:38:22.653553', '[]', 'consultorios', 'Ciudad');
INSERT INTO public.tickets VALUES (256, 'TKT-MM2ATT04-41WM', 'Odontologia.', 'buenos días, la odontóloga no puede ver las imágenes de telerradiografía, por ende no puede realizar los trazados.', 'closed', 'medium', 'Sistemas', 'Noelia Estefania Escobar', 'escobare@idiagnostica.com.ar', 3, '2026-02-25 14:19:00.635204', '2026-02-26 09:44:49.381051', '[]', 'Transcripción de informe', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (640, 'TKT-MTLUMO4N-JUU2', 'baño', 'problema con la tapa del baño', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-03 15:18:53.735997', '2026-09-04 10:19:06.159729', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (643, 'TKT-MTMZCQUS-U20D', 'luces de emergencia', 'control de luces', 'closed', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-04 10:18:54.965982', '2026-09-04 10:57:28.320049', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (258, 'TKT-MM2ENS8W-ISV8', 'enchufe', 'se salio una tapa de un tomacorriente en maipu en el ecografo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-25 16:06:18.187076', '2026-02-26 12:13:42.045382', '[]', 'ecografo maipu', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (283, 'TKT-MMAWLWOG-7HYP', 'cerradura de lockers', 'se coloco una nueva cerradura para lockrs en rx en un solo cambiador para probar que tal se desenpeña. por que las que estan se rompen con facilidad y quedan encerradas las pertenencias del paciente', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-03 14:50:53.107083', '2026-03-03 15:20:44.393872', '[]', 'rx', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (261, 'TKT-MM3MIPU1-GHPR', 'AIRE SPLIT', 'Hola Franco y Cristian, el aire split del cuarto de maquinas del 4to piso sala de maquinas no esta enfriando bien. Lo pueden revisar? Gracias.', 'closed', 'medium', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-02-26 12:34:04.87629', '2026-02-26 13:12:08.739663', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (253, 'TKT-MM1ZX2LD-T35F', 'pintura aire acondicionado', 'pintar el aire acondicionado de la sala de espera del cuarto piso por que esta amarillo viejo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-25 09:13:37.250375', '2026-02-26 13:42:03.455286', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (286, 'TKT-MMC1YKK7-AUY7', 'NO FUNCIONA MOCHILA DE BAÑO DE RAYOS.', 'AL TOCAR BOTON DE MOCHILA NO VACIA EL AGUA. SE ABRE TAPA Y SE ENCUENTRAN LOS PLASTICOS DEL SISTEMA ROTOS.', 'closed', 'low', 'Mantenimiento', 'NATALIA JUAREZ', 'nataliajuarezviajes@gmail.com', 10, '2026-03-04 10:08:28.189884', '2026-03-04 14:30:20.614595', '[]', 'RADIOLOGIA', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (288, 'TKT-MMCAAHK0-4MAE', 'Dispenser de agua', 'CAMBIO DE BIDON SALA RMI PLANTA BAJA', 'closed', 'low', 'Mantenimiento', 'Vargas Aldana Noelia', 'aldanavargas@icloud.com', 10, '2026-03-04 14:01:41.090086', '2026-03-04 15:35:27.720462', '[]', 'Tomografia reso planta baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (263, 'TKT-MM4VKGV1-YYWK', 'BIDON AGUA', 'BIDON AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-02-27 09:35:09.288218', '2026-02-27 11:35:20.280384', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (243, 'TKT-MLZ4AKIM-2P17', 'FILTRACIONES POR LLUVIA', 'Filtraciones de agua por lluvia en la oficina, se inunda desde arriba del mueble y se mojaron cajones, pc, teléfono, entre otros articulos de chequeos (ordenes médicas). Quedo atento al seguimiento del ticket. Gracias.', 'closed', 'low', 'Mantenimiento', 'GERMAN VIGON', 'vigong@idiagnostica.com.ar', 10, '2026-02-23 08:52:46.94469', '2026-02-27 11:37:30.110497', '[]', 'GESTION DE GRILLAS-CHEQUEOS', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (262, 'TKT-MM4T9184-ROXF', 'No se puede ingresar al sistema de Mendoza.', 'No se puede ingresar al sistema de Mendoza.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-02-27 08:30:16.566908', '2026-02-27 11:46:00.901546', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (259, 'TKT-MM3DZRCN-A0DE', 'tiras led', 'pegar tira led del eco 3 que se despego a la altura del aire acondicionado', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-02-26 08:35:23.448306', '2026-02-27 13:03:52.880209', '[]', 'eco 3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (265, 'TKT-MM53RDBD-5E1F', 'aire acondicionado de sala de espera no esta funcionando-.', 'no se puede prender el aire acondicionado de la sala de espera del 4 to piso.,', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-02-27 13:24:28.203543', '2026-02-27 13:55:10.726967', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (289, 'TKT-MMDONKIX-RV5L', 'pegamento en el piso', 'se saco un cable canal y quedo pegamento en el piso.', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-05 13:31:32.267256', '2026-03-05 13:34:06.506991', '[]', 'eco 1', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (290, 'TKT-MMDOOIRQ-7Z3L', 'cartel', 'se apago la mitad del cartel por que se quemo lla fuente. se cambio por una nueva', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-05 13:32:16.647532', '2026-03-05 14:48:56.101915', '[]', 'cartel', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (295, 'TKT-MMF3352P-NUM9', 'techo', 'el techo del consultorio 17 se despego la pintura por humedad', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-06 13:03:19.539844', '2026-03-13 12:01:38.201979', '[]', '3 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (304, 'TKT-MMJ68SJU-DV9B', 'PANTALLA DE NUMERADOR Y QR', 'NO FUNCIONA LA  PANTALLA PARA SACAR NUMERO Y QR, ESTA APAGADO EL MONITOR', 'closed', 'medium', 'Sistemas', 'MARIANA ZAGO', 'zagom@idiagnostica.com.ar', 3, '2026-03-09 09:42:46.795651', '2026-03-09 09:52:02.485477', '[]', 'recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (305, 'TKT-MMJ7YM5T-FRAD', 'Quitar plotter del interior del ascensor.', 'Por favor, quitar el plotteo del ascensor, dejando libres las placas para una limpieza profunda. 
Solo se mantendra la información de los pisos.', 'closed', 'low', 'Mantenimiento', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 10, '2026-03-09 10:30:51.186216', '2026-03-09 14:12:12.445989', '[]', 'MKT, Gestión de grillas, Call Center', 'Ciudad');
INSERT INTO public.tickets VALUES (641, 'TKT-MTLUO9YM-XVO7', 'control de cemepaci', 'martes 8 control de bomberos', 'open', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-03 15:20:08.687444', '2026-09-07 09:53:59.555228', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (308, 'TKT-MMJH7UEV-GG0C', 'BIDON DE AGUA', 'BIDON DE AGUA', 'closed', 'low', 'Mantenimiento', 'MARIA DEL CARMEN HERRERA', 'mdelcherreragodoy@gmail.com', 10, '2026-03-09 14:49:58.329699', '2026-03-09 15:19:35.877405', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (306, 'TKT-MMJG9G4K-R1XJ', 'agua', 'llevar un bidon de agua a mamografia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-09 14:23:13.510261', '2026-03-09 15:19:39.378012', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (307, 'TKT-MMJGW2AO-5L5V', 'HUB DE ACCESO', 'SACAR DEL MENU EL ENLACE CON SANCOR SALUD  POR NO TENER ACTIVO EL CONVENIO', 'closed', 'medium', 'Sistemas', 'CLAUDIO', 'faccendinic@idiagnostica.com.ar', 3, '2026-03-09 14:40:48.674652', '2026-03-10 08:14:46.048387', '[]', 'hub de acceso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (315, 'TKT-MMKU5D1X-W9UL', 'reparar manija ventana directorio', 'reparar manija ventana directorio', 'closed', 'medium', 'Mantenimiento', 'danilo barresi', 'barresid@idiagnostica.com.ar', 10, '2026-03-10 13:39:43.702882', '2026-03-10 14:36:10.491963', '[]', 'gerencia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (317, 'TKT-MMKWBHXF-EGU4', 'filtracion de agua 1 piso', 'se reforzo con mas membrana liquida y se coloco membrana asfáltica', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-10 14:40:29.18835', '2026-03-10 14:40:39.654004', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (316, 'TKT-MMKW9PPN-1FZ1', 'filtracion de agua tuerquita', 'se coloco membrana entre la estrtuctura del la sala de la tuerquita y el 3 piso.', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-10 14:39:05.964651', '2026-03-10 14:40:54.788337', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (314, 'TKT-MMKS9199-C77E', 'ACTUALIZACION DE USUARIO', 'Necesito por favor que me actualicen mi usuario para la recepcion, configuracion de recepcionista para el usuario razeglio', 'closed', 'medium', 'Sistemas', 'ROMINA AZEGLIO', 'romiazeglio@gmail.com', 3, '2026-03-10 12:46:35.807528', '2026-03-11 08:59:05.559786', '[]', 'RECEPCION', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (318, 'TKT-MML0UR9V-VLKR', 'sin sistema no puedo arribar ver pacientes', 'no se puede ingfresar al sistema de consolas n cargar pacientes', 'closed', 'medium', 'Sistemas', 'GIMENA manique', 'gimenasolmanrique@gmail.com', 3, '2026-03-10 16:47:26.241307', '2026-03-11 08:59:22.789921', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (310, 'TKT-MMJSVWU2-1VN7', 'luces dicroicas de afuera.', 'luces quemadas por el lado de la pared que da a la calle maza. ninguna prende en ese lateral.', 'closed', 'low', 'Mantenimiento', 'pablo estrella', 'estrellap@idiagnostica.com.ar', 10, '2026-03-09 20:16:36.995724', '2026-03-11 13:55:04.455473', '["/uploads/tickets/ticket-1773098196975-609253870.jpeg"]', 'recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (260, 'TKT-MM3LUJSG-WU7I', 'pocelanato y cinta led', 'el le piso de la recepcion al lado del dispenser esta un pocelanato despegado y se ha levantado provocando tropiezos a los pacientes y en  el recibidor que esta en recepcion se a despegado en en la esquina  la cinta de luces led que rodea todo el mueble abajo.', 'closed', 'low', 'Mantenimiento', 'MARIANA ZAGO', 'zagom@idiagnostica.com.ar', 10, '2026-02-26 12:15:17.298652', '2026-03-11 13:55:47.428663', '[]', 'recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (311, 'TKT-MMKP3W22-CAII', 'No puedo abrir la ventana para tipear los estudios de San Martin, se queda pensando y tampoco me lo cierra a uno que ya había tipeado.', 'No puedo abrir la ventana para tipear los estudios de San Martin, se queda pensando y tampoco me lo cierra a uno que ya había tipeado.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezgerardomartin@gmail.com', 3, '2026-03-10 11:18:36.940766', '2026-03-11 14:16:04.656819', '[]', 'Transcripción', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (319, 'TKT-MMMAWOZ0-6BHX', 'Llamador', 'Por favor necesito que en el sistema de recepcion me coloquen el llamador de pac completo, falta ecografia.
Para el usuario razeglio. Gracias', 'closed', 'medium', 'Sistemas', 'ROMINA AZEGLIO', 'romiazeglio@gmail.com', 3, '2026-03-11 14:16:38.893358', '2026-03-11 14:19:32.427307', '[]', 'recepcion 1P', 'Ciudad');
INSERT INTO public.tickets VALUES (309, 'TKT-MMJSSSWI-1H68', 'foco plafon y gotera en techo.', 'foco quemado en el vestidor de resonancia y gotera en el techo del tecnico donde estan las computadoras.', 'closed', 'medium', 'Mantenimiento', 'pablo estrella', 'estrellap@idiagnostica.com.ar', 10, '2026-03-09 20:14:11.924963', '2026-03-11 15:07:06.900569', '["/uploads/tickets/ticket-1773098051915-501595834.jpeg", "/uploads/tickets/ticket-1773098051917-452892963.jpeg"]', 'resonancia', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (320, 'TKT-MMMCRD2O-8OJD', 'puerta', 'no cierra la puerta del baño de pacientes', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-11 15:08:29.42627', '2026-03-11 15:09:02.456109', '[]', 'baño', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (321, 'TKT-MMMCRXHA-Y0Q9', 'baño', 'tapa floja del baño de la cocina', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-11 15:08:55.8721', '2026-03-11 15:09:06.270598', '[]', 'baño', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (324, 'TKT-MMNLPKM6-ZISW', 'baño', 'boton del baño trabado', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-12 12:06:48.607524', '2026-03-12 12:06:59.014207', '[]', 'eco 3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (322, 'TKT-MMNK6KPW-X71J', 'congelado', 'el aire del brivo amaneció congelado por la húmeda del ambiente. se puso a descongelar y listo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-12 11:24:02.663293', '2026-03-12 13:39:07.223062', '[]', 'brivo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (303, 'TKT-MMJ5I7ID-8RIU', 'Compra RAM', 'Buen día, necesitamos realizar una compra de memoria RAM para notebook Compaq ( la misma a la que se le cambió el teclado ) ya que actualmente cuenta con 4GB y para el uso activo es poco.

El valor ronda final los 70-75 mil pesos, y la compra se realizará en Electrosoft, quedo atento a aprobación para realizar la compra', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 11, '2026-03-09 09:22:06.47052', '2026-03-13 08:19:20.404957', '["/uploads/tickets/ticket-1773058926458-854858426.png"]', 'Sistema', 'Ciudad');
INSERT INTO public.tickets VALUES (313, 'TKT-MMKQ8K99-1OUU', 'Hojas para impresora del 1er piso y lapiceras', 'se necesitan hojas para la impresora de eco del 1er piso 
y lapiceras', 'closed', 'medium', 'Compras e Insumos', 'Monica', 'veram@idiagnostica.com.ar', 11, '2026-03-10 11:50:14.543612', '2026-03-13 08:19:27.119013', '[]', 'TRANSCIPCIÓN', 'Ciudad');
INSERT INTO public.tickets VALUES (326, 'TKT-MMOSXZKO-HTHR', 'Mi maquina esta muy lenta', 'Esta super lenta para navegar, para trabajar con paquete office. Por favor, la revisan. Gracias !!', 'closed', 'medium', 'Sistemas', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-03-13 08:17:04.766471', '2026-03-13 08:29:19.999328', '[]', 'MKT, Gestión de grillas, Call Center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (312, 'TKT-MMKPNGF4-MNG9', 'Mamografías', 'Mamografías en el pacs se ven muy blancas ( 1 o 2 de las 4 subidas )', 'closed', 'medium', 'Sistemas', 'Romina', 'mail@mail.com', 3, '2026-03-10 11:33:49.795046', '2026-03-13 08:40:55.018787', '["/uploads/tickets/ticket-1773153229785-610615823.png", "/uploads/tickets/ticket-1773153229789-538899334.png"]', 'Mamografía', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (325, 'TKT-MMNUXI6T-5O7J', 'toner', 'no tenemos toner', 'closed', 'medium', 'Sistemas', 'carina romagnoli', 'carinaromagnoli1975@gmail.com', 3, '2026-03-12 16:24:55.278793', '2026-03-13 15:57:01.858889', '[]', 'recepción 1piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (327, 'TKT-MMOTZLM3-JC59', 'Resolución Pantallas Tótem', 'Actualizar las PC, hacer limpieza para poder mejorar la resolucion de las pantallas.', 'closed', 'medium', 'Sistemas', 'Lorena Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-03-13 08:46:19.564551', '2026-03-14 11:18:09.833206', '[]', 'Recepciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (323, 'TKT-MMNKSPCS-SJY1', 'Armario', 'Las puertas del armario están descuadradas . Lo noté hoy. La bisagra se ve en mal estado.', 'closed', 'low', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-03-12 11:41:15.106662', '2026-03-13 12:01:32.916846', '[]', 'Resonador Articulaciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (642, 'TKT-MTLYSWPT-0QLV', 'problemas de impresion', 'la computado del puesto 1 no funciona no deja imprimir nada y muy lenta , cuando se intenta imprimir la computadora se traba se queda pensando y no se puede usar mas', 'closed', 'medium', 'Sistemas', 'claudia raiano', 'rodriguezf@idiagnostica.com.ar', 3, '2026-09-03 17:15:43.278524', '2026-09-04 09:05:04.632968', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (644, 'TKT-MTN0RCUV-KG63', 'ayuda', 'ayudar al ingeniero eric en el brivo', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-04 10:58:16.280784', '2026-09-04 10:58:29.977773', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (361, 'TKT-MMP7QIDG-E05G', 'matafuegos', 'intercambiar el matafuego del pasillo del 1 piso con el del 4 piso, y pegar el cartel q se despego', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-13 15:11:10.086148', '2026-03-13 15:43:19.214549', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (364, 'TKT-MMT2BGXK-935E', 'TAMAÑO DE LAS FUENTES  EN LOS TOTEN', 'NECESITO DE UNA VEZ POR TODAS QUE LA FUENTE SEA MAS GRANDE  MAYOR TAMAÑO LETRA MAS CLARA PARA QUE LOS ´PACIENTES PUEDAN  OPTAR CON FACILIDAD Y SE UNIFIQUEN LOS TAMAÑOS EN TODAS LAS SEDES', 'closed', 'medium', 'Sistemas', 'CLAUDIO FACCENDINI', 'faccendinic@idiagnostioca.com.ar', 3, '2026-03-16 07:50:35.011068', '2026-03-16 08:47:24.929409', '[]', 'RECEPCIONES', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (365, 'TKT-MMT3W57J-9GHE', 'NO FUNCIONA MI INTERNO', 'NO PUEDO LOGUEARME', 'closed', 'medium', 'Sistemas', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 3, '2026-03-16 08:34:39.1999', '2026-03-16 10:01:49.271032', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (366, 'TKT-MMT7REPP-6IEH', 'Pintura', 'Pintar paredes blancas de la vip', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-03-16 10:22:56.701898', '2026-03-16 11:54:25.012195', '[]', 'VIP', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (367, 'TKT-MMTG7IVU-AHZ0', 'BIDON DE AGUA', 'BIDON DE AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-03-16 14:19:25.530956', '2026-03-16 14:59:25.581127', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (360, 'TKT-MMP52K2B-589D', 'bobinas', 'Hola franco, te pido si podes colocar los tornillos nuevos a las bobinas del resonador de articulaciones.
Muchas Gracias.', 'closed', 'medium', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-03-13 13:56:33.303689', '2026-03-16 14:59:31.734646', '[]', 'resonador de articulaciones Tuerca.', 'Ciudad');
INSERT INTO public.tickets VALUES (369, 'TKT-MMTMH7IO-10FL', 'No hay sistema', 'Se corto el sistema y no puedo dar inicio, finalizar un estudio o una nota con los antecedentes del paciente.', 'closed', 'medium', 'Sistemas', 'Alejandro Montero', 'alejdromonterof@gmail.com', 3, '2026-03-16 17:14:55.058519', '2026-03-17 08:23:40.62437', '[]', 'Resonador Articulaciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (368, 'TKT-MMTG868R-V9NX', 'cambio de matricula medico derivante', 'Figuran varias matriculas con niombre de derivante cargados con matriculas erroneas .- mat 10243 Borgoa Stella Maris, siendo lo correcto par aesta matricula Borgia Laura', 'closed', 'medium', 'Sistemas', 'Vanesa medina', 'medinav@idiagnostica.com.ar', 3, '2026-03-16 14:19:55.804259', '2026-03-17 10:05:02.506856', '[]', 'RECEPCION', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (371, 'TKT-MMUMARJD-7Y71', 'lavado', 'se lavo los aires de el resonador de alto campo. sepi. bajo campo, aire central y aires que estaban en la terraza', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-17 09:57:40.587418', '2026-03-17 10:43:58.423838', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (373, 'TKT-MMUNZAP5-KJFK', 'lockers', 'cambiar los lockers viejos por los nuevos del brivo y bajo campo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-17 10:44:44.778753', '2026-03-17 10:44:53.203506', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (372, 'TKT-MMUMBVY8-UTKZ', 'filtros', 'limpiar filtros de todos los split del edificio', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-17 09:58:32.961541', '2026-03-17 12:11:17.445133', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (375, 'TKT-MMUR3DXH-QUW0', 'patio', 'subir aluminios de plata baja al techo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-17 12:11:54.439975', '2026-03-17 13:43:10.560939', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (370, 'TKT-MMUIWJQ4-KQRJ', 'Sistema de mza lento', 'Quiero hacer una corrección y no me deja', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-03-17 08:22:38.429294', '2026-03-18 09:17:59.792304', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (381, 'TKT-MMW7JSMO-RW5I', 'plafon', 'un plafon estaba caido', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-18 12:40:20.017713', '2026-03-18 12:40:59.707434', '[]', 'pasillo', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (382, 'TKT-MMW7KG2X-Y1OE', 'zocalo', 'sacar tornillos de zocalos', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-18 12:40:50.410981', '2026-03-18 12:41:04.34283', '[]', 'dirctorio', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (380, 'TKT-MMW7J0SO-1PV1', 'cartel', 'cambiar la conexion del cartel de afuera por que siempre estaba encendido', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-18 12:39:43.945567', '2026-03-18 12:41:15.570477', '[]', 'maipu', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (362, 'TKT-MMQ7UJVC-KT8A', 'Almacenamiento', 'Necesitamos renovar stock de SSD 240GB para mejora de las computadores actuales deficientes.

La compra debe ser de al menos 5 unidades. El mejor precio del mercado encontrado', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 11, '2026-03-14 08:02:04.835413', '2026-03-19 11:38:00.180418', '["/uploads/tickets/ticket-1773486124727-42917526.png"]', 'Sistema', 'Ciudad');
INSERT INTO public.tickets VALUES (384, 'TKT-MMXONWQ6-FC74', 'tamden', 'un tornillo salido molestas', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-19 13:27:11.599304', '2026-03-19 13:28:46.872484', '[]', 'planta baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (383, 'TKT-MMXHW9D8-JCBU', 'terraza', 'lavar la terraza', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-19 10:17:43.916953', '2026-03-19 13:28:53.108723', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (385, 'TKT-MMXOPLRL-GGE9', 'oficina de guada', 'buscar la llave de la puerta de la oficiana y colocarle una cerradura a un cajon', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-19 13:28:30.707206', '2026-03-19 15:19:38.900779', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (387, 'TKT-MMY4DG66-G5MU', 'no funciona work list', 'debo cargar pacientes de manera manual', 'closed', 'medium', 'Sistemas', 'Gimena Soledad Manrique Olivera', 'gimenasolmanrique@gmail.com', 3, '2026-03-19 20:46:57.44966', '2026-03-20 09:32:27.454408', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (363, 'TKT-MMT28FN2-KNSI', 'TOTEN', 'TODAS LAS MAÑANAS TENEMOS PROBLEMAS DE CONEXION  CON EL TV O LA PANTALLA  TACTIL', 'closed', 'medium', 'Sistemas', 'CLAUDIO FACCENDINI', 'faccendinic@idiagnostica.com.ar', 3, '2026-03-16 07:48:13.368204', '2026-03-20 09:35:03.128473', '[]', 'RECEPCION PLANTA BAJA', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (374, 'TKT-MMUO9G3G-AWP1', 'TAMAÑO DE LAS FUENTES EN LOS TOTENS DE RECEPCIONES', 'NECESITAMOS EN FORMA URGENTE QUE AGRANDEN EL TAMAÑO DE LOS MENUES EN LOS TOTEN DE INGRESO EN MENDOZA Y MAIPU', 'closed', 'medium', 'Sistemas', 'RECEPCIONES', 'faccendinic@idiagnostica.com.ar', 3, '2026-03-17 10:52:38.334737', '2026-03-20 09:35:12.072267', '[]', 'RECEPCIONES', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (376, 'TKT-MMUR4IFX-QZKN', 'ver que tirar', 'ver que tirar elementos grandes para un contenedor', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-17 12:12:46.942756', '2026-03-23 08:50:19.464345', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (378, 'TKT-MMUW77MV-ZCG8', 'pintura', 'pintar parte blanca de facturacion', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-17 14:34:50.984858', '2026-03-23 12:30:38.799016', '[]', 'facturacion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (379, 'TKT-MMW24MYF-VBWY', 'Silla en consola.', 'La silla está perdiendo los tornillos del respaldo.', 'closed', 'low', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-03-18 10:08:34.746617', '2026-03-26 13:49:06.007715', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (386, 'TKT-MMXQZZ5X-JID2', 'carga de estudios', 'no se cargan los pacientes al worklist', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-03-19 14:32:33.864528', '2026-03-20 09:31:59.129048', '[]', 'resonancia y tac', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (388, 'TKT-MMYT1KMU-UZBX', 'worklist', 'buen día Matías y Rodolfo , No esta funcionando el worklist en ninguno de los equipos de resonancia y tac.', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-03-20 08:17:33.75229', '2026-03-20 09:32:28.295796', '[]', 'resonancia y tac', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (390, 'TKT-MMYUDQHE-DJCW', 'Colocar cerradura en mueble', 'Buen día, solicito que coloquen cerradura en cajón.


Gracias!', 'closed', 'medium', 'Mantenimiento', 'Guadalupe Sanchez', 'sanchezg@idiagnostica.com.ar', 10, '2026-03-20 08:55:00.82063', '2026-03-20 09:32:36.759701', '[]', 'RRHH', 'Ciudad');
INSERT INTO public.tickets VALUES (389, 'TKT-MMYTN4TU-KBR6', 'PUBLICO SM', 'No se puede conectar desde esa pc al servidor sr-imagenes, mando capturas e ingreso a anydesk. saludos', 'closed', 'medium', 'Sistemas', 'Jonatan Luduena', 'jluduena@idiagnostica.com.ar', 3, '2026-03-20 08:34:19.700708', '2026-03-20 10:21:09.067075', '["/uploads/tickets/ticket-1774006459368-541555064.png", "/uploads/tickets/ticket-1774006459460-864090865.png"]', 'recepcion', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (391, 'TKT-MMZ6IKIF-BQEG', 'baño', 'boton del baño se perdio', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-20 14:34:41.753928', '2026-03-20 14:36:28.461041', '[]', 'baño', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (392, 'TKT-MMZ6KM9Q-E07M', 'alarma', 'se escuchaba una alarma debes en cuando. resulta que era el sepi que estuvo con un baipass incompleto. que provocaba que se vaciara y sonara la alarma por bajo flujo', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-20 14:36:17.344844', '2026-03-20 14:36:35.276037', '[]', 'alarma', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (393, 'TKT-MMZ6LQ6J-6DS7', 'plafon', 'plafon del vestidor se quemo', 'closed', 'high', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-20 14:37:09.067998', '2026-03-20 14:37:20.174384', '[]', 'eco 1', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (395, 'TKT-MN38RPFL-F37Z', 'protector para la pared', 'colocar protector en la pared de facturacion', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-23 10:48:51.971992', '2026-03-23 12:30:30.36567', '[]', 'facturacion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (394, 'TKT-MN353RWX-OCOW', 'caldera', 'probar y purgar los radiadores que hagan falta', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-23 09:06:16.595352', '2026-03-23 12:30:35.05192', '[]', '2 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (397, 'TKT-MN3DE9TW-P46M', 'silla', 'se cambio la base de 2 sillas en la recepcion', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-23 12:58:23.302411', '2026-03-23 14:31:49.725326', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (403, 'TKT-MN67353O-42YM', 'baño', 'el baño de planta baja se rompió el picaporte, se cambio por uno nuevo', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 12:25:04.791331', '2026-03-25 12:25:13.641704', '[]', 'plata baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (404, 'TKT-MN674ES2-NKUL', 'puerta de patio', 'la puerta del patio no cerraba. se arreglo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 12:26:03.988044', '2026-03-25 12:26:15.502564', '[]', 'planta baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (402, 'TKT-MN66SXS8-ACS9', 'aire acondicionado,', 'se solicita a franco que revise el aire por lo que los tecnicos mnos indican que se sentia muy frio en el sector de rayos', 'closed', 'low', 'Mantenimiento', 'medina vanesa', 'medinav@idiagnostica.com.ar', 10, '2026-03-25 12:17:08.747191', '2026-03-25 14:02:43.046106', '[]', 'recepcion pb', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (401, 'TKT-MN66P8IN-03LF', 'aire acondicionado', 'se le solicita el dia 13/03/26 a Franco que vea el aire porque en teoria no marcaba bien los grados', 'closed', 'low', 'Mantenimiento', 'medina vanesa', 'medinav@idiagnostica.com.ar', 10, '2026-03-25 12:14:16.033406', '2026-03-25 14:02:49.486551', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (400, 'TKT-MN66N945-WZPE', 'silla con clavo en recepcion', 'en la sala de recepcion se observa una silla con un clavo el cual se le solicita a mantenimineto que lo mire por favor', 'closed', 'low', 'Mantenimiento', 'vanesa medina', 'medinav@idiagnostica.com.ar', 10, '2026-03-25 12:12:43.502889', '2026-03-25 14:02:56.479626', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (410, 'TKT-MN6APQIP-8YIO', 'puerta', 'se arreglo la puerta de sistema que no cerraba', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 14:06:37.828254', '2026-03-25 14:07:28.90893', '[]', 'pasillo', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (411, 'TKT-MN6AQPUP-6AIE', 'eco 1', 'se limpia filtro de aire de eco 1', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 14:07:23.619142', '2026-03-25 14:07:35.363989', '[]', 'aire', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (409, 'TKT-MN6AOR70-JVZ1', 'vestirdor', 'puerta del locker del vestidor no tenia llave. se cambio cerradura', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 14:05:52.047012', '2026-03-25 14:07:40.258489', '[]', 'eco 1', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (408, 'TKT-MN6ANGWT-JCTQ', 'aire', 'limpieza de aire acondicionado central de maipu', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 14:04:52.062224', '2026-03-25 14:07:45.433795', '[]', 'recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (407, 'TKT-MN6AMMJ4-8Q5P', 'puerta de baño', 'puerta del baño de resonancia no cierra. se arreglo y quedo funcionando', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-25 14:04:12.699101', '2026-03-25 14:07:50.794142', '[]', 'vestidor maipu', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (405, 'TKT-MN69V01S-N2WV', 'BIDON DE AGUA', 'BIDON DE AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-03-25 13:42:43.842818', '2026-03-25 15:02:55.716253', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (398, 'TKT-MN66IP1J-T2HZ', 'mail sin funcionar', 'no tiene configurado mi casilla de correo', 'closed', 'medium', 'Sistemas', 'vanesa medina', 'medinav@idiagnostica.com.ar', 3, '2026-03-25 12:09:10.857994', '2026-03-26 08:35:51.77244', '[]', 'recepcion pb', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (412, 'TKT-MN7EHJOO-66AV', 'NO PUEDO TENER ACCESO DESDE MI COMPU PERSONAL', 'NECESITO POR FAVOR CON SUMA URGENCIA EN LO POSIBLE , EL TEMA DE LA COMPU YA QUE DESDE AYER NO HE PODIDO TENER ACCESO AL SISTEMA DESDE MI CASA . ESPERAMOS UN A PRONTA RESPUESTA, MUCHAS GRACIAS ESTIMADOS ....', 'closed', 'medium', 'Mantenimiento', 'FACUNDO', 'paredesf@idiagnostica.com.ar', 10, '2026-03-26 08:40:00.369799', '2026-03-26 08:44:04.098467', '[]', 'facturacion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (399, 'TKT-MN66K2RJ-1E39', 'mal funcionamiento del escaner', 'no funciona se reclama en reiteradas opurtunidades', 'closed', 'medium', 'Sistemas', 'claudia raiano', 'rodriguezf@idiagnostica.com.ar', 3, '2026-03-25 12:10:15.298971', '2026-03-26 16:04:20.263569', '[]', 'RECEPCION', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (441, 'TKT-MNGAAFHN-O1AW', 'perfume', 'colocar repuesto de perfume en baño de primer piso pasillo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-01 13:52:25.453936', '2026-04-01 14:44:49.864122', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (439, 'TKT-MNG6QHJN-BIC9', 'Insumos para RM', 'Descartador (2)
Contraste para Resonancia.
Jeringas de 5ml
Algodón
Alcohol (2)
Gel para estudios de pelvis con gel.', 'closed', 'medium', 'Compras e Insumos', 'David Gutiérrez', 'davidguti1405@yahoo.com', 11, '2026-04-01 12:12:56.147937', '2026-04-06 11:05:26.006512', '[]', 'resonancia y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (396, 'TKT-MN3AHOEO-8219', 'telefono', 'colocacion de linea y aparato', 'closed', 'medium', 'Sistemas', 'mariela', 'marielaajaya@gmail.com', 3, '2026-03-23 11:37:03.313916', '2026-04-07 08:21:36.772756', '[]', 'oficina workstation de rayos', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (413, 'TKT-MN7ILOE4-GUBG', 'Gestión de cola de espera', 'verificar si el sistema nos permite colocar una placa previa a la de estudios donde el paciente deba indicar si es por OOSS o Particular. Esto nos ayudaria a darle prioridad al particular.', 'closed', 'medium', 'Sistemas', 'Lorena Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-03-26 10:35:11.559395', '2026-04-09 08:10:46.436395', '[]', 'Recepciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (645, 'TKT-MTN15BON-88QF', 'Crear clave', 'Crear clave para consultar el vizualizador de estudios. Clave liberada para las 3 sedes. 
TERRAZAS', 'closed', 'medium', 'Sistemas', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-09-04 11:09:07.945244', '2026-09-07 08:01:39.807093', '[]', 'MKT, Gestión de grillas, Call Center', 'Ciudad');
INSERT INTO public.tickets VALUES (639, 'TKT-MTLUEIKX-LLE9', 'COMPU PLANTA BAJA PUESTO NUMERO 1 RAIANO CLAUDIA', 'LA COMPU DE PLANTA BAJA, QUE COMUNMENTE LA USA RAIANO CLAUDIA, NO FUNCIONA CORRECTAMENTE , SE TIULDA, REVISAR POR FAVOR', 'closed', 'medium', 'Sistemas', 'VANESA MEDINA', 'medinav@idiagnostica.com.ar', 3, '2026-09-03 15:12:33.308582', '2026-09-07 08:01:46.029281', '[]', 'RECEPCION', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (414, 'TKT-MN7LPIZ7-JNOF', 'consola tecnico y medico', 'buenos dias! Es posible agregar al perfil de Caludia Raiano la consola de medicos y tecnicos por favor asi puede agregar los trazados', 'closed', 'medium', 'Sistemas', 'vanesa medina', 'medinav@idiagnostica.com.ar', 3, '2026-03-26 12:02:10.006169', '2026-03-26 16:19:34.109142', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (418, 'TKT-MN96VKT2-EAT7', 'cajon', 'colocarle una cerradura al cajon', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-27 14:42:30.422984', '2026-03-27 14:42:41.7325', '[]', 'german', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (419, 'TKT-MN97D7B9-XWWU', 'agua', 'agua', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-27 14:56:12.74634', '2026-03-27 15:20:47.263122', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (417, 'TKT-MN96BDBH-5JO7', 'CHEQUEAR LA COMPUTADORA DE LORENA USO DE TACLADO Y AUDIO', 'NO PUEDE PASAR AUDIOS DE ESTUDIOS EN WORD 
NECESITA UN TECLADO MULTIMEDIA', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-03-27 14:26:47.599558', '2026-03-28 10:57:46.819492', '[]', 'TRANSCIPCIÓN', 'Ciudad');
INSERT INTO public.tickets VALUES (421, 'TKT-MNAEU76O-QKHR', 'se rompio el picaporte de la puerta', 'se rompio el picaporte de la puerta', 'closed', 'low', 'Mantenimiento', 'claudia cataldo', 'claudiacataldo01@gmail.com', 10, '2026-03-28 11:13:09.218907', '2026-03-30 09:00:01.768088', '[]', 'transcripción', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (420, 'TKT-MNAALQXQ-ZHFY', 'Rotura de picaporte de puerta nueva de la sala de transcripción en primer piso.', 'Hola Chicos! Les cuento que se a roto el picaporte de puerta nueva de la sala de transcripción en primer piso.
Muchas Gracias!', 'closed', 'low', 'Mantenimiento', 'Gerardo', 'dominguezgerardomartin@gmail.com', 10, '2026-03-28 09:14:36.448341', '2026-03-30 09:03:35.710936', '[]', 'TRANSCIPCIÓN', 'Ciudad');
INSERT INTO public.tickets VALUES (422, 'TKT-MND3EOJU-PYI1', 'ESTA ROTO EL PICAPORTE DE LA PUERTA DE TRANSCRIPCIÓN', 'ESTA ROTO EL PICAPORTE DE LA PUERTA DE TRANSCRIPCIÓN', 'closed', 'low', 'Mantenimiento', 'Monica', 'veram@idiagnostica.com.ar', 10, '2026-03-30 08:16:27.980429', '2026-03-30 09:03:44.767468', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (425, 'TKT-MNDEPEG8-DR0K', 'gotera', 'gotea un aire del bajo campo. se destapo el desagote y quedo bien', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-30 13:32:43.882671', '2026-03-30 13:32:53.904757', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (426, 'TKT-MNDG8WQN-UO7C', 'aire de sala de maquinas apagado', 'aire de sala de maquina apagado y no se puede prender .,', 'closed', 'medium', 'Mantenimiento', 'CECILIA', 'chechualf@gmail.com', 10, '2026-03-30 14:15:53.665891', '2026-03-30 15:01:50.021916', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (429, 'TKT-MNEUBZSD-OPWB', 'BIDON  DE AGUA', 'BIDON DE AGUA', 'closed', 'medium', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-03-31 13:37:58.38428', '2026-03-31 16:24:43.710821', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (431, 'TKT-MNEZKV13-X61Y', 'AGUA', 'Traer bidón de agua por favor', 'closed', 'low', 'Mantenimiento', 'maria jose calvo', 'mariajosecalvo02@gmail.com', 10, '2026-03-31 16:04:50.209096', '2026-03-31 16:25:02.04236', '[]', 'Call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (427, 'TKT-MNEP9PWB-3DLG', 'Ajustar bisagra de casillero', 'Ajustar bisagra inferior de casillero en cambiador 1.', 'closed', 'low', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-03-31 11:16:14.174335', '2026-04-01 08:40:49.046767', '[]', 'RMN 4to piso alto campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (433, 'TKT-MNFY2U4V-02PH', 'Vincha', 'no me funciona la vincha, reponer por favor', 'closed', 'medium', 'Sistemas', 'erica contreras', 'mariajosecalvo02@gmail.com', 3, '2026-04-01 08:10:35.804045', '2026-04-01 08:43:57.768844', '[]', 'ART', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (430, 'TKT-MNEZF9UG-88XJ', 'NO ME FUNCIONA LA VINCHA DEL TELEFONO', 'NO FUNCIONA', 'closed', 'medium', 'Sistemas', 'ANDREA BELEN', 'belu29326@gmail.com', 3, '2026-03-31 16:00:29.47771', '2026-04-01 08:44:00.360609', '[]', 'ART', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (434, 'TKT-MNFY3PQL-W8E4', 'Arreglo de computadora', 'Actualización de sistema', 'closed', 'medium', 'Sistemas', 'maximiliano reynaga', 'mariajosecalvo02@gmail.com', 3, '2026-04-01 08:11:16.781854', '2026-04-01 10:46:49.924628', '[]', 'Call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (432, 'TKT-MNFY0OJS-ZASH', 'Arreglo de computadora', 'Actualizacion de computadora', 'closed', 'medium', 'Mantenimiento', 'maximiliano reynaga', 'mariajosecalvo02@gmail.com', 10, '2026-04-01 08:08:55.253327', '2026-04-01 10:58:13.865962', '[]', 'Call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (437, 'TKT-MNG4RTBU-9X6K', 'Cambio de silla tamden', 'se quebro la silla y la cambiamos', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-01 11:17:58.845311', '2026-04-01 11:18:13.098149', '[]', 'planta baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (436, 'TKT-MNG4OAUC-Z5X1', 'aire acondicionado perdia agua', 'se destapo el desagote en ecógrafo 3', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-01 11:15:14.918856', '2026-04-01 11:18:21.554949', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (435, 'TKT-MNG44PD8-VVTU', 'cambio picaportes', 'se cambio picaportes de la puerta del piso 1 y 2', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-01 11:00:00.633694', '2026-04-01 11:18:27.841523', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (423, 'TKT-MND58QAD-OBVB', 'impresora', 'las imagenes q se mandan a imprimir estan grises y borrosas -.', 'closed', 'medium', 'Sistemas', 'CECILIA', 'chechualf@gmail.com', 3, '2026-03-30 09:07:49.528016', '2026-04-07 08:22:06.303657', '[]', 'resonancia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (424, 'TKT-MND5P8E0-7X8T', 'Imagenes de Impresora', 'Las imagenes de la impresora salen borrosas y demasiado grises', 'closed', 'medium', 'Sistemas', 'Vargas Aldana Noelia', 'aldanavargas@icloud.com', 3, '2026-03-30 09:20:39.482416', '2026-04-07 08:22:20.872827', '[]', 'Tomografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (406, 'TKT-MN6A0GE8-50HR', 'recepcion, baño publico, consultorio, puerta electrica pasillo central, resonancia.', 'plafones de recepcion sucios.

cerradura de baño publico (hombres) no cierra con llave.

cerradura consultorio 1 no cierra con llave.

escritorio de computadoras (resonancia). con piques en la madera.

puerta electrica que divide rececion con pasillo central. al tocar el boton para abrir desde adentro, se vuelve a cerrar de inmediato.', 'closed', 'low', 'Mantenimiento', 'estrella pablo', 'estrellap@idiagnostica.com.ar', 10, '2026-03-25 13:46:58.306827', '2026-04-14 13:11:39.491146', '[]', 'recepcion, baño publico, consultorio, resonancia.', 'Maipú');
INSERT INTO public.tickets VALUES (438, 'TKT-MNG532A4-M3T0', 'Compra de vinchas', 'Buen día, solicito la compra de 3 unidades nuevas de vinchas, debido a que algunas del call center presentan problemas de audio, cable corteajeado, etc.

Compra sugerida debido a que ya se han usado y son de buena calidad.

https://www.mercadolibre.com.ar/vincha-headset-auricular-p--plantronics-practica-t110-t100/up/MLAU214750085#polycard_client=search-desktop&search_layout=grid&position=3&type=product&tracking_id=bc856abd-3cc3-418c-8f6b-9f21669fd18a&wid=MLA1127419919&sid=search', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo', 'vigonr@idiagnostica.com.ar', 11, '2026-04-01 11:26:43.662916', '2026-04-17 09:25:01.82955', '[]', 'Call center', 'Ciudad');
INSERT INTO public.tickets VALUES (415, 'TKT-MN912CFG-Z9X4', 'pintura', 'pintar la escalera', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-03-27 11:59:48.461411', '2026-04-22 12:10:04.046554', '[]', 'escalera', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (428, 'TKT-MNESDND3-PZHN', 'Problemas con el envío de estudios por la IA', 'Estudios informados y cerrados por medio de la IA parece que no están llegando a los paciente el informe, ya he recibido varios reclamos', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-03-31 12:43:16.361915', '2026-07-04 08:04:58.927436', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (443, 'TKT-MNK8QME9-1RY3', 'se quemo foco de pasillo, frente salida del ascensor', 'sin luz en pasillo, salida del ascensor 
sala de espera 4° piso', 'closed', 'low', 'Mantenimiento', 'gimena', 'gimenasolmanrique@gmail.com', 10, '2026-04-04 08:20:06.401421', '2026-04-04 09:32:43.995409', '[]', 'RMN 4to piso', 'Ciudad');
INSERT INTO public.tickets VALUES (377, 'TKT-MMUTR1TP-IMDR', 'AMPLIFICADOR PARA AUMENTAL EL VOLUMEN.', 'Buenas Tardes Chicos! Les pido la posibilidad de conseguir un amplificador para el sonido en mi escritorio (4 piso) como tiene Mónica y Gastón. 
Los audios cada vez se escuchan más bajo y si hay paciente hablando en la sala de espera no llego a escuchar el audio de los médicos para poder tipearlos.
El volumen del sistema está al máximo, el probable es la conexión de mis auriculares.
Muchas Gracias!', 'closed', 'medium', 'Compras e Insumos', 'Gerardo', 'dominguezgerardomartin@gmail.com', 11, '2026-03-17 13:26:17.728465', '2026-04-06 11:05:07.322', '[]', 'Transcripción', 'Ciudad');
INSERT INTO public.tickets VALUES (440, 'TKT-MNG8LRW0-HUMG', 'no puedo arribar o dar finalizado a los pacientes ya que hay un paciente arribado el dia 08/04/2026', 'se esta realizando un paciente con fecha el 08/04/2026
caceres jonathan', 'closed', 'medium', 'Sistemas', 'GIMENA', 'gimenasolmanrique@gmail.com', 3, '2026-04-01 13:05:15.506277', '2026-04-07 08:20:18.031137', '[]', 'resonador de articulaciones Tuerca.', 'Ciudad');
INSERT INTO public.tickets VALUES (444, 'TKT-MNNL44C4-A8C5', 'falla de impresora', 'a bloquearse la computadora del puesto dos y querer imprimir del pueto uno no imprime , esto pasa cdo pasa mucho tiempo sin usar la compu del puesto dos.', 'closed', 'medium', 'Sistemas', 'DAVID VIDELA', 'medinav@idiagnostica.com.ar', 3, '2026-04-06 16:29:50.079365', '2026-04-07 08:39:24.216407', '[]', 'recepcion 1P', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (446, 'TKT-MNP3W6N2-JOC3', 'SCANNER PUESTO 1', 'SE QUEDO UN PEDAZO DE PAPEL DENTRO DE SCANNER NO FUNCIONA', 'closed', 'medium', 'Sistemas', 'DAVID VIDELA', 'cromagnoli@idiagnostica.com.ar', 3, '2026-04-07 18:03:18.696232', '2026-04-08 08:28:15.756129', '[]', 'RECEPCION 1 p', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (158, 'TKT-ML8958MR-7OFA', 'redes', 'Verifica redes en san martin, sigue mal, celus no conectan wifi ID SM

Las pc tienen bloqueos a sitios y descargas en segundo plano, sin proxy no hay internet', 'closed', 'medium', 'Sistemas', 'Sede San Martin', 'mail@mail.com', 3, '2026-02-04 13:38:49.588358', '2026-04-09 08:10:53.663053', '["/uploads/tickets/ticket-1770223129367-603444908.jpeg"]', 'sede san martin', NULL);
INSERT INTO public.tickets VALUES (449, 'TKT-MNRJIV3D-TZ09', 'puerta de ingreso de pacientes a los consultorios,', 'puerta de ingreso de pacientes a los consultorios, hace mucho ruido', 'closed', 'low', 'Mantenimiento', 'VANESA MEDINA', 'medinav@idiagnostica.com.ar', 10, '2026-04-09 10:56:23.402736', '2026-04-09 11:07:25.727939', '[]', 'recepcion primer piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (447, 'TKT-MNPYTKIS-YAOE', 'Impresora planta baja', 'IMAGENES EN TONOS BAJOS DE GRISES Y CON MOVIMIENTO', 'closed', 'medium', 'Sistemas', 'Vargas Aldana Noelia', 'aldanavargas@icloud.com', 3, '2026-04-08 08:29:04.804922', '2026-04-10 08:16:49.594092', '[]', 'Tomografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (448, 'TKT-MNQAOI1I-HJNE', 'AIRE CONGELADO', 'Uno de los aires de la sala de máquinas está congelado, se colocó en FAN, lleva más de 6 horas en FAN y sigue sin descongelarse', 'closed', 'medium', 'Mantenimiento', 'JORGELINA ARAYA', 'ninajaraya@gmail.com', 10, '2026-04-08 14:01:03.71678', '2026-04-10 08:30:49.589312', '[]', 'Resonador BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (452, 'TKT-MNSR7HQV-SWDN', 'no encienden todas las luces de recepcion en planta baja', 'estan todas prendidas pero no se cual es esa linea de luz', 'closed', 'medium', 'Mantenimiento', 'lujan claudia', 'lujanc@idiagnostica.com.ar', 10, '2026-04-10 07:19:15.994034', '2026-04-10 08:30:52.873946', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (451, 'TKT-MNRL3FQB-W4FX', 'reparar boton microhondas', 'por favor ver la posibilidad de reparar el boton de la cocina del microhondas ,', 'closed', 'low', 'Mantenimiento', 'danilo', 'barresid@idiagnostica.com.ar', 10, '2026-04-09 11:40:22.885479', '2026-04-10 10:12:53.053683', '[]', 'cocina', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (456, 'TKT-MNUA1TN2-LAKH', 'no hay sistema riss', 'se corto laluz por la tormenta, no hay Riss en san martin, no puedo cargar pacientes, arribar.', 'closed', 'medium', 'Sistemas', 'franco baigorri', 'baigorriaf@idiagnostica.com.ar', 3, '2026-04-11 08:54:30.362597', '2026-04-11 09:33:54.38514', '[]', 'sistema', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (455, 'TKT-MNTF3ORV-GW33', 'Faltan aplicaciones de osde/ impresora de tickets', 'Dsde el día de la fecha no tengo instalda Apligem y Nuvalid no se puede ingresar porque le faltan datos de ingreso.  Tampoco imprime la impresero de los tickets.', 'closed', 'medium', 'Sistemas', 'Marcelo Castro', 'castrom@idiagnostica.com.ar', 3, '2026-04-10 18:28:09.27206', '2026-04-11 09:34:24.274491', '[]', 'recepcion ecografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (453, 'TKT-MNSXEQ2P-Y37E', 'No puedo ingresar a San Martin', 'No tengo ingreso a San Martin', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-04-10 10:12:51.074473', '2026-04-11 09:34:39.582604', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (416, 'TKT-MN938CYZ-ULNO', 'PANTALLA PRIMER PISO RX ADONTOLOGICO', 'En primer piso en la pantalla para sacar numero odontologico le indica al paciente que se acerque a planta baja *MODIFICARLO*', 'closed', 'medium', 'Sistemas', 'VANESA MEDINA', 'cromagnoli@idiagnostica.com.ar', 3, '2026-03-27 13:00:28.334089', '2026-04-11 09:35:59.546987', '[]', 'recepcion 1P', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (454, 'TKT-MNT5E8R9-REBW', 'BIDON AGUA', 'BIDON AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-04-10 13:56:25.570053', '2026-04-13 08:17:57.965706', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (442, 'TKT-MNGAQXEW-8J6P', 'silla consola Tc', 'Se solicita ajustar tuerca silla consola TC', 'closed', 'low', 'Mantenimiento', 'ALDANA VARGAS', 'aldanavargas@icloud.com', 10, '2026-04-01 14:05:15.178899', '2026-04-13 08:46:46.023854', '[]', 'Tomografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (458, 'TKT-MNX9OOH9-XOO9', 'baño', 'se salio el boton del baño del eco 2.', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 11:07:35.662573', '2026-04-13 11:08:24.255715', '[]', 'eco 3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (459, 'TKT-MNX9PFX0-UIYU', 'equipo', 'ver el equipo por q saca las rx torcidas', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 11:08:11.221166', '2026-04-13 11:08:33.590825', '[]', 'dental', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (460, 'TKT-MNXBSWXK-0ZOV', 'silla', 'cambiar butaca de silla de la recepcion.', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 12:06:52.474993', '2026-04-13 12:07:06.645918', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (461, 'TKT-MNXEMGM8-10XK', 'lockes', 'cambiar la cerraduras de 2 lockers y darle las llaves al claudio', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 13:25:50.24265', '2026-04-13 13:25:59.686478', '[]', 'cocina', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (463, 'TKT-MNXHEPQD-1UL5', 'silla', 'cambiar silla tamdem de planta baja por que esta desoldada', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 14:43:47.655182', '2026-04-13 14:43:56.09417', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (464, 'TKT-MNXIOKG2-JEF0', 'silla', 'cambiar silla de vestidor', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 15:19:26.979883', '2026-04-13 15:19:35.329178', '[]', 'eco 5', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (462, 'TKT-MNXHDTHV-HBAO', 'ascensor', 'recibir al tecnico del ascensor para mantenimiento', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-13 14:43:05.877276', '2026-04-13 15:19:39.152012', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (457, 'TKT-MNX7S9LY-TCIP', 'Falla de impresora', 'Se traba la impresora', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-04-13 10:14:23.784921', '2026-04-14 08:03:55.725513', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (465, 'TKT-MNYQBBD2-RIXC', 'Estudio', 'Se cargó mal las imágenes de un estudio, por error, la Dra cargo en la paciente Garay, estudio de la paciente Lillo y a Lillo, cargó una imagen en negro.', 'closed', 'medium', 'Sistemas', 'Dra Zarza', 'mail@mail.com', 3, '2026-04-14 11:40:51.785196', '2026-04-16 08:28:52.215172', '[]', 'Ecografìa', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (450, 'TKT-MNRJNC61-SRHQ', 'Estudios salen torcidos', 'Los estudios de panorámicas o cone beam, salen torcidos milimétricamente, reportar a Newton', 'closed', 'medium', 'Sistemas', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 3, '2026-04-09 10:59:52.154003', '2026-05-09 08:19:27.144659', '[]', 'Odontología', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (445, 'TKT-MNNTFBDF-5281', 'baños publicos de recepcion', 'puerta descolgada en baño mujeres recepcion.', 'closed', 'low', 'Mantenimiento', 'pablo estrella', 'estrellap@idiagnostica.com.ar', 10, '2026-04-06 20:22:29.344408', '2026-04-14 13:11:35.285199', '["/uploads/tickets/ticket-1775517749281-144068524.jpeg"]', 'baños recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (648, 'TKT-MTRDIKNV-IH7Z', 'canaletas', 'sacar cumuló de hojas secas en canaleta del frente', 'open', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-07 12:06:26.204851', '2026-09-07 12:06:36.551653', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (466, 'TKT-MNYZ5X8P-3C4R', 'No logra escanear el equipo.', 'No logra escanear el equipo.', 'closed', 'medium', 'Sistemas', 'Marcelo Castro', 'castrom@idiagnostica.com.ar', 3, '2026-04-14 15:48:36.755454', '2026-04-15 10:21:58.160427', '[]', 'scanner recepción ecografía. Box 3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (467, 'TKT-MO04X6IT-L90A', 'tapa', 'colocar tapa en un tomacorrinte y lubricar la puerta', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-15 11:17:32.750917', '2026-04-15 11:18:41.644357', '[]', 'eco 6', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (468, 'TKT-MO04YE23-NBUL', 'acrilico', 'atornillar estructura acrilico al piso', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-15 11:18:29.165348', '2026-04-15 14:30:14.965898', '[]', 'rx', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (469, 'TKT-MO0FCRUH-ZFW9', 'AGUA BIDON', 'BIDON DE AGUA', 'closed', 'low', 'Mantenimiento', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 10, '2026-04-15 16:09:36.37973', '2026-04-16 10:19:14.203881', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (471, 'TKT-MO1TDZCU-6PL7', 'BIDON DE AGUA', 'BIDON DE AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-04-16 15:30:13.566824', '2026-04-16 15:51:53.542224', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (470, 'TKT-MO1M18HO-UI7G', 'MAIL DE FACTURACION', 'Instalación de mail de facturacion@idiagnostica.com.ar en computadora de Julieta Venturin (sede Maipú)', 'closed', 'medium', 'Sistemas', 'FACUNDO PAREDES', 'paredesf@idiagnostica.com.ar', 3, '2026-04-16 12:04:21.566113', '2026-04-17 10:19:22.673378', '[]', 'FACTURACION', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (472, 'TKT-MO344YOR-TLFS', 'cartel', 'ir a maipu a colocar una cartel en arena maipu', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-17 13:18:54.748128', '2026-04-17 13:24:13.961965', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (473, 'TKT-MO73GD05-GQE1', 'sistema de ciudad muy lento', 'hay operadores que no pueden entrar', 'closed', 'medium', 'Sistemas', 'Erica vanesa Contreras', 'contrerase@idiagnostica.com.ar', 3, '2026-04-20 08:10:51.626209', '2026-04-20 08:18:02.380874', '[]', 'ART', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (474, 'TKT-MO77MY3F-ZE5G', 'dispenser de jabon', 'avisarle a danilo que se robaron 2 dispenser de jabon en los baños de planta baja y primer piso', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-20 10:07:57.341532', '2026-04-20 10:08:06.689565', '[]', 'baño', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (147, 'TKT-ML6P7VWY-0R7K', 'Añadir cuenta POP3', 'Añadir cuenta POP3 de su mail de imagen, ya que se modificó a IMAP debido a suscripcion de microsoft 365', 'closed', 'medium', 'Sistemas', 'ENRIQUE', 'mail@mail.com', 3, '2026-02-03 11:33:14.578973', '2026-04-21 08:46:25.203259', '[]', 'Outlook enrique', NULL) ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (475, 'TKT-MO7ILXZY-4D3R', 'luz baño eco 2', 'luz baño eco 2', 'closed', 'medium', 'Mantenimiento', 'danili', 'barresid@idiagnostica.com.ar', 10, '2026-04-20 15:15:06.335974', '2026-04-21 11:39:49.001166', '[]', 'maipu', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (476, 'TKT-MO8UTIMP-OLMB', 'lubricar puerttas de maipu', 'S', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-21 13:44:41.234313', '2026-04-21 13:47:16.656649', '[]', 'lubricar puertas', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (477, 'TKT-MO8UXUP5-A7DD', 'ventilacion', 'apagar los extractores de aire de maipu', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-21 13:48:03.499343', '2026-04-21 15:22:20.520885', '[]', 'mantenimiento', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (479, 'TKT-MOAB86M3-S8JR', 'jabonera', 'reemplazar jaboneras de las cuales se robaron', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-22 14:11:45.532523', '2026-04-22 14:11:52.732483', '[]', 'planta baja', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (481, 'TKT-MOBCAKL7-EXLT', 'No puedo entrar al cuidad', 'se colgó el ingreso a ciudad', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-04-23 07:29:22.75105', '2026-04-23 08:30:34.249338', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (480, 'TKT-MOBCA71O-6ZUO', 'Sistema caído', 'No tenemos sistema para ingresar turnos o pra ver el listado por consola.', 'closed', 'medium', 'Sistemas', 'David Gutiérrez', 'davidguti1405@yahoo.com', 3, '2026-04-23 07:29:05.208833', '2026-04-23 08:30:35.53857', '[]', 'RESONADOR BAJO CAMPO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (483, 'TKT-MOBHEJO0-3XI6', 'aire de tomo', 'limpieza de aire acondicionado de tomografia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 09:52:26.259014', '2026-04-23 09:52:34.563584', '[]', 'tomo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (482, 'TKT-MOBHDL0J-GTNE', 'sala de maquinas', 'colocar cinta en los caños para que no condence el agua y gotee', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 09:51:41.347815', '2026-04-23 11:46:19.394053', '[]', 'brivo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (490, 'TKT-MOBQYACZ-03G2', 'luces escalera', 'buscar y mostrar a claudio apliques nuevos para colocar en la escalera principal para cambiar los artefactos que estan viejos', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 14:19:43.867334', '2026-04-23 14:19:55.333476', '[]', 'escalera', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (489, 'TKT-MOBQW7YV-ZE8B', 'calle', 'pintar los postes de los carteles de la vereda de blanco', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 14:18:07.448508', '2026-04-24 11:30:09.469127', '[]', 'calle', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (486, 'TKT-MOBQSYR5-GKZG', 'callle', 'pintar el cordon de la calle de colo amarillo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 14:15:35.539823', '2026-04-24 15:49:42.172743', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (488, 'TKT-MOBQUTQR-LDKR', 'pintar', 'pintar la oficina de lorena', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 14:17:02.358891', '2026-04-27 15:10:56.666044', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (478, 'TKT-MOA0DPHB-PMFV', 'Colocar el panel y zocalos faltantes en el servicio.', 'Detras del acrilico.', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-04-22 09:08:07.502181', '2026-05-05 11:39:26.917353', '[]', 'radiologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (514, 'TKT-MOVSY11V-UOW7', 'taller', 'limpieza de taller', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-07 15:10:54.548891', '2026-05-07 15:18:57.571042', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (513, 'TKT-MOVS28GD-UHLF', 'SILLA ROTA', 'RETIRAR SILLA ROTA', 'closed', 'low', 'Mantenimiento', 'David Gutiérrez', 'davidguti1405@yahoo.com', 10, '2026-05-07 14:46:11.15172', '2026-05-07 15:19:00.998217', '[]', 'Resonador Articulaciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (517, 'TKT-MOX0VYHF-JKYK', 'ordenar', 'ordenar y limpiar deposito de tanque', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-08 11:41:01.01242', '2026-05-08 11:41:16.094468', '[]', 'deposito', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (487, 'TKT-MOBQTY48-P1HK', 'baranda de rampa genera', 'pintar la baranda de genera de la vereda de color gris', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-23 14:16:21.376191', '2026-05-11 08:36:20.431418', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (518, 'TKT-MOX6NWJ4-9ITU', 'canilla', 'pegar la canilla de la cocina', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-08 14:22:42.929139', '2026-05-11 12:07:20.226903', '[]', 'cocina', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (519, 'TKT-MP16R0RV-A1JW', 'No se puede ingresar a San Martin', 'No anda la pagina', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-05-11 09:36:13.11375', '2026-05-13 08:04:54.26415', '[]', 'TRANSCIPCIÓN', 'San Martín') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (484, 'TKT-MOBJ223H-1UPP', 'Colocar tacos de goma en la camilla del eco 4', 'Colocar tacos de goma en la camilla del eco 4', 'closed', 'low', 'Mantenimiento', 'Federico Dalla Torre', 'FEDE.DALLA.TORRE@GMAIL.COM', 10, '2026-04-23 10:38:42.847758', '2026-05-20 14:34:30.935439', '[]', 'ecografo 4', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (516, 'TKT-MOX0UT6J-L7SP', 'tapicero', 'tapizar bases de sillas', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-08 11:40:07.484806', '2026-06-22 08:37:36.094722', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (515, 'TKT-MOX0U6GT-4H5T', 'tapicero', 'tapizar almohadas de resonacia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-08 11:39:38.046562', '2026-06-22 08:37:40.576871', '[]', 'reso', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (646, 'TKT-MTOIZ1S6-JMJJ', 'consolas del sistema faltantes', 'Buen dia, necesito por favor que me actualicen las consolas de medicos y equipos para poder visualizarlas. Me faltan las consolas de RM, TAC, RAYOS, Dra Rodriguez Puig, densitometria. Muchas gracias', 'closed', 'medium', 'Sistemas', 'ROMINA AZEGLIO', 'romiazeglio@gmail.com', 3, '2026-09-05 12:15:54.448928', '2026-09-07 08:06:59.230138', '[]', 'recepcion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (491, 'TKT-MOEFBN0V-W3N8', 'PEDIDO DE TECLADO BOX 2', 'LA TECLA G ESTA TRABADA', 'closed', 'medium', 'Sistemas', 'CARINA ROMAGNOLI', 'cromagnoli@idiagnostica.com.ar', 3, '2026-04-25 11:17:29.949864', '2026-04-27 08:09:11.883193', '[]', 'RECEPCION PRIMER PISO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (494, 'TKT-MOHA4FLC-VNJZ', 'aire central', 'cerrar la puerta que va al primer piso de aire', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-27 11:15:14.163079', '2026-04-27 11:21:18.963137', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (493, 'TKT-MOHA2T7G-1X05', 'calor', 'cerrar la entrada de aire calefacción en la guada', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-27 11:13:58.49695', '2026-04-27 11:21:22.970747', '[]', 'rrhh', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (496, 'TKT-MOHAQWLA-3ZQ7', 'No funciona el aire acondicionado. Ya cambié las pilas del control remoto.', 'No funciona el aire acondicionado. Ya cambié las pilas del control remoto.', 'closed', 'low', 'Mantenimiento', 'Gerardo', 'dominguezgerardomartin@gmail.com', 10, '2026-04-27 11:32:42.623689', '2026-04-27 12:04:18.190666', '[]', 'Recepción cuarto piso.', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (495, 'TKT-MOHAE3P6-JHJ0', 'sala caliente', 'se cerro las entras del aire central  se le cargo gas al split por que le faltaba.', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-27 11:22:45.307322', '2026-04-27 13:01:21.865401', '[]', 'ups', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (498, 'TKT-MOHMQ44L-JE50', 'tonner negro,impresora de eocgrafias', 'impresora de ecografias', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-04-27 17:08:01.134506', '2026-04-28 11:03:54.861966', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (502, 'TKT-MOIQSUOC-ZB9E', 'vestidor', 'se salio el riel de la puerta del vestidor y se volvio a colocar', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-28 11:49:53.485997', '2026-04-28 14:10:51.231216', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (501, 'TKT-MOIQRW97-WN9M', 'colocar camara en el ascensor', 'colocar camara en el ascensor', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-28 11:49:08.876632', '2026-04-28 15:30:33.650006', '[]', 'ascensor', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (499, 'TKT-MOIK44EH-9H0J', 'bot - expiro la contraseña', 'no puedo ingresar', 'closed', 'medium', 'Sistemas', 'carina romagnoli', 'cromagnoli@idiagnostica.com.ar', 3, '2026-04-28 08:42:41.995067', '2026-04-29 10:48:25.448918', '[]', 'primer piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (505, 'TKT-MOK879JZ-7BI1', 'vestidor', 'ajustar puerta del vestidor que se salio', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-29 12:44:45.600405', '2026-04-29 13:50:40.775129', '[]', 'eco 2', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (507, 'TKT-MOKAKQHV-KLO9', 'agua', 'agua', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-29 13:51:13.316472', '2026-04-30 11:49:52.885391', '[]', 'call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (506, 'TKT-MOK9Q0AB-HHLB', 'PUERTA', 'Hola franco, podrán levantar la puerta del cuarto de maquinas del 4to piso para que no raspe en el piso. Gracias..', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-04-29 13:27:19.670071', '2026-04-30 11:49:55.977882', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (503, 'TKT-MOJ1AWIS-78ZZ', 'Llave del cambiador numero 1', 'Esta trabada la cerradura no cierra', 'closed', 'low', 'Mantenimiento', 'ESTEFANIA GERVILLA', 'estefigervilla93@gmail.com', 10, '2026-04-28 16:43:51.854182', '2026-04-30 11:50:04.276664', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (508, 'TKT-MOLLPOTG-BUR8', 'silla', 'se salio un tornillo de la silla', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-30 11:50:46.374998', '2026-04-30 11:50:59.379311', '[]', 'tomo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (509, 'TKT-MOLQ3TS5-H5AS', 'bacha', 'destapar la bacha del primer piso', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-04-30 13:53:44.464367', '2026-04-30 15:07:54.909731', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (511, 'TKT-MOR5521J-JKCB', 'pilas', 'cambiar pilas de control de aire', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-04 08:53:26.936313', '2026-05-04 08:53:37.551297', '[]', 'eco 2', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (510, 'TKT-MOR31T6Z-4LFT', 'sensor de agua.', 'Hola franco, No funciona el sensor de flujo de agua del resonador 4t piso, y esta perdiendo agua por las juntas, cuando puedas podes verlo. Gracias.', 'closed', 'medium', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-05-04 07:54:56.302961', '2026-05-04 12:55:35.414675', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (512, 'TKT-MOVM29KQ-1HAU', 'estante', 'cambiar de lugar el dispenser de agua y colocar un estante en bajo campo para las  batas', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-07 11:58:14.907068', '2026-05-07 13:16:59.756932', '[]', 'bajo campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (504, 'TKT-MOJ2SFFM-ZKQR', 'porta lampara exterior y puerta sala de limpieza.', 'porta lampara caído en ventanal exterior del instituto.
puerta caída en sala de limpieza.', 'closed', 'low', 'Mantenimiento', 'pablo estrella', 'estrellap@idiagnostica.com.ar', 10, '2026-04-28 17:25:29.124248', '2026-05-18 12:03:02.65815', '["/uploads/tickets/ticket-1777407929029-968798183.jpeg", "/uploads/tickets/ticket-1777407929054-22472358.jpeg"]', 'exterior instituto y puerta sala de limpieza.', 'Maipú');
INSERT INTO public.tickets VALUES (500, 'TKT-MOIKFPVJ-TJQW', 'ingresos mal cargados de pacientes no puedo generar el cambio', 'Trato de hacer cambios en los estudios mal ingresados y no me deja si están pasados por la IA 
ej: paciente DNI 17012506 mal cargado el médico derivante y correcciones de fecha dentro del documento, cambio el nombre del médico lo cierro y vuelvo a abrir y no hay cambio', 'closed', 'medium', 'Sistemas', 'Monica', 'veram@idiagnostica.com.ar', 3, '2026-04-28 08:51:43.041708', '2026-06-05 08:11:53.192837', '[]', 'TRANSCIPCIÓN', 'Ciudad');
INSERT INTO public.tickets VALUES (485, 'TKT-MOBLK06O-QKWH', 'EQUIPO BRIVO RX', 'El día jueves  9/3 el equipo BRIVO DE RX comenzó a presentar anómalos durante su funcionamiento.
se observo que el sistema rotatorio (cátodo) continuaba girando luego de cada exposición sin detenerse en el tiempo habitual.
el día lunes 13 al iniciar las actividades el equipo no permitió realizar imágenes debido a que no supero el control de calidad ( QAP), indico fallas en los pixeles y bloqueo la adquisición de imágenes.
se realizaron intentos de calibración que inicialmente fueron cancelados por el sistema ,mostrando mensajes con error e inhibición de exposiciones.
finalmente se ejecuto luego de reiniciar el equipo, el proceso de calibración el cual se completo correctamente.
los valores de fallas en pixeles volvieron a niveles normales y el equipo recupero su funcionamiento.
ESTADO ACTUAL: el equipo se encuentra operativo, realizando correctamente la calibración QAP,y en distintas ocasiones aisladas el cátodo continua girando luego de una exposición.', 'closed', 'medium', 'Sistemas', 'CAMILA SIMONE', 'camisimone35197@gmail.com', 3, '2026-04-23 11:48:39.411439', '2026-06-05 08:11:55.605642', '["/uploads/tickets/ticket-1776955718945-291640086.jpeg", "/uploads/tickets/ticket-1776955718978-789555496.jpeg", "/uploads/tickets/ticket-1776955718995-897238063.jpg"]', 'RAYOS', 'Maipú');
INSERT INTO public.tickets VALUES (572, 'TKT-MRV0ZPAA-Q2JU', 'cinta hipoalergenica TRANSPORE  4 UNIDADES', '4 UNIDADES DE CINTA HIPOALERGENICA TRANSPORE
1 CAJAS DE PLACA 25*30', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-07-21 16:07:30.382063', '2026-07-22 13:43:13.176329', '[]', 'mamografia', 'Ciudad');
INSERT INTO public.tickets VALUES (595, 'TKT-MSI6LRPE-9V0F', 'hay q crgar los pacientes de manera manula', 'no funciona el worklist', 'closed', 'medium', 'Sistemas', 'Gimena Soledad Manrique Olivera', 'gimenasolmanrique@gmail.com', 3, '2026-08-06 21:03:20.0768', '2026-08-07 09:40:27.530413', '[]', 'RMN Y TAC', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (594, 'TKT-MSHDR11K-6KJE', 'worklist', 'Hola Matías no esta funcionando worklist en los resonadores y tomógrafo.
Y te pido si podes colocar las cámaras en la PC de la tuerca.
Gracias.', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-08-06 07:35:36.594099', '2026-08-07 09:40:28.685776', '[]', 'resonancia y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (520, 'TKT-MP1C53S8-JSDI', 'caldera', 'la caldera presento un error, se encontró la falla en el sensor de temperatura y se compro y remplazo el censor. ahora esta andando pero en prueba para ver si no vuelve a fallar', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-11 12:07:08.266091', '2026-05-12 08:28:16.219479', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (521, 'TKT-MP2R4MS8-FF85', 'refrigerante', 'colocar refrigerante al grupo', 'closed', 'medium', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-12 11:54:26.650805', '2026-05-12 11:54:43.1224', '[]', 'grupo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (497, 'TKT-MOHD1GGH-L5IJ', 'almohadas y ventilacion', 'Hola franco, consulta , las almohadas del brivo que llevaste a tapizar para cuando van a estar?
Hay posibilidad de colocar un difusor en el techo de la consola del brivo para poder  controlar la salida de la calefaccion.', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-04-27 12:36:54.163746', '2026-05-12 11:54:48.530327', '[]', 'resonancia', 'Ciudad');
INSERT INTO public.tickets VALUES (492, 'TKT-MOH5JU88-Q43F', 'Equipos nuevos', 'Solicito componentes para armar 2 PC nuevas en el área del call center para así dar de baja 2 equipos obsoletos que dificultan la tarea de los chicos, dejo adjunta link de carrito, consultarme para el proceso de compra ya que hay que crear cuenta.

https://compragamer.com/carro-compras?tipo=26&paso=11&cpu=8647&mother=10900&ccpu=2094&mem=19016&gab=18260&pasoCarrito=productos&listado_prod=2-8647,2-10900,2-19016&cate=15&filtros=184:DDR5&sort=lower_price', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo VIgon', 'vigonr@idiagnostica.com.ar', 11, '2026-04-27 09:07:14.903508', '2026-05-13 08:51:21.287076', '["/uploads/tickets/ticket-1777291634873-439099858.png"]', 'Call center', 'Ciudad');
INSERT INTO public.tickets VALUES (523, 'TKT-MP78CUTA-VR4B', 'agua', 'agua', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-15 15:07:48.479661', '2026-05-15 15:08:00.206065', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (522, 'TKT-MP71FJYR-H0IJ', 'focos', 'Hola franco, necesito si pueden poner un pasador del lado de adentro de la puerta del cuarto de maquinas del brivo, así no abren la puerta cuando nos estamos cambiando.
Y un foco nuevo para unos de los cambiadores del bajo campo, el que tiene no alumbra .', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-05-15 11:53:57.08643', '2026-05-18 13:31:47.652579', '[]', 'resonancia', 'Ciudad');
INSERT INTO public.tickets VALUES (525, 'TKT-MPBFA092-PHG1', 'calefacion', 'se abrio la entra de aire al primer piso por que romina reporta que hace frio', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-18 13:32:37.575302', '2026-05-18 13:33:19.619448', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (526, 'TKT-MPBFAEU4-05YI', 'bolsas', 'llevar bolsas a mamo', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-18 13:32:56.478171', '2026-05-18 13:33:26.118059', '[]', 'mamografria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (527, 'TKT-MPBPUM7E-XO5Z', 'mueble donde guardamos material de contraste. el cajon no se desplaza correctamente,, cuesta abrirlo y cerrarlo', 'cuesta abrir primer cajón de mueble donde están los contraste 
al lado de la consola', 'closed', 'low', 'Mantenimiento', 'gimena', 'gimenasolmanrique@gmail.com', 10, '2026-05-18 18:28:35.316452', '2026-05-19 12:01:10.739424', '[]', 'RMN 4to piso', 'Ciudad');
INSERT INTO public.tickets VALUES (524, 'TKT-MPB5S1YJ-MZGI', 'Rotura de cortina', 'Hola Chicos! Se rompió la cortina norte de la recepción del 4 piso.
Gracias!', 'closed', 'low', 'Mantenimiento', 'Gerardo', 'dominguezgerardomartin@gmail.com', 10, '2026-05-18 09:06:43.437337', '2026-05-19 12:01:16.36333', '[]', 'Recepción cuarto piso.', 'Ciudad');
INSERT INTO public.tickets VALUES (530, 'TKT-MPE4WU5C-0U69', 'silla de recepcion', 'silla de recepcion se cambio una base por q estaba rota', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-20 11:05:45.507427', '2026-05-20 11:05:57.606586', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (528, 'TKT-MPCRH4TZ-1DDV', 'baño', 'cambiar el sistema de descargar del baño', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-19 12:01:51.679026', '2026-05-20 11:06:01.702491', '[]', 'eco3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (531, 'TKT-MPE6WG6D-Y02K', 'puerta cambiador', 'vira metálica despegada en puerta de cambiador de tac', 'closed', 'low', 'Mantenimiento', 'Frias Diego', 'diefrias@icloud.com', 10, '2026-05-20 12:01:26.631426', '2026-05-20 13:23:29.199857', '[]', 'Tomografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (532, 'TKT-MPFF4X6C-JXQK', 'baño', 'baño de la cocina se trabo el sistema de descarga', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-21 08:39:45.015391', '2026-05-21 08:39:55.428863', '[]', 'baño', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (529, 'TKT-MPD2EL8U-2GJY', 'recambio de cartucho impresora', 'cambiar cartucho impresora recepción ecografía.', 'closed', 'medium', 'Sistemas', 'Marcelo Castro', 'castrom@idiagnostica.com.ar', 3, '2026-05-19 17:07:48.753225', '2026-05-21 09:25:53.279327', '[]', 'tonner impresora', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (533, 'TKT-MPFHIHY4-NFUX', 'filtros de aires acondicionados', 'limpieza de todos los filtros de los aires split', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-21 09:46:17.695055', '2026-05-21 10:18:37.743265', '[]', 'mantenimiento', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (534, 'TKT-MPFIPAFY-OZHD', 'cloaca', 'limpieza de cloaca', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-21 10:19:34.176584', '2026-05-21 11:42:25.992965', '[]', 'cloaca', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (535, 'TKT-MPGUWQM9-A847', 'baño', 'se trabajo el sistema de carga. limpiar y lubricar el sistema de carga', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-22 08:49:03.298517', '2026-05-22 10:14:09.938382', '[]', '2 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (537, 'TKT-MPH8QC27-M1X1', 'PUERTA', '(PICAPORTE)', 'closed', 'low', 'Mantenimiento', 'ANA', 'rubio_jonatan@yahoo.com.ar', 10, '2026-05-22 15:15:59.1345', '2026-05-23 11:18:24.158191', '[]', 'RMN 4to piso alto campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (536, 'TKT-MPH2GQC9-H503', 'cambio luz', 'pedido cambio de luz arriba de silla de Fernando Garau', 'closed', 'low', 'Mantenimiento', 'danilo', 'barresid@idiagnostica.com.ar', 10, '2026-05-22 12:20:33.380519', '2026-05-26 09:04:07.860479', '[]', 'contaduria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (538, 'TKT-MPMOLB0D-BQ6S', 'escritorio', 'cambiar los riel de 2 escritorios', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-26 10:38:49.215643', '2026-05-26 14:32:27.866772', '[]', 'call', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (539, 'TKT-MPO4HNT3-10DJ', 'terraza', 'se limpio la terraza', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-27 10:51:39.208385', '2026-05-27 15:32:30.725845', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (540, 'TKT-MPOEJNYU-5JMR', 'control de aire', 'falla en el control de aire acondicionado del 4 piso', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-05-27 15:33:08.887007', '2026-05-27 15:33:17.646579', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (541, 'TKT-MPPYPMP7-85TZ', 'termotanque y marco de chapa.', 'termotanque en sala de maestranza perdiendo agua.
marco de chapa en pasillo de baños publico, suelto.', 'closed', 'medium', 'Mantenimiento', 'pablo estrella', 'estrellap@idiagnostica.com.ar', 10, '2026-05-28 17:45:25.689009', '2026-06-02 12:09:38.860327', '["/uploads/tickets/ticket-1780001125561-254021571.jpeg", "/uploads/tickets/ticket-1780001125610-646148653.jpeg"]', 'sala de maestranza y pasillo baños publico', 'Maipú');
INSERT INTO public.tickets VALUES (543, 'TKT-MPYCVA4O-R11J', 'Se cayo es sistema de turnos', 'No se actualiza la lista de trabajo', 'closed', 'medium', 'Sistemas', 'Alejandro Montero', 'alejdromonterof@gmail.com', 3, '2026-06-03 14:43:53.361565', '2026-06-04 07:56:48.925178', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (542, 'TKT-MPWVZ90E-DJXQ', 'jabalina', 'Hola franco, el ingeniero del resonador abierto recomienda humedecer la jabalina.', 'closed', 'low', 'Mantenimiento', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 10, '2026-06-02 14:03:18.891366', '2026-06-08 08:53:46.00241', '[]', 'resonancia bajo campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (544, 'TKT-MQ5GW9YF-TMVH', 'agregar a consola servicios', 'Agregar en mi consola Tuerca y RX. También pido habilitar huela en puerta de ingreso a Brivo, Tomo, etc.', 'closed', 'medium', 'Sistemas', 'marcelo castro', 'castrom@idiagnostica.com.ar', 3, '2026-06-08 14:11:01.489432', '2026-06-16 10:35:36.378444', '[]', 'consola', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (647, 'TKT-MTR4YB7I-WLIK', 'Alarma de bajo flujo de agua', 'Alarma de bajo flujo, revisar bomba, en resonador no muestra errores', 'closed', 'medium', 'Mantenimiento', 'Javier Rios', 'jarios160@gmail.com', 10, '2026-09-07 08:06:43.903202', '2026-09-07 09:53:49.883123', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (649, 'TKT-MTRG3TXP-WSUC', 'PROBLEMA ESPECIFICO CON PACIENTE', 'Por pedido expreso de Dr Dalla Torre, revision de paciente Cauteruccio Silvia, del 07/09, doctor refiere que cuando quiere informar el codo derecho, el sistema le pone un cartel que dice que esta en proceso. En web y visual, yo lo puedo visualizar bien. Llama desde eco 2.', 'closed', 'medium', 'Sistemas', 'Javier Rios', 'jarios160@gmail.com', 3, '2026-09-07 13:18:57.230746', '2026-09-07 15:27:41.959491', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (548, 'TKT-MQIJS9NT-7QL1', 'NO PUEDO IMPRIMIR LAS RESONANCIAS', 'SE ENVIAN IMAGENES A IMPRESORA PERO NO SE IMPRIMEN', 'closed', 'medium', 'Sistemas', 'gimena', 'gimenasolmanrique@gmail.com', 3, '2026-06-17 17:52:53.643196', '2026-06-18 09:54:47.740961', '[]', 'RMN 4to piso alto campo', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (546, 'TKT-MQI2EXW5-GC0Y', 'aire frio calor', 'no funcina de forma optima el aire acondicionado en la funcion de aire caliente ,solo unos minutos calieta luedo debemos apagarlo por que larga aire frio y es el unic medio de calefaccion que tenemos en recepcion', 'closed', 'low', 'Mantenimiento', 'MARIANA ZAGO', 'zagom@idiagnostica.com.ar', 10, '2026-06-17 09:46:38.426478', '2026-06-19 09:31:06.072707', '[]', 'recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (550, 'TKT-MQJLP3E7-2Q75', 'Actualizar plotters', 'Reemplazar plotters en PB y 1 piso de los plotter para conectarse a wifi y sacar turnos', 'closed', 'low', 'Mantenimiento', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 10, '2026-06-18 11:34:10.953348', '2026-06-22 08:37:31.49122', '[]', 'Recepciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (549, 'TKT-MQJEJYXB-WEUJ', 'CAMBIO DE OFICINA', 'Rudi, buen día, el martes 23/06 necesitamos que la oficina y los puestos de facturación de Yanina y Levi pase al area dónde se encuentra ART, la idea es hacer hacerlo a las 09.30 del martes 23/06', 'closed', 'medium', 'Sistemas', 'FACUNDO PAREDES', 'paredesf@idiagnostica.com.ar', 3, '2026-06-18 08:14:14.555583', '2026-06-23 11:55:12.232596', '[]', 'facturacion', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (553, 'TKT-MQS4H6O2-NOIV', 'TONER PARA IMPRESORA DE TRANSCRIPCIÓN', 'NO SE PUEDE IMPRIMIR FALTA TONER', 'closed', 'medium', 'Compras e Insumos', 'Monica', 'veram@idiagnostica.com.ar', 11, '2026-06-24 10:42:04.054451', '2026-06-24 11:26:18.475146', '[]', 'TRANSCIPCIÓN', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (552, 'TKT-MQQWJIUB-0SOW', 'pedido', 'placas mamograficas  20*25 -  8*10 y 25*30 -10*12
gasas 10x10
jeringas 5 cc (caja)
agujas 50/8(caja)
PERVINOX FRASCO GRANDE
AGUA OXIGENADA 10 VOLUMEN (envase grande)
GEL 
TUBOS DE 15 ml  PARA CORE BIOPSIA ( 25 envases)
PORTA OBJETO 3 CAJAS  
ALGODON PAQUETE GRANDE
ALCOHOL 500ml', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-06-23 14:12:10.029035', '2026-06-24 12:05:44.043875', '[]', 'mamografia', 'Ciudad');
INSERT INTO public.tickets VALUES (551, 'TKT-MQLIP8B5-D1G1', 'puerta cocina', 'Al cerrar la puerta hace ruido, esta caida.', 'closed', 'low', 'Mantenimiento', 'ledesma estefania', 'ledesmae@idiagnostica.com.ar', 10, '2026-06-19 19:45:50.811536', '2026-06-25 08:22:35.481224', '["/uploads/tickets/ticket-1781909150739-763458119.jpeg"]', 'cocina', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (547, 'TKT-MQI3STJJ-I34X', 'canilla del baño', 'queda pegada y pierde agua.', 'closed', 'low', 'Mantenimiento', 'julieta venturin', 'venturinj@idiagnostica.com.ar', 10, '2026-06-17 10:25:25.534386', '2026-06-25 08:22:40.022174', '[]', 'sede maipu', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (554, 'TKT-MQS7QAQK-ZNMU', 'COLOCAR ACCESO A ESCANER', 'Rudi, buen dia, para el viernes 26/06 se puede colocar el acceso en el escaner en la compu fija y en la notebook por fa

Muchas gracias', 'closed', 'medium', 'Sistemas', 'FACUNDO PAREDES', 'paredesf@idiagnostica.com.ar', 3, '2026-06-24 12:13:08.061481', '2026-06-26 10:29:29.448468', '[]', 'facturacion', 'Ciudad');
INSERT INTO public.tickets VALUES (555, 'TKT-MQVFXDI3-KPMJ', 'foco quemado', 'foco quemado cerca de aire acondicionado', 'closed', 'low', 'Mantenimiento', 'gimena', 'gimenasolmanrique@gmail.com', 10, '2026-06-26 18:25:53.715022', '2026-06-27 12:22:43.781014', '[]', 'Resonador Articulaciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (556, 'TKT-MQZ5M7DX-P9T0', 'reposicion de insumos', '1 guantes s, bolsitas polip. dental,  2 cartuchos de placas 8x10, algodon, alcohol(pico delgado/punta). gasas.', 'closed', 'medium', 'Compras e Insumos', 'MARIELA', 'marielaajaya@gmail.com', 11, '2026-06-29 08:48:21.107858', '2026-07-01 09:11:49.400546', '[]', 'sala de rayos', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (558, 'TKT-MR0O2FGA-ONMB', 'PEDIDO DE INSUMOS', '30 Gadovist, 2 cajas de fisiológico, 2 cajas de guantes M, Butter 21 y 23, jeringas de 5ml y 60 ml, Jeringas de 50 pico grueso, Apósitos, 2 Descartadores, 1 Algodón, Gel, Extensores, Llaves de 3 Vías, Ultravist 300 y 370 ( 8 de cada uno), 2 paquetes de Jeringas para la Bomba y Conectores, 5 Sachet de Fisiológico de 100 ml y Alcohol (2).', 'closed', 'medium', 'Compras e Insumos', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-06-30 10:12:37.308762', '2026-07-01 12:44:29.46427', '[]', 'RMN Y TAC', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (559, 'TKT-MR2C0UEE-OSSI', 'luz quemada en pasillo central.', 'dos lamparas quemadas en pasillo central.', 'closed', 'medium', 'Mantenimiento', 'estrella pablo', 'estrellap@idiagnostica.com.ar', 10, '2026-07-01 14:11:00.328952', '2026-07-03 08:45:24.853133', '["/uploads/tickets/ticket-1782925860290-305529247.jpeg"]', 'recepcion, baño publico, consultorio, resonancia.', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (560, 'TKT-MR3HW0IP-CXJY', 'BIDON DE AGUA', 'AGUA', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-07-02 09:42:58.951941', '2026-07-03 08:45:34.010704', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (557, 'TKT-MQZ7K3XO-4KX8', 'WIFI Inestable', 'Estimado, buen día, sigo experimetando cortes en wifi en mi notebook


Aguardo comentarios

Slds', 'closed', 'medium', 'Sistemas', 'FACUNDO PAREDES', 'paredesf@idiagnostica.com.ar', 3, '2026-06-29 09:42:42.554577', '2026-07-04 08:04:52.97677', '[]', 'facturacion', 'Ciudad');
INSERT INTO public.tickets VALUES (561, 'TKT-MR9EDKF0-JJC5', 'No funciona el control/aire de la recepción del 4 piso.', 'Hola Chicos, creo que no funciona el control/aire de la recepción del 4 piso.', 'closed', 'low', 'Mantenimiento', 'Gerardo', 'dominguezgerardomartin@gmail.com', 10, '2026-07-06 12:51:16.442085', '2026-07-10 10:23:11.696778', '[]', 'Recepción cuarto piso.', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (562, 'TKT-MRJ7HUZA-M83Z', 'NO FUNCIONA EL VISUAL', 'APARECE COMO SISTEMA SUSPENDIDO, NO SE PUEDE INGRESAR A LA PAGINA', 'closed', 'medium', 'Sistemas', 'CONTRERAS ERICA VANESA', 'gestionart@idiagnostica.com.ar', 3, '2026-07-13 09:36:21.154231', '2026-07-14 08:12:46.231888', '[]', 'VISUAL', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (545, 'TKT-MQ83FOHR-K4PB', 'WIFI', 'Problemas recurrentes de red, caidas, desconexiones, mala intensidad de señal entre otros problemas que afectan el trabajo de gerencia', 'closed', 'medium', 'Sistemas', 'Rodolfo VIgon', 'itidiagnostica@gmail.com', 3, '2026-06-10 10:17:30.70391', '2026-07-15 08:07:02.887938', '[]', 'Gerencia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (566, 'TKT-MRL167AN-6LM0', 'placas', 'placas mamograficas 25x30 2 cajas', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-07-14 16:14:51.897507', '2026-07-15 12:03:48.226327', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (565, 'TKT-MRL13DWO-UXH2', 'placas de mamografia  25x30  2 cajas', 'placas mamograficas', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-07-14 16:12:40.56356', '2026-07-15 12:03:59.670575', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (564, 'TKT-MRKO116T-D4ZW', 'CARTUCHOS DE PLACAS 2', 'Reposicion de placas', 'closed', 'medium', 'Compras e Insumos', 'MARIELA', 'marielaajaya@gmail.com', 11, '2026-07-14 10:06:55.694471', '2026-07-15 12:39:39.107178', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (567, 'TKT-MRP0UWHP-Y7NP', 'Bidon agua', 'Agua', 'closed', 'low', 'Mantenimiento', 'TERESA ROMO', 'romot@idiagnostica.com.ar', 10, '2026-07-17 11:17:09.375291', '2026-07-17 11:53:59.31978', '[]', 'CALL CENTER', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (568, 'TKT-MRP27NRW-FYDP', 'terraza', 'lavar la terraza', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-07-17 11:55:04.221174', '2026-07-17 13:14:23.611254', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (570, 'TKT-MRUPPNCP-GGAU', 'caruchos de placas', '2 cartuchos de placas y bolsitas para morder', 'closed', 'medium', 'Compras e Insumos', 'mariela', 'marielaajaya@gmail.com', 11, '2026-07-21 10:51:45.549035', '2026-07-22 13:43:24.807304', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (563, 'TKT-MRKJE72F-UENK', 'pintar', 'pintar el consultorio', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-07-14 07:57:11.752903', '2026-07-23 14:42:04.524158', '[]', 'eco 3', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (571, 'TKT-MRUX49Y9-NYW9', 'materiales', 'Hola, necesito del deposito 10 gadovist, 8 ultravist 300,jeringas de 60ml pico fino, fisiológico, guantes S , LAPICERAS.
y tapones para oídos de pacientes de rmn.
saludos.', 'closed', 'medium', 'Compras e Insumos', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-07-21 14:19:05.328623', '2026-07-22 12:10:31.489263', '[]', 'resonancia y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (624, 'TKT-MTIY610Z-84JD', 'Materiales', 'Hola Dante Y Fernando.
Necesito del deposito, 
Ultravist 300 ( 4)
Gadovist 20
Temistac 4
Jeringas 5 ml y 10 ml (BRIVO)
Jeringas 50ML PICO GRUESO.
Gasas
Butter 23.
Conectores de la Bomba.
2 alcoholes.', 'closed', 'medium', 'Compras e Insumos', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-09-01 14:34:37.237797', '2026-09-08 10:48:18.926703', '[]', 'resonancia y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (575, 'TKT-MRXSVWCZ-CX9G', 'reflector', 'cambiar reflector que se daño por la lluvia', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-07-23 14:43:54.51744', '2026-07-28 08:12:33.434046', '[]', 'patio', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (574, 'TKT-MRXSV91L-UY5I', 'luz', 'cambiar plafon de vestidor de eco 2 por que hace interferencia', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-07-23 14:43:24.298254', '2026-07-28 08:12:38.325948', '[]', 'eco 2', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (577, 'TKT-MS4R67WF-BTXY', 'mochila de baño', 'mochila de baño se rompio el sistema de descarga.', 'closed', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-07-28 11:30:20.03276', '2026-07-29 09:28:04.434493', '[]', 'baño', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (580, 'TKT-MS62A8TS-4Y5A', 'luz', 'cambiar los 3 plafones de luz de recepcion primer piso', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-07-29 09:29:09.811322', '2026-07-29 12:20:04.251687', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (579, 'TKT-MS629LOS-C341', 'baño', 'baño del fondo pierde un poco de agua', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-07-29 09:28:39.822738', '2026-07-29 12:20:07.812222', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (573, 'TKT-MRXSU8UA-D9UI', 'pintura', 'pintar eco 6', 'closed', 'low', 'Mantenimiento', 'franco', 'mantenimiento@tiquetera.com', 10, '2026-07-23 14:42:37.379435', '2026-07-29 12:20:11.071514', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (578, 'TKT-MS4X69OY-5ERZ', 'materiales', 'GADOVIST 30,JERINGAS 5ML, 10 ML Y DE 60 ML PICO GRUESO.
AGUJAS 21 G, 4 CINTAS, GUANTES S Y L , 1 ALGODON.
ULTRAVIST 300 Y 307, 3 SACHET DE FISIOLOGICO-', 'closed', 'medium', 'Compras e Insumos', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-07-28 14:18:20.053027', '2026-07-29 13:24:56.290565', '[]', 'rmn y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (569, 'TKT-MRT8PQ60-8LH0', 'Computadora', 'Estimados: se suma Analia al equipo a partir del día de hoy. Necesitamos una computadora para que pueda resolver las tareas asignadas. Para ello debera contar con acceso a internet, acceso a visual en las 3 sedes, acceso al disco público y de Mkt . Aguardo comentarios.-', 'closed', 'medium', 'Sistemas', 'Lorena Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-07-20 10:08:09.541818', '2026-07-30 08:01:44.897455', '[]', 'MKT, Gestión de grillas, Call Center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (581, 'TKT-MS68G89G-7UGQ', 'estante', 'sacar estante de German', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-07-29 12:21:46.71091', '2026-07-30 13:57:39.105414', '[]', '1 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (583, 'TKT-MS7G1FHW-CTER', 'publico', 'Hola mati, podrás cargar el publico en la pc de resonador de articulaciones, y consulta tienen de casualidad algunos parlantes, los que tenemos no funcionan.
saludos', 'closed', 'medium', 'Sistemas', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 3, '2026-07-30 08:41:59.401837', '2026-07-31 08:07:41.587395', '[]', 'resonador articulaciones', 'Ciudad');
INSERT INTO public.tickets VALUES (576, 'TKT-MS358GXP-RCPM', 'Pop up', 'Sigue apareciendo el cartel del outlook en el esccritorio . Matias me paso clave pero no funcionarón. Es muy molesto trabajar con un cartel que se abre a cada rato', 'closed', 'medium', 'Sistemas', 'Lorena Andrea Menegon', 'menegonl@idiagnostica.com.ar', 3, '2026-07-27 08:28:27.327522', '2026-07-31 08:07:44.215765', '["/uploads/tickets/ticket-1785151707050-287384368.jpg"]', 'MKT, Gestión de grillas, Call Center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (586, 'TKT-MSAGJN7T-N5F6', 'Problema para cerrar estudios en el sistema de Ciudad.', 'Hola Chicos! El sistema no permite cerrar los estudios una vez terminado de tipearlo, la página dice lo siguiente.

Esta página no funciona
La página mendoza.id-estudios.com.ar no puede procesar esta solicitud ahora.
HTTP ERROR 500

El estudio no se cierra y queda bloqueado.', 'closed', 'medium', 'Sistemas', 'Gerardo', 'dominguezg@idiagnostica.com.ar', 3, '2026-08-01 11:19:27.731598', '2026-08-01 11:29:11.35818', '[]', 'Transcripción.', 'Ciudad');
INSERT INTO public.tickets VALUES (584, 'TKT-MS7KFFDG-2LNZ', 'no funciona luz led de sala', 'la luz led queda en roja o verde', 'closed', 'low', 'Mantenimiento', 'veronica', 'marielaajaya@gmail.com', 10, '2026-07-30 10:44:50.865808', '2026-08-03 12:24:42.485364', '[]', 'radiologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (585, 'TKT-MSAAL7J1-IJI8', 'SILLA RESPALDO ROTO', 'SILLA ROTA', 'closed', 'low', 'Mantenimiento', 'Gimena Soledad Manrique Olivera', 'gimenasolmanrique@gmail.com', 10, '2026-08-01 08:32:42.976587', '2026-08-04 15:37:31.921245', '[]', 'RESONADOR BRIVO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (590, 'TKT-MSF04TKE-WEZE', 'aire', 'sala de ups esta con temperatura alta. se le cargo gas al aire acondicionado', 'closed', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-08-04 15:38:53.103428', '2026-08-04 15:39:01.668153', '[]', 'ups', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (588, 'TKT-MSEOOPTA-Z1M9', 'Solicito insumos', '2 cajas de placas', 'closed', 'medium', 'Compras e Insumos', 'Andrea Duran', 'belu29326@gmail.com', 11, '2026-08-04 10:18:25.969681', '2026-08-05 09:07:26.14454', '[]', 'Odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (592, 'TKT-MSG8N2JR-CM7G', 'baño', 'baño de 4 piso pierde agua', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-08-05 12:24:47.664861', '2026-08-05 12:53:19.258651', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (589, 'TKT-MSET99PT-SLHO', 'imsumos semanales', '* 20 Gadovist
* butter 23 y 21 
* jeringa 5 y 10 ml
* 1 alcohol
* tapones para oídos 
* Jeringas p/bomba inyectora y conectores nuevos.
* 10 ultravist 300
* Llaves de 3 vías', 'closed', 'medium', 'Compras e Insumos', 'Rubio Jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-08-04 12:26:23.351401', '2026-08-05 14:03:08.709043', '[]', 'resonancia y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (587, 'TKT-MSDQ4H1P-DWK5', 'LIBRERIA', '2 MARCADORES INDELEBLE NEGRA
LAPICE RAS
 AZUL 1
NEGRA 1', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 11, '2026-08-03 18:10:54.552061', '2026-08-05 14:03:18.810725', '[]', 'mamografia', 'Ciudad');
INSERT INTO public.tickets VALUES (582, 'TKT-MS6M6W9Y-GXG0', 'JERINGAS  5 ML  UNA CAJA', 'JERINGAS   5 ml        1 caja x100
curitas                           1 caja
placas 25x30 mamografia    1 caja', 'closed', 'medium', 'Compras e Insumos', 'María del Carmen', 'mdelcherreragodoy@gmail.com.ar', 11, '2026-07-29 18:46:25.905065', '2026-08-05 14:03:29.793599', '[]', 'mamografia', 'Ciudad');
INSERT INTO public.tickets VALUES (596, 'TKT-MSIVPRI7-CTKF', 'reposicion de agua', 'reponer agua', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-08-07 08:46:16.892709', '2026-08-10 14:47:02.466571', '[]', 'radiologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (591, 'TKT-MSG5ISY6-6R83', 'se corto una de las cadenas par asubir bajar las cortinas', 'al subir una de las cortinas de corto la cadena', 'closed', 'low', 'Mantenimiento', 'MARIANA ZAGO', 'zagom@idiagnostica.com.ar', 10, '2026-08-05 10:57:29.745124', '2026-08-10 14:47:07.838861', '[]', 'recepcion', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (597, 'TKT-MSIVR8YQ-HVGM', 'cableado', 'organizar el cableado de las computadoras de rayos para que no esten en el piso y mejorar los tomas', 'closed', 'low', 'Mantenimiento', 'mariela', 'marielaajaya@gmail.com', 10, '2026-08-07 08:47:26.125138', '2026-08-31 09:25:25.696318', '[]', 'radiologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (622, 'TKT-MTIX2E44-E4S7', 'mal olor', 'cristina hablo con el encargado de el mall de maipu y localizaron el respiradero atras del local.', 'closed', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-01 14:03:47.957499', '2026-09-01 14:04:00.575989', '[]', 'mantenimiento', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (593, 'TKT-MSGBMI8L-74KQ', 'puerta cambuiador de TAC. puerta entrada. cortinas de recepcion. cartel de IMAGEN afuera.', 'puerta del cambiador de TAC (riel flojo)
puerta de entrada (pestillo trabado abajo)
cortinas de ventanales recepcion (2 cortadas)
letrero exterior de IMAGEN DIAGNOSTICA (el punto de la I caido)', 'closed', 'medium', 'Mantenimiento', 'estrella pablo', 'estrellap@idiagnostica.com.ar', 10, '2026-08-05 13:48:20.185486', '2026-08-10 14:46:55.183002', '["/uploads/tickets/ticket-1785948499626-442695771.jpeg", "/uploads/tickets/ticket-1785948499764-384385859.jpeg", "/uploads/tickets/ticket-1785948500105-161463288.jpeg"]', 'recepcion, baño publico, consultorio, resonancia.', 'Maipú');
INSERT INTO public.tickets VALUES (650, 'TKT-MTSN1AG6-OQ73', 'PLACAS', '2 CARTUCHOS DE PLACAS', 'open', 'medium', 'Compras e Insumos', 'MARIELA', 'marielaajaya@gmail.com', 11, '2026-09-08 09:20:42.151803', '2026-09-08 09:20:42.151803', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (651, 'TKT-MTSNCCEK-JMAY', 'no se ve el publico', 'no se ve el publico', 'closed', 'low', 'Sistemas', 'gaston renalias', 'renaliasg@idiagnostica.com.ar', 3, '2026-09-08 09:29:17.902976', '2026-09-08 09:32:05.909197', '[]', 'call center', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (617, 'TKT-MTILRQ5B-PT6F', 'placas', '2 cartuchos de placas.', 'closed', 'medium', 'Compras e Insumos', 'mariela', 'marielaajaya@gmail.com', 11, '2026-09-01 08:47:34.600915', '2026-09-08 10:46:50.522598', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (599, 'TKT-MSOPS75S-OHSX', 'placas', '2 cartuchos de placas', 'closed', 'medium', 'Compras e Insumos', 'MARIELA', 'marielaajaya@gmail.com', 11, '2026-08-11 10:46:49.802381', '2026-08-12 12:37:51.652019', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (598, 'TKT-MSNOG496-KBO1', 'sin cámaras', 'No podemos visualizar si hay pacientes en la sala de espera.', 'closed', 'medium', 'Sistemas', 'Ana Bautista', 'rubio_jonatan@yahoo.com.ar', 3, '2026-08-10 17:21:40.371693', '2026-08-13 08:04:47.336704', '[]', 'RMN 4to piso (articulaciones)', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (601, 'TKT-MSP2SC4Z-D95M', 'no funciona worklist', 'ingresamos paciente de manera manual', 'closed', 'medium', 'Sistemas', 'gimena manrique', 'gimenasolmanrique@gmail.com', 3, '2026-08-11 16:50:51.262378', '2026-08-13 08:52:33.237261', '[]', 'resonancia y tac', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (603, 'TKT-MSRRLPRT-7138', 'ALTA TEMP EN SALA DE MAQUINA DE BRIVO', 'Mucho calor en sala de maquinas en BRIVO', 'closed', 'medium', 'Mantenimiento', 'Javier', 'jarios160@gmail.com', 10, '2026-08-13 14:01:05.093259', '2026-08-14 09:57:09.253398', '[]', 'resonancia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (600, 'TKT-MSOT5UIP-RYKX', 'gotera', 'goteaba el techo de los chicos de sistema. se abrio el techo y era un caño del baño de arraiba que se habia corrido y perdia.
se corrigio', 'closed', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-08-11 12:21:25.44318', '2026-08-14 09:57:13.336061', '[]', 'sistema', 'Ciudad');
INSERT INTO public.tickets VALUES (606, 'TKT-MT0OC705-7V6R', 'ARREGLAR BANQUETA DEL VESTIDOR', 'SE SOLTARON DOS DE LOS 3 TORNILLOS. INESTABLE', 'closed', 'low', 'Mantenimiento', 'NATALIA JUAREZ', 'nataliajuarezviajes@gmail.com', 10, '2026-08-19 19:39:37.600673', '2026-08-20 08:42:45.072182', '[]', 'DENSITOMETRIA', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (604, 'TKT-MSYV01KY-XWCE', 'pedido', 'TAC: 14 ULTRAVIST 300, SOLUCION FISIOLOGICA ( AMPOLLAS) Y ABOCATH 20 ( ROSADO)

RMN: 30 GADOVIST, JERINGAS DE 5ML Y DE 10 ML, 3 DESCARTADORES, 10 APOSITOS, 2 ALCOHOLES, 4 CINTAS.
AGUJAS 21 G
TAPONES PARA LOS OIDOS.
NOTA: EL JUEVES Y HOY MARTES PEDI A DANTE 26 GADOVIST EN TOTAL.', 'closed', 'medium', 'Compras e Insumos', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-08-18 13:10:35.652154', '2026-08-21 08:51:49.589258', '[]', 'resonancia y tac', 'Ciudad');
INSERT INTO public.tickets VALUES (611, 'TKT-MT8QP12U-4OUA', 'No hay pase de imagenes del RMN a sistema de visualizacion.', 'No pasan imagenes.
No refresca worklist', 'closed', 'medium', 'Sistemas', 'Javier Rios', 'jarios160@gmail.com', 3, '2026-08-25 11:07:45.168037', '2026-08-26 08:03:58.6723', '[]', 'RMN (Brivo)', 'Ciudad');
INSERT INTO public.tickets VALUES (610, 'TKT-MT8O3GYV-QP2M', 'problema de poco espacio en la cpu', 'no funciona la cpu para hacer pdf de estudios', 'closed', 'medium', 'Sistemas', 'MARIELA', 'marielaajaya@gmail.com', 3, '2026-08-25 09:55:00.082855', '2026-08-26 08:04:15.730637', '[]', 'densitometria', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (613, 'TKT-MTA6SMM2-NT8V', 'perdida de agua en baño', 'perdia la canilla de agua en el baño del 4 piso resonador. se compro repuesto y se remplazo', 'closed', 'medium', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-08-26 11:26:12.988962', '2026-08-26 11:26:18.791026', '[]', '4 piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (612, 'TKT-MT8XM1AA-VPDO', 'materiales', 'Hola , necesito del deposito 12 gadovist, 4 cintas, 2 aguas oxigenadas, ultravis 370 (10) jeringas de 50 ml pico fino, llaves de 3 vías, barbijos, guantes S y M.', 'closed', 'medium', 'Compras e Insumos', 'jonatan', 'rubio_jonatan@yahoo.com.ar', 11, '2026-08-25 14:21:22.763267', '2026-08-26 12:48:26.551293', '[]', 'RMN Y TAC', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (608, 'TKT-MT79MEFK-Z88Y', 'PLACAS', '2 CARTUCHOS DE PLACAS Y BOLSITAS PARA MORDER', 'closed', 'medium', 'Compras e Insumos', 'MARIELA', 'marielaajaya@gmail.com', 11, '2026-08-24 10:22:02.771093', '2026-08-26 12:48:36.252815', '[]', 'odontologia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (614, 'TKT-MTALNHX3-OGZQ', 'MAMOGRAFO', 'FALLO EL MAMOGRAFO, POR FAVOR REVISAR EL LIQUIDO REFRIGERANTE DEL GABINETE,LA LEYENDA DICE ERROR DEL BRAZO.RX NO PREPARADO. ENCEDI Y APAGUE .SIGUIO FUNCIONANADO NORMAL.', 'closed', 'low', 'Mantenimiento', 'María del Carmen', 'mdelcherreragodoy@gmail.com', 10, '2026-08-26 18:22:07.873273', '2026-08-28 11:45:56.471169', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (609, 'TKT-MT8M1Z6A-C1QD', 'CORREO', 'NO FUNCIONA EL CORREO, NO SALEN NI ENTRAN CORREOS, YA DI AVISO TELEFONICO A LAS 8:19 HS, AUN NO HAY SOLUCION.', 'closed', 'medium', 'Sistemas', 'Vanesa Contreras', 'contrerase@idiagnostica.com.ar', 3, '2026-08-25 08:57:51.068863', '2026-08-29 08:14:52.156982', '[]', 'CORREO', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (607, 'TKT-MT755ED8-T33Y', 'impresora hp11002', 'la impresora no funciona, las hojas se atascan', 'closed', 'medium', 'Sistemas', 'CARINA ROMAGNOLI', 'cromagnoli@idiagnostica.com.ar', 3, '2026-08-24 08:16:51.159964', '2026-08-29 08:49:53.441831', '[]', 'recepcion pb', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (615, 'TKT-MTHCH9QD-PF1E', 'PILAS', 'PILAS', 'closed', 'low', 'Mantenimiento', 'DANTE', 'canasad@idiagnostica.com.ar', 10, '2026-08-31 11:39:44.017325', '2026-08-31 14:06:31.23619', '[]', 'CONTADURIA', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (616, 'TKT-MTHHRYZL-0J8L', 'DISPENSER DE ALCOHOL', 'Reparación dispenser de alcohol de entrada sede Necochea', 'closed', 'low', 'Mantenimiento', 'MATIAS', 'matiasbelluco@gmail.com', 10, '2026-08-31 14:08:01.380246', '2026-08-31 14:44:38.519325', '["/uploads/tickets/ticket-1788196081370-813702751.jpeg"]', 'Gerencia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (620, 'TKT-MTISREK0-2F2X', 'Cerradura Puerta', 'Se traba la cerradura de la puerta de vidrio de la oficina.', 'closed', 'low', 'Mantenimiento', 'GERMAN VIGON', 'vigong@idiagnostica.com.ar', 10, '2026-09-01 12:03:16.859577', '2026-09-01 13:32:10.245716', '[]', 'GESTION DE GRILLAS-CHEQUEOS', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (621, 'TKT-MTIX0F8F-CP9K', 'bolsas', 'subir las bosas que llegaron', 'closed', 'low', 'Mantenimiento', 'franco ortiz', 'mantenimiento@tiquetera.com', 10, '2026-09-01 14:02:16.096398', '2026-09-01 14:02:24.462581', '[]', 'planta baja', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (623, 'TKT-MTIXU2DG-ZXPC', 'agujas core biopsia 14ga x 10', 'quedan en el consultorio del Dr Tercero 9 agujas, gracias!!', 'open', 'medium', 'Compras e Insumos', 'MARIA DEL CARMEN HERRERA', 'mdelcherreragodoy@gmail.com', 11, '2026-09-01 14:25:19.110502', '2026-09-01 14:25:19.110502', '[]', 'mamografia', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (605, 'TKT-MSYXKWXE-Z2XV', 'estamos sin camaras', 'no tenemos cámaras, no podemos ver si hay gente en la sala', 'closed', 'medium', 'Sistemas', 'gimena', 'gimenasolmanrique@gmail.com', 3, '2026-08-18 14:22:48.629085', '2026-09-02 08:48:25.115619', '[]', 'Resonador Articulaciones', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (630, 'TKT-MTK0YWCA-6M2K', 'esta rota la tapa del inodoro', 'se rompió la tapa del inodoro del baño del 4t0 piso.,', 'closed', 'low', 'Mantenimiento', 'cecilia alfaro', 'chechualf@gmail.com', 10, '2026-09-02 08:40:49.595704', '2026-09-03 14:20:51.837511', '[]', 'RMN 4to piso', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (652, 'TKT-MTSP7PNW-YWOA', 'Cable USB para lamparas de escritorio', 'Comprar cables de USB, de un largo de 1.5 o 2 m de largo para las lámparas de escritorio de los ecógrafos, porque los que tienen quedan cortos para la CPU y está conectado al ecografo y si se mueve el ecografo se cae la lampara', 'open', 'medium', 'Mantenimiento', 'FEDERICO DALLA TORRE', 'fede.dalla.torre@gmail.com', 10, '2026-09-08 10:21:41.038155', '2026-09-08 10:21:41.038155', '[]', 'ecografia', 'Maipú') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (602, 'TKT-MSRGOL6A-63N2', 'Compra Batería', 'Batería de HP 240 de Lorena Menegon presenta problemas de retención de carga, debe usarla conectada para que funcione, su cargador es nuevo y de todas maneras no carga.

Opción ML -> https://www.mercadolibre.com.ar/bateria-para-hp-pavilion-240-g7-246-g7-250-g7-255-g7-ht03xl/up/MLAU3548060802?pdp_filters=item_id:MLA2550349632#is_advertising=true&searchVariation=MLAU3548060802&backend_model=search-backend;EQ:BATERIA%20HT03XL%20HP%20240%20G7;EQ:BATERIA%20HP%20PAVILION;EQ:BATERIA%20HT03XL%20HP%20250%20G7&be_origin=backend&position=1&search_layout=grid&type=pad&tracking_id=f95e49f3-5e39-436a-ac44-5b9e378220f2&ad_domain=VQCATCORE_LST&ad_position=1&ad_click_id=ZjAzNTU3OWUtZWJiNy00MDAyLTlmNzMtMDY0ODZkZjBmMGNi', 'closed', 'medium', 'Compras e Insumos', 'Rodolfo VIgon', 'itidiagnostica@gmail.com', 11, '2026-08-13 08:55:23.325911', '2026-09-08 10:30:40.580738', '[]', 'Marketing', 'Ciudad');
INSERT INTO public.tickets VALUES (619, 'TKT-MTIQ67PM-XFSQ', 'mouse', 'Hola Matías, necesito si podes cambiar el mause del resonador abierto que esta fallando, ayer le comentamos al Ingeniero y nos aconsejo reemplazarlo.', 'closed', 'medium', 'Sistemas', 'JONATAN', 'rubio_jonatan@yahoo.com.ar', 3, '2026-09-01 10:50:48.982986', '2026-09-02 08:32:44.335752', '[]', 'rmn abierto', 'Ciudad') ON CONFLICT DO NOTHING;
INSERT INTO public.tickets VALUES (618, 'TKT-MTIM92C5-L512', 'Prevención salud', 'colocar por favor para la obra social prevención que sea obligatorio poner el número de referencia en la recepción del paciente. Gracias', 'closed', 'medium', 'Sistemas', 'julieta venturin', 'venturinj@idiagnostica.com.ar', 3, '2026-09-01 09:01:03.520439', '2026-09-02 09:15:23.667535', '[]', 'facturacion', 'Maipú') ON CONFLICT DO NOTHING;


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.users VALUES (5, 'rrhh@tiquetera.com', '$2a$08$cef5RxuJyWnJiQa0jjn8m.9yyOoxbiKAldQQvPWlm7UWrCP5g/T6a', 'Recursos Humanos', 'rrhh', 'Recursos Humanos', '2025-11-13 22:48:31.608951', false) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (6, 'contact@tiquetera.com', '$2a$08$cef5RxuJyWnJiQa0jjn8m.9yyOoxbiKAldQQvPWlm7UWrCP5g/T6a', 'Contact Center', 'contact', 'Contact Center', '2025-11-13 22:48:31.654418', false) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (3, 'soporte@tiquetera.com', '$2a$08$s6zCOkpIb5HenzOCddWKHeV0einbosR.Xy747dqThVoOkrbOIZ9N.', 'Sistemas', 'support', 'Sistemas', '2025-11-13 22:48:31.512116', true) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (11, 'compras@tiquetera.com', '$2a$08$P8.4w/EF2cHAp9JHuE1Mj.TnJ0Foq5TCb3tb9gYErU.Bnd6jW8q8G', 'Compras e Insumos', 'compras', 'Compras e Insumos', '2026-01-16 13:35:38.603657', true) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (4, 'facturacion@tiquetera.com', '$2a$08$cef5RxuJyWnJiQa0jjn8m.9yyOoxbiKAldQQvPWlm7UWrCP5g/T6a', 'Facturación', 'facturacion', 'Facturación', '2025-11-13 22:48:31.565566', true) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (2, 'gerencia@tiquetera.com', '$2a$08$cef5RxuJyWnJiQa0jjn8m.9yyOoxbiKAldQQvPWlm7UWrCP5g/T6a', 'Gerencia', 'gerencia', NULL, '2025-11-13 22:48:31.475669', true) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (1, 'admin@tiquetera.com', '$2a$08$GeoDE5HAQBKPRH28c1Cyv.p01zne.tjD3qMU6x56zK7SoO0nPeG3C', 'Administrador', 'administrador', NULL, '2025-11-13 22:48:31.442972', true) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (10, 'mantenimiento@tiquetera.com', '$2a$08$1nOGzX3aceAnDcBt3Lm2Feyg8On1jpy5YaHYxKAQ8Yx2XiSIIJRcS', 'Mantenimiento', 'mantenimiento', 'Mantenimiento', '2026-01-16 13:35:38.586054', true) ON CONFLICT DO NOTHING;
INSERT INTO public.users VALUES (12, 'support@tiquetera.com', '$2a$08$cef5RxuJyWnJiQa0jjn8m.9yyOoxbiKAldQQvPWlm7UWrCP5g/T6a', 'support', 'rrhh', 'Soporte', '2026-08-29 11:45:25.48066', false) ON CONFLICT DO NOTHING;


--
-- Name: audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.audit_log_id_seq', 626, true);


--
-- Name: maintenance_tasks_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.maintenance_tasks_id_seq', 182, true);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1155, true);


--
-- Name: push_metrics_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.push_metrics_id_seq', 1, false);


--
-- Name: push_subscriptions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.push_subscriptions_id_seq', 1, false);


--
-- Name: shared_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shared_reports_id_seq', 8, true);


--
-- Name: shared_tasks_boards_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.shared_tasks_boards_id_seq', 36, true);


--
-- Name: ticket_updates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ticket_updates_id_seq', 282, true);


--
-- Name: tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tickets_id_seq', 653, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.users_id_seq', 12, true);


--
-- Name: audit_log audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_pkey;
ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_pkey PRIMARY KEY (id);


--
-- Name: maintenance_tasks maintenance_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tasks DROP CONSTRAINT IF EXISTS maintenance_tasks_pkey;
ALTER TABLE ONLY public.maintenance_tasks
    ADD CONSTRAINT maintenance_tasks_pkey PRIMARY KEY (id);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: push_metrics push_metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_metrics DROP CONSTRAINT IF EXISTS push_metrics_pkey;
ALTER TABLE ONLY public.push_metrics
    ADD CONSTRAINT push_metrics_pkey PRIMARY KEY (id);


--
-- Name: push_subscriptions push_subscriptions_endpoint_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions DROP CONSTRAINT IF EXISTS push_subscriptions_endpoint_key;
ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_endpoint_key UNIQUE (endpoint);


--
-- Name: push_subscriptions push_subscriptions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions DROP CONSTRAINT IF EXISTS push_subscriptions_pkey;
ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_pkey PRIMARY KEY (id);


--
-- Name: report_cache report_cache_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.report_cache DROP CONSTRAINT IF EXISTS report_cache_pkey;
ALTER TABLE ONLY public.report_cache
    ADD CONSTRAINT report_cache_pkey PRIMARY KEY (cache_key);


--
-- Name: shared_reports shared_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_reports DROP CONSTRAINT IF EXISTS shared_reports_pkey;
ALTER TABLE ONLY public.shared_reports
    ADD CONSTRAINT shared_reports_pkey PRIMARY KEY (id);


--
-- Name: shared_reports shared_reports_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_reports DROP CONSTRAINT IF EXISTS shared_reports_token_key;
ALTER TABLE ONLY public.shared_reports
    ADD CONSTRAINT shared_reports_token_key UNIQUE (token);


--
-- Name: shared_tasks_boards shared_tasks_boards_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_tasks_boards DROP CONSTRAINT IF EXISTS shared_tasks_boards_pkey;
ALTER TABLE ONLY public.shared_tasks_boards
    ADD CONSTRAINT shared_tasks_boards_pkey PRIMARY KEY (id);


--
-- Name: shared_tasks_boards shared_tasks_boards_token_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_tasks_boards DROP CONSTRAINT IF EXISTS shared_tasks_boards_token_key;
ALTER TABLE ONLY public.shared_tasks_boards
    ADD CONSTRAINT shared_tasks_boards_token_key UNIQUE (token);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.system_config DROP CONSTRAINT IF EXISTS system_config_pkey;
ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (key);


--
-- Name: ticket_updates ticket_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_updates DROP CONSTRAINT IF EXISTS ticket_updates_pkey;
ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT ticket_updates_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets DROP CONSTRAINT IF EXISTS tickets_pkey;
ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_tracking_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets DROP CONSTRAINT IF EXISTS tickets_tracking_id_key;
ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_tracking_id_key UNIQUE (tracking_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_audit_log_created; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_audit_log_created ON public.audit_log USING btree (created_at DESC);


--
-- Name: idx_audit_log_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_audit_log_user ON public.audit_log USING btree (user_id);


--
-- Name: idx_maintenance_tasks_assigned; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_assigned ON public.maintenance_tasks USING btree (assigned_to);


--
-- Name: idx_maintenance_tasks_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_department ON public.maintenance_tasks USING btree (department);


--
-- Name: idx_maintenance_tasks_recurring; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_recurring ON public.maintenance_tasks USING btree (is_recurring, recurrence_interval);


--
-- Name: idx_maintenance_tasks_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_maintenance_tasks_status ON public.maintenance_tasks USING btree (status);


--
-- Name: idx_notifications_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications USING btree (created_at DESC);


--
-- Name: idx_notifications_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_notifications_department ON public.notifications USING btree (department);


--
-- Name: idx_notifications_is_read; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications USING btree (is_read);


--
-- Name: idx_push_subscriptions_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_department ON public.push_subscriptions USING btree (department);


--
-- Name: idx_push_subscriptions_user; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_push_subscriptions_user ON public.push_subscriptions USING btree (user_id);


--
-- Name: idx_report_cache_expires; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_report_cache_expires ON public.report_cache USING btree (expires_at);


--
-- Name: idx_shared_reports_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_shared_reports_active ON public.shared_reports USING btree (is_active);


--
-- Name: idx_shared_reports_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_shared_reports_token ON public.shared_reports USING btree (token);


--
-- Name: idx_shared_tasks_boards_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_shared_tasks_boards_token ON public.shared_tasks_boards USING btree (token);


--
-- Name: idx_ticket_updates_ticket_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_ticket_updates_ticket_id ON public.ticket_updates USING btree (ticket_id);


--
-- Name: idx_tickets_assigned_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_assigned_to ON public.tickets USING btree (assigned_to);


--
-- Name: idx_tickets_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_created_at ON public.tickets USING btree (created_at DESC);


--
-- Name: idx_tickets_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_department ON public.tickets USING btree (department);


--
-- Name: idx_tickets_priority; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_priority ON public.tickets USING btree (priority);


--
-- Name: idx_tickets_sede; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_sede ON public.tickets USING btree (sede);


--
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_status ON public.tickets USING btree (status);


--
-- Name: idx_tickets_tracking_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_tickets_tracking_id ON public.tickets USING btree (tracking_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX IF NOT EXISTS idx_users_role ON public.users USING btree (role);


--
-- Name: tickets update_tickets_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

DROP TRIGGER IF EXISTS update_tickets_updated_at ON public.tickets;
CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: audit_log audit_log_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.audit_log DROP CONSTRAINT IF EXISTS audit_log_user_id_fkey;
ALTER TABLE ONLY public.audit_log
    ADD CONSTRAINT audit_log_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: maintenance_tasks maintenance_tasks_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tasks DROP CONSTRAINT IF EXISTS maintenance_tasks_assigned_to_fkey;
ALTER TABLE ONLY public.maintenance_tasks
    ADD CONSTRAINT maintenance_tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: maintenance_tasks maintenance_tasks_completed_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tasks DROP CONSTRAINT IF EXISTS maintenance_tasks_completed_by_fkey;
ALTER TABLE ONLY public.maintenance_tasks
    ADD CONSTRAINT maintenance_tasks_completed_by_fkey FOREIGN KEY (completed_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: maintenance_tasks maintenance_tasks_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.maintenance_tasks DROP CONSTRAINT IF EXISTS maintenance_tasks_created_by_fkey;
ALTER TABLE ONLY public.maintenance_tasks
    ADD CONSTRAINT maintenance_tasks_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_read_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_read_by_fkey;
ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_read_by_fkey FOREIGN KEY (read_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: notifications notifications_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_ticket_id_fkey;
ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- Name: push_metrics push_metrics_subscription_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_metrics DROP CONSTRAINT IF EXISTS push_metrics_subscription_id_fkey;
ALTER TABLE ONLY public.push_metrics
    ADD CONSTRAINT push_metrics_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES public.push_subscriptions(id) ON DELETE CASCADE;


--
-- Name: push_subscriptions push_subscriptions_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.push_subscriptions DROP CONSTRAINT IF EXISTS push_subscriptions_user_id_fkey;
ALTER TABLE ONLY public.push_subscriptions
    ADD CONSTRAINT push_subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: shared_reports shared_reports_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_reports DROP CONSTRAINT IF EXISTS shared_reports_created_by_fkey;
ALTER TABLE ONLY public.shared_reports
    ADD CONSTRAINT shared_reports_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: shared_tasks_boards shared_tasks_boards_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.shared_tasks_boards DROP CONSTRAINT IF EXISTS shared_tasks_boards_created_by_fkey;
ALTER TABLE ONLY public.shared_tasks_boards
    ADD CONSTRAINT shared_tasks_boards_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: ticket_updates ticket_updates_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_updates DROP CONSTRAINT IF EXISTS ticket_updates_ticket_id_fkey;
ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT ticket_updates_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- Name: ticket_updates ticket_updates_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ticket_updates DROP CONSTRAINT IF EXISTS ticket_updates_user_id_fkey;
ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT ticket_updates_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tickets tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tickets DROP CONSTRAINT IF EXISTS tickets_assigned_to_fkey;
ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--


