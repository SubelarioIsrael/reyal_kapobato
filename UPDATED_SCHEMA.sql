-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.activities (
  id integer NOT NULL DEFAULT nextval('activities_id_seq'::regclass),
  name character varying NOT NULL UNIQUE,
  description text,
  points integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT activities_pkey PRIMARY KEY (id)
);
CREATE TABLE public.activity_completions (
  completion_id integer NOT NULL DEFAULT nextval('activity_completions_completion_id_seq'::regclass),
  user_id uuid NOT NULL,
  activity_id integer NOT NULL,
  completed_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  completion_date date,
  CONSTRAINT activity_completions_pkey PRIMARY KEY (completion_id),
  CONSTRAINT activity_completions_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES public.activities(id),
  CONSTRAINT activity_completions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.breathing_exercises (
  id integer NOT NULL DEFAULT nextval('breathing_exercises_id_seq'::regclass),
  name character varying NOT NULL,
  description text NOT NULL,
  duration integer NOT NULL CHECK (duration > 0),
  pattern jsonb NOT NULL,
  color_hex character varying NOT NULL CHECK (color_hex::text ~ '^#[0-9A-Fa-f]{6}$'::text),
  icon_name character varying NOT NULL,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT breathing_exercises_pkey PRIMARY KEY (id)
);
CREATE TABLE public.chat_messages (
  message_id integer NOT NULL DEFAULT nextval('chat_messages_message_id_seq'::regclass),
  user_id uuid NOT NULL,
  message_content text NOT NULL,
  sender character varying NOT NULL CHECK (sender::text = ANY (ARRAY['user'::character varying::text, 'bot'::character varying::text])),
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT chat_messages_pkey PRIMARY KEY (message_id),
  CONSTRAINT chat_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.counseling_appointments (
  appointment_id integer NOT NULL DEFAULT nextval('counselingappointments_appointment_id_seq'::regclass),
  counselor_id integer NOT NULL,
  appointment_date date NOT NULL,
  start_time time without time zone NOT NULL,
  end_time time without time zone NOT NULL,
  status character varying DEFAULT '''''pending''''::character varying''::character varying'::character varying CHECK (status::text = ANY (ARRAY['accepted'::character varying::text, 'pending'::character varying::text, 'completed'::character varying::text, 'cancelled'::character varying::text, 'rejected'::character varying::text, 'rescheduled'::character varying::text, 'no-show'::character varying::text])),
  notes text,
  user_id uuid,
  status_message text,
  CONSTRAINT counseling_appointments_pkey PRIMARY KEY (appointment_id),
  CONSTRAINT counseling_appointments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT counselingappointments_counselor_id_fkey FOREIGN KEY (counselor_id) REFERENCES public.counselors(counselor_id)
);
CREATE TABLE public.counseling_session_notes (
  session_note_id integer NOT NULL DEFAULT nextval('counseling_session_notes_session_note_id_seq'::regclass),
  appointment_id integer NOT NULL,
  counselor_id integer NOT NULL,
  student_user_id uuid NOT NULL,
  summary text NOT NULL,
  topics_discussed text,
  recommendations text,
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT counseling_session_notes_pkey PRIMARY KEY (session_note_id),
  CONSTRAINT counseling_session_notes_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.counseling_appointments(appointment_id),
  CONSTRAINT counseling_session_notes_counselor_id_fkey FOREIGN KEY (counselor_id) REFERENCES public.counselors(counselor_id),
  CONSTRAINT counseling_session_notes_student_user_id_fkey FOREIGN KEY (student_user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.counselors (
  counselor_id integer NOT NULL DEFAULT nextval('counselors_counselor_id_seq'::regclass),
  first_name character varying NOT NULL,
  last_name character varying NOT NULL,
  email character varying NOT NULL UNIQUE,
  specialization character varying NOT NULL,
  availability_status text CHECK (availability_status = ANY (ARRAY['available'::character varying::text, 'busy'::character varying::text, 'away'::character varying::text, 'offline'::character varying::text])),
  bio text,
  profile_picture character varying,
  user_id uuid NOT NULL UNIQUE,
  CONSTRAINT counselors_pkey PRIMARY KEY (counselor_id),
  CONSTRAINT counselors_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.emergency_contacts (
  contact_id integer NOT NULL DEFAULT nextval('emergencycontacts_contact_id_seq'::regclass),
  contact_name character varying NOT NULL,
  relationship character varying NOT NULL,
  contact_number character varying NOT NULL,
  is_notified boolean DEFAULT false,
  user_id uuid NOT NULL,
  CONSTRAINT emergency_contacts_pkey PRIMARY KEY (contact_id),
  CONSTRAINT emergency_contacts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.intervention_logs (
  log_id integer NOT NULL DEFAULT nextval('intervention_logs_log_id_seq'::regclass),
  user_id uuid NOT NULL,
  intervention_level character varying NOT NULL CHECK (intervention_level::text = ANY (ARRAY['moderate'::character varying::text, 'high'::character varying::text])),
  trigger_message text NOT NULL,
  triggered_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT intervention_logs_pkey PRIMARY KEY (log_id),
  CONSTRAINT intervention_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.journal_entries (
  journal_id integer NOT NULL DEFAULT nextval('journalentries_journal_id_seq'::regclass),
  title character varying NOT NULL,
  content text NOT NULL,
  sentiment_score numeric CHECK (sentiment_score >= '-1.0'::numeric AND sentiment_score <= 1.0),
  entry_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  is_shared_with_counselor boolean DEFAULT false,
  user_id uuid,
  CONSTRAINT journal_entries_pkey PRIMARY KEY (journal_id),
  CONSTRAINT journal_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.mental_health_hotlines (
  hotline_id integer NOT NULL DEFAULT nextval('mental_health_hotlines_id_seq'::regclass),
  name text NOT NULL,
  phone text NOT NULL,
  city_or_region text,
  notes text,
  created_at timestamp with time zone DEFAULT now(),
  profile_picture text,
  CONSTRAINT mental_health_hotlines_pkey PRIMARY KEY (hotline_id)
);
CREATE TABLE public.mental_health_resources (
  resource_id integer NOT NULL DEFAULT nextval('mentalhealthresources_resource_id_seq'::regclass),
  title character varying NOT NULL,
  description text NOT NULL,
  resource_type character varying NOT NULL CHECK (resource_type::text = ANY (ARRAY['article'::character varying::text, 'video'::character varying::text, 'infographic'::character varying::text, 'ebook'::character varying::text, 'external_link'::character varying::text])),
  media_url character varying,
  tags character varying,
  publish_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT mental_health_resources_pkey PRIMARY KEY (resource_id)
);
CREATE TABLE public.messages (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  appointment_id bigint,
  sender_id uuid,
  receiver_id uuid,
  message text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT timezone('utc'::text, now()),
  is_read boolean DEFAULT false,
  message_type text DEFAULT 'text'::text,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_appointment_id_fkey FOREIGN KEY (appointment_id) REFERENCES public.counseling_appointments(appointment_id),
  CONSTRAINT messages_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.mood_entries (
  entry_id integer NOT NULL DEFAULT nextval('mood_entries_entry_id_seq'::regclass),
  user_id uuid,
  mood_type character varying NOT NULL,
  emoji_code character varying,
  reasons ARRAY,
  notes text,
  entry_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  entry_date date DEFAULT (entry_timestamp)::date,
  CONSTRAINT mood_entries_pkey PRIMARY KEY (entry_id),
  CONSTRAINT mood_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.questionnaire_answers (
  answer_id integer NOT NULL DEFAULT nextval('questionnaire_answers_answer_id_seq'::regclass),
  response_id integer NOT NULL,
  question_id integer NOT NULL,
  chosen_answer integer NOT NULL,
  question_text_snapshot text NOT NULL DEFAULT ''::text,
  CONSTRAINT questionnaire_answers_pkey PRIMARY KEY (answer_id),
  CONSTRAINT questionnaire_answers_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(question_id),
  CONSTRAINT questionnaire_answers_response_id_fkey FOREIGN KEY (response_id) REFERENCES public.questionnaire_responses(response_id)
);
CREATE TABLE public.questionnaire_questions (
  version_id integer NOT NULL,
  question_id integer NOT NULL,
  question_order integer NOT NULL,
  CONSTRAINT questionnaire_questions_pkey PRIMARY KEY (version_id, question_id),
  CONSTRAINT questionnaire_questions_question_id_fkey FOREIGN KEY (question_id) REFERENCES public.questions(question_id),
  CONSTRAINT questionnaire_questions_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.questionnaire_versions(version_id)
);
CREATE TABLE public.questionnaire_responses (
  response_id integer NOT NULL DEFAULT nextval('questionnaire_responses_response_id_seq'::regclass),
  user_id uuid NOT NULL,
  version_id integer NOT NULL,
  total_score integer NOT NULL,
  submission_timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT questionnaire_responses_pkey PRIMARY KEY (response_id),
  CONSTRAINT questionnaire_responses_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id),
  CONSTRAINT questionnaire_responses_version_id_fkey FOREIGN KEY (version_id) REFERENCES public.questionnaire_versions(version_id)
);
CREATE TABLE public.questionnaire_summaries (
  summary_id integer NOT NULL DEFAULT nextval('questionnaire_summaries_summary_id_seq'::regclass),
  response_id integer NOT NULL,
  severity_level character varying NOT NULL CHECK (severity_level::text = ANY (ARRAY['mild'::character varying::text, 'moderate'::character varying::text, 'severe'::character varying::text, 'critical'::character varying::text])),
  insights text NOT NULL,
  recommendations text NOT NULL,
  breathing_exercise_id integer,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT questionnaire_summaries_pkey PRIMARY KEY (summary_id),
  CONSTRAINT questionnaire_summaries_breathing_exercise_id_fkey FOREIGN KEY (breathing_exercise_id) REFERENCES public.breathing_exercises(id),
  CONSTRAINT questionnaire_summaries_response_id_fkey FOREIGN KEY (response_id) REFERENCES public.questionnaire_responses(response_id)
);
CREATE TABLE public.questionnaire_versions (
  version_id integer NOT NULL DEFAULT nextval('questionnaire_versions_version_id_seq'::regclass),
  version_name character varying NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT questionnaire_versions_pkey PRIMARY KEY (version_id)
);
CREATE TABLE public.questions (
  question_id integer NOT NULL DEFAULT nextval('questions_question_id_seq'::regclass),
  question_text text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT questions_pkey PRIMARY KEY (question_id)
);
CREATE TABLE public.students (
  student_id integer NOT NULL DEFAULT nextval('students_student_id_seq'::regclass) UNIQUE,
  student_code character varying NOT NULL UNIQUE,
  course character varying,
  year_level integer NOT NULL,
  user_id uuid,
  last_login timestamp with time zone,
  first_name character varying,
  last_name character varying,
  strand character varying,
  education_level character varying NOT NULL DEFAULT 'basic_education'::character varying CHECK (education_level::text = ANY (ARRAY['basic_education'::character varying, 'junior_high'::character varying, 'senior_high'::character varying, 'college'::character varying]::text[])),
  CONSTRAINT students_pkey PRIMARY KEY (student_id),
  CONSTRAINT students_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.user_notifications (
  notification_id integer NOT NULL DEFAULT nextval('usernotifications_notification_id_seq'::regclass),
  notification_type character varying NOT NULL,
  content text NOT NULL,
  timestamp timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  is_read boolean DEFAULT false,
  action_url character varying,
  user_id uuid,
  CONSTRAINT user_notifications_pkey PRIMARY KEY (notification_id),
  CONSTRAINT user_notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id)
);
CREATE TABLE public.users (
  email character varying NOT NULL UNIQUE,
  registration_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
  user_type character varying DEFAULT 'student'::character varying CHECK (user_type::text = ANY (ARRAY['student'::character varying::text, 'admin'::character varying::text, 'counselor'::character varying::text])),
  user_id uuid NOT NULL,
  status character varying NOT NULL DEFAULT 'active'::character varying CHECK (status::text = ANY (ARRAY['active'::character varying::text, 'suspended'::character varying::text])),
  profile_picture text,
  CONSTRAINT users_pkey PRIMARY KEY (user_id)
);
CREATE TABLE public.video_calls (
  call_id integer NOT NULL DEFAULT nextval('video_calls_call_id_seq'::regclass),
  call_code character varying NOT NULL UNIQUE,
  counselor_id integer,
  student_user_id uuid,
  created_by character varying NOT NULL CHECK (created_by::text = ANY (ARRAY['counselor'::character varying, 'student'::character varying]::text[])),
  status character varying NOT NULL DEFAULT 'active'::character varying CHECK (status::text = ANY (ARRAY['active'::character varying, 'ended'::character varying, 'expired'::character varying]::text[])),
  created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
  counselor_joined_at timestamp with time zone,
  student_joined_at timestamp with time zone,
  ended_at timestamp with time zone,
  duration_minutes integer,
  notes text,
  CONSTRAINT video_calls_pkey PRIMARY KEY (call_id),
  CONSTRAINT video_calls_counselor_id_fkey FOREIGN KEY (counselor_id) REFERENCES public.counselors(counselor_id),
  CONSTRAINT video_calls_student_user_id_fkey FOREIGN KEY (student_user_id) REFERENCES public.users(user_id)
);