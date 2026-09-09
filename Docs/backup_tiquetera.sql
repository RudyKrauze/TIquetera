--
-- PostgreSQL database dump
--

\restrict ePaYOLen4NpLHWmVq9er44rvoaPTAOM4uzm4lu0je45ACobQ1w3i3bDWUCFWKrL

-- Dumped from database version 16.10 (Debian 16.10-1.pgdg13+1)
-- Dumped by pg_dump version 16.10 (Debian 16.10-1.pgdg13+1)

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
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: ticket_app
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO ticket_app;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: system_config; Type: TABLE; Schema: public; Owner: ticket_app
--

CREATE TABLE public.system_config (
    key character varying(255) NOT NULL,
    value text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.system_config OWNER TO ticket_app;

--
-- Name: ticket_updates; Type: TABLE; Schema: public; Owner: ticket_app
--

CREATE TABLE public.ticket_updates (
    id integer NOT NULL,
    ticket_id integer NOT NULL,
    user_id integer,
    update_type character varying(50) DEFAULT 'comment'::character varying,
    content text NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.ticket_updates OWNER TO ticket_app;

--
-- Name: ticket_updates_id_seq; Type: SEQUENCE; Schema: public; Owner: ticket_app
--

CREATE SEQUENCE public.ticket_updates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ticket_updates_id_seq OWNER TO ticket_app;

--
-- Name: ticket_updates_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ticket_app
--

ALTER SEQUENCE public.ticket_updates_id_seq OWNED BY public.ticket_updates.id;


--
-- Name: tickets; Type: TABLE; Schema: public; Owner: ticket_app
--

CREATE TABLE public.tickets (
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
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tickets OWNER TO ticket_app;

--
-- Name: tickets_id_seq; Type: SEQUENCE; Schema: public; Owner: ticket_app
--

CREATE SEQUENCE public.tickets_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tickets_id_seq OWNER TO ticket_app;

--
-- Name: tickets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ticket_app
--

ALTER SEQUENCE public.tickets_id_seq OWNED BY public.tickets.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: ticket_app
--

CREATE TABLE public.users (
    id integer NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    role character varying(50) DEFAULT 'support'::character varying NOT NULL,
    department character varying(255),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.users OWNER TO ticket_app;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: ticket_app
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_id_seq OWNER TO ticket_app;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: ticket_app
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: ticket_updates id; Type: DEFAULT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.ticket_updates ALTER COLUMN id SET DEFAULT nextval('public.ticket_updates_id_seq'::regclass);


--
-- Name: tickets id; Type: DEFAULT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.tickets ALTER COLUMN id SET DEFAULT nextval('public.tickets_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Data for Name: system_config; Type: TABLE DATA; Schema: public; Owner: ticket_app
--

COPY public.system_config (key, value, created_at) FROM stdin;
default_users_created	true	2025-11-13 22:48:31.692368
\.


--
-- Data for Name: ticket_updates; Type: TABLE DATA; Schema: public; Owner: ticket_app
--

COPY public.ticket_updates (id, ticket_id, user_id, update_type, content, created_at) FROM stdin;
\.


--
-- Data for Name: tickets; Type: TABLE DATA; Schema: public; Owner: ticket_app
--

COPY public.tickets (id, tracking_id, title, description, status, priority, department, created_by_name, created_by_email, assigned_to, created_at, updated_at) FROM stdin;
1	TKT-MHY2WQ2A-XJC4	vbnvbnvb	vbnvbn	closed	medium	General	yhgfnvbn		3	2025-11-13 23:47:25.817822	2025-11-18 01:33:17.658822
14	TKT-MI3LMPMZ-IC2X	Ticket de prueba #13	Descripción de prueba #13	open	medium	Soporte	Usuario Prueba	prueba13@example.com	3	2025-11-17 20:30:22.284224	2025-11-18 21:44:59.545801
10	TKT-MI3LMPIH-685D	Ticket de prueba #9	Descripción de prueba #9	open	high	Soporte	Usuario Prueba	prueba9@example.com	3	2025-11-17 20:30:22.122376	2025-11-18 21:44:59.545801
6	TKT-MI3LMPDZ-QK0B	Ticket de prueba #5	Descripción de prueba #5	open	low	Soporte	Usuario Prueba	prueba5@example.com	3	2025-11-17 20:30:21.960347	2025-11-18 21:44:59.545801
2	TKT-MI3LMP8T-3OQK	Ticket de prueba #1	Descripción de prueba #1	open	medium	Soporte	Usuario Prueba	prueba1@example.com	3	2025-11-17 20:30:21.774608	2025-11-18 21:44:59.545801
15	TKT-MI3LMPNR-1MTA	Ticket de prueba #14	Descripción de prueba #14	open	low	Facturación	Usuario Prueba	prueba14@example.com	4	2025-11-17 20:30:22.312288	2025-11-18 21:44:59.545801
11	TKT-MI3LMPJS-PHOA	Ticket de prueba #10	Descripción de prueba #10	open	medium	Facturación	Usuario Prueba	prueba10@example.com	4	2025-11-17 20:30:22.169416	2025-11-18 21:44:59.545801
7	TKT-MI3LMPEK-UDH3	Ticket de prueba #6	Descripción de prueba #6	open	high	Facturación	Usuario Prueba	prueba6@example.com	4	2025-11-17 20:30:21.981071	2025-11-18 21:44:59.545801
3	TKT-MI3LMPAY-3FJL	Ticket de prueba #2	Descripción de prueba #2	open	low	Facturación	Usuario Prueba	prueba2@example.com	4	2025-11-17 20:30:21.851212	2025-11-18 21:44:59.545801
12	TKT-MI3LMPKV-IDBQ	Ticket de prueba #11	Descripción de prueba #11	open	low	Recursos Humanos	Usuario Prueba	prueba11@example.com	5	2025-11-17 20:30:22.208662	2025-11-18 21:44:59.545801
8	TKT-MI3LMPGE-J3AP	Ticket de prueba #7	Descripción de prueba #7	open	medium	Recursos Humanos	Usuario Prueba	prueba7@example.com	5	2025-11-17 20:30:22.047974	2025-11-18 21:44:59.545801
4	TKT-MI3LMPBQ-7342	Ticket de prueba #3	Descripción de prueba #3	open	high	Recursos Humanos	Usuario Prueba	prueba3@example.com	5	2025-11-17 20:30:21.879939	2025-11-18 21:44:59.545801
13	TKT-MI3LMPLW-LM7V	Ticket de prueba #12	Descripción de prueba #12	open	high	Contact Center	Usuario Prueba	prueba12@example.com	6	2025-11-17 20:30:22.245248	2025-11-18 21:44:59.545801
5	TKT-MI3LMPCW-2A7D	Ticket de prueba #4	Descripción de prueba #4	open	medium	Contact Center	Usuario Prueba	prueba4@example.com	6	2025-11-17 20:30:21.921631	2025-11-18 21:44:59.545801
9	TKT-MI3LMPH3-7CB8	Ticket de prueba #8	Descripción de prueba #8	open	low	Contact Center	Usuario Prueba	prueba8@example.com	6	2025-11-17 20:30:22.072613	2025-11-18 22:20:57.514239
19	TKT-MI3LMPR5-ZRSY	Ticket de prueba #18	Descripción de prueba #18	open	medium	Soporte	Usuario Prueba	prueba18@example.com	5	2025-11-17 20:30:22.434232	2025-11-17 22:02:31.037922
21	TKT-MI3LMPSG-YWHL	Ticket de prueba #20	Descripción de prueba #20	in-progress	medium	Recursos Humanos	Usuario Prueba	prueba20@example.com	5	2025-11-17 20:30:22.481551	2025-11-17 22:48:03.164138
20	TKT-MI3LMPRO-3Q63	Ticket de prueba #19	Descripción de prueba #19	closed	medium	Facturación	Usuario Prueba	prueba19@example.com	4	2025-11-17 20:30:22.453101	2025-11-18 21:44:59.545801
22	TKT-MI51K0BE-R5LQ	<script>alert('XSS')</script>	<script>alert('XSS')</script>	closed	medium	Recursos Humanos	<script>alert('XSS')</script>		5	2025-11-18 20:43:56.196924	2025-11-18 21:44:59.545801
16	TKT-MI3LMPOX-V078	Ticket de prueba #15	Descripción de prueba #15	open	high	Recursos Humanos	Usuario Prueba	prueba15@example.com	5	2025-11-17 20:30:22.354404	2025-11-18 21:44:59.545801
18	TKT-MI3LMPQC-KWYG	Ticket de prueba #17	Descripción de prueba #17	open	medium	Soporte	Usuario Prueba	prueba17@example.com	3	2025-11-17 20:30:22.405217	2025-11-18 21:46:54.867905
17	TKT-MI3LMPP7-KLXL	Ticket de prueba #16	Descripción de prueba #16	in-progress	medium	Contact Center	Usuario Prueba	prueba16@example.com	6	2025-11-17 20:30:22.364816	2025-11-18 22:20:42.228395
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: ticket_app
--

COPY public.users (id, email, password, name, role, department, created_at, active) FROM stdin;
1	admin@tiquetera.com	$2a$08$IZw3APf8pvtnCzxZz64hd.4biAdGSU9aCbXEFVQK3ckg8e2XtsgFm	Administrador	administrador	\N	2025-11-13 22:48:31.442972	t
4	facturacion@tiquetera.com	$2a$08$WqcvpItJbRCjSyBsiMrWgOU7k6YDN1NT0ZJGC1Ge.3PEjdGSsKiBq	Facturación	facturacion	Facturación	2025-11-13 22:48:31.565566	t
5	rrhh@tiquetera.com	$2a$08$MQL2sdZR4eQ7mltW59VmBuMDGp9JsnQ2s9u8QsoXP/5bJTeqTVIMi	Recursos Humanos	rrhh	Recursos Humanos	2025-11-13 22:48:31.608951	t
6	contact@tiquetera.com	$2a$08$xPsDeUdbln6PmMB04rh4h.E44D1jhDB4yBpKetzpI8KEHKfCVBBW.	Contact Center	contact	Contact Center	2025-11-13 22:48:31.654418	t
2	gerencia@tiquetera.com	$2a$08$Ixm6WnZp9a0KI0FLwowL6OX7EPXZJpQXKx1asCYLLKNVXogruocmm	Gerencia	gerencia	\N	2025-11-13 22:48:31.475669	t
3	soporte@tiquetera.com	$2a$08$C5qdjYfe9jFNh0RAzyfFee10d0LLSGOXlBVTD90NKepL8V2qp9M0e	Usuario Soporte	support	\N	2025-11-13 22:48:31.512116	t
\.


--
-- Name: ticket_updates_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ticket_app
--

SELECT pg_catalog.setval('public.ticket_updates_id_seq', 1, false);


--
-- Name: tickets_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ticket_app
--

SELECT pg_catalog.setval('public.tickets_id_seq', 22, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: ticket_app
--

SELECT pg_catalog.setval('public.users_id_seq', 6, true);


--
-- Name: system_config system_config_pkey; Type: CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.system_config
    ADD CONSTRAINT system_config_pkey PRIMARY KEY (key);


--
-- Name: ticket_updates ticket_updates_pkey; Type: CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT ticket_updates_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_pkey; Type: CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_pkey PRIMARY KEY (id);


--
-- Name: tickets tickets_tracking_id_key; Type: CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_tracking_id_key UNIQUE (tracking_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_ticket_updates_ticket_id; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_ticket_updates_ticket_id ON public.ticket_updates USING btree (ticket_id);


--
-- Name: idx_tickets_assigned_to; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_tickets_assigned_to ON public.tickets USING btree (assigned_to);


--
-- Name: idx_tickets_created_at; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_tickets_created_at ON public.tickets USING btree (created_at DESC);


--
-- Name: idx_tickets_department; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_tickets_department ON public.tickets USING btree (department);


--
-- Name: idx_tickets_priority; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_tickets_priority ON public.tickets USING btree (priority);


--
-- Name: idx_tickets_status; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_tickets_status ON public.tickets USING btree (status);


--
-- Name: idx_tickets_tracking_id; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_tickets_tracking_id ON public.tickets USING btree (tracking_id);


--
-- Name: idx_users_email; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_users_email ON public.users USING btree (email);


--
-- Name: idx_users_role; Type: INDEX; Schema: public; Owner: ticket_app
--

CREATE INDEX idx_users_role ON public.users USING btree (role);


--
-- Name: tickets update_tickets_updated_at; Type: TRIGGER; Schema: public; Owner: ticket_app
--

CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON public.tickets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: ticket_updates ticket_updates_ticket_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT ticket_updates_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id) ON DELETE CASCADE;


--
-- Name: ticket_updates ticket_updates_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.ticket_updates
    ADD CONSTRAINT ticket_updates_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: tickets tickets_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: ticket_app
--

ALTER TABLE ONLY public.tickets
    ADD CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict ePaYOLen4NpLHWmVq9er44rvoaPTAOM4uzm4lu0je45ACobQ1w3i3bDWUCFWKrL

