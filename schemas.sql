create table public.admin_users (
  admin_id serial not null,
  username character varying(50) not null,
  user_id uuid not null,
  constraint adminusers_pkey primary key (admin_id),
  constraint admin_users_user_id_key unique (user_id),
  constraint adminusers_username_key unique (username),
  constraint admin_users_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create table public.breathing_exercises (
  id serial not null,
  name character varying(100) not null,
  description text not null,
  duration integer not null,
  pattern jsonb not null,
  color_hex character varying(7) not null,
  icon_name character varying(50) not null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint breathing_exercises_pkey primary key (id),
  constraint breathing_exercises_duration_check check ((duration > 0)),
  constraint valid_color_hex check (((color_hex)::text ~ '^#[0-9A-Fa-f]{6}$'::text))
) TABLESPACE pg_default;

create table public.counseling_appointments (
  appointment_id serial not null,
  counselor_id integer not null,
  appointment_date date not null,
  start_time time without time zone not null,
  end_time time without time zone not null,
  status character varying(10) null default '''''pending''''::character varying''::character varying'::character varying,
  notes text null,
  user_id uuid null,
  constraint counselingappointments_pkey primary key (appointment_id),
  constraint counseling_appointments_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint counselingappointments_counselor_id_fkey foreign KEY (counselor_id) references counselors (counselor_id) on delete CASCADE,
  constraint chk_appointment_times check ((start_time < end_time)),
  constraint counseling_appointments_status_check check (
    (
      (status)::text = any (
        array[
          ('accepted'::character varying)::text,
          ('pending'::character varying)::text,
          ('completed'::character varying)::text,
          ('cancelled'::character varying)::text,
          ('rejected'::character varying)::text,
          ('rescheduled'::character varying)::text,
          ('no-show'::character varying)::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_appointments_date on public.counseling_appointments using btree (appointment_date) TABLESPACE pg_default;

create table public.counselors (
  counselor_id serial not null,
  first_name character varying(50) not null,
  last_name character varying(50) not null,
  email character varying(100) not null,
  specialization character varying(100) not null,
  availability_status text null,
  bio text null,
  profile_picture character varying(255) null,
  user_id uuid not null,
  constraint counselors_pkey primary key (counselor_id),
  constraint counselors_email_key unique (email),
  constraint counselors_user_id_key unique (user_id),
  constraint counselors_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint counselors_availability_status_check check (
    (
      availability_status = any (
        array[
          ('available'::character varying)::text,
          ('busy'::character varying)::text,
          ('away'::character varying)::text,
          ('offline'::character varying)::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create table public.aggregated_analytics (
  analytics_id serial not null,
  metric_type character varying(50) not null,
  time_period character varying(20) not null,
  value numeric(10, 2) not null,
  demographic_filter jsonb null,
  timestamp timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint aggregatedanalytics_pkey primary key (analytics_id)
) TABLESPACE pg_default;

create table public.emergency_contacts (
  contact_id serial not null,
  contact_name character varying(100) not null,
  relationship character varying(50) not null,
  contact_number character varying(20) not null,
  email character varying(100) null,
  is_primary boolean null default false,
  is_notified boolean null default false,
  user_id uuid null,
  constraint emergencycontacts_pkey primary key (contact_id),
  constraint emergency_contacts_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create table public.journal_entries (
  journal_id serial not null,
  title character varying(100) not null,
  content text not null,
  sentiment_score numeric(3, 2) null,
  entry_timestamp timestamp without time zone null default CURRENT_TIMESTAMP,
  is_shared_with_counselor boolean null default false,
  user_id uuid null,
  constraint journalentries_pkey primary key (journal_id),
  constraint journal_entries_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint chk_sentiment_score check (
    (
      (sentiment_score >= '-1.0'::numeric)
      and (sentiment_score <= 1.0)
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_journal_entries_timestamp on public.journal_entries using btree (entry_timestamp) TABLESPACE pg_default;

create table public.mental_health_resources (
  resource_id serial not null,
  title character varying(100) not null,
  content text not null,
  resource_type character varying(15) not null,
  media_url character varying(255) null,
  tags character varying(255) null,
  publish_date timestamp without time zone null default CURRENT_TIMESTAMP,
  constraint mentalhealthresources_pkey primary key (resource_id),
  constraint mentalhealthresources_resource_type_check check (
    (
      (resource_type)::text = any (
        (
          array[
            'article'::character varying,
            'video'::character varying,
            'infographic'::character varying,
            'ebook'::character varying,
            'external_link'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create table public.mood_entries (
  entry_id serial not null,
  mood_rating integer not null,
  mood_description character varying(100) null,
  energy_level integer not null,
  stress_level integer not null,
  entry_timestamp timestamp without time zone null default CURRENT_TIMESTAMP,
  tags character varying(255) null,
  notes text null,
  user_id uuid null,
  constraint moodentries_pkey primary key (entry_id),
  constraint mood_entries_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint chk_energy_level check (
    (
      (energy_level >= 1)
      and (energy_level <= 10)
    )
  ),
  constraint chk_mood_rating check (
    (
      (mood_rating >= 1)
      and (mood_rating <= 10)
    )
  ),
  constraint chk_stress_level check (
    (
      (stress_level >= 1)
      and (stress_level <= 10)
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_mood_entries_timestamp on public.mood_entries using btree (entry_timestamp) TABLESPACE pg_default;

create table public.parental_connections (
  connection_id serial not null,
  parent_name character varying(100) not null,
  relationship character varying(50) not null,
  email character varying(100) not null,
  phone character varying(20) null,
  access_level character varying(15) null default 'emergency_only'::character varying,
  status character varying(10) null default 'pending'::character varying,
  date_connected timestamp without time zone null default CURRENT_TIMESTAMP,
  user_id uuid null,
  constraint parentalconnections_pkey primary key (connection_id),
  constraint parental_connections_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint parentalconnections_access_level_check check (
    (
      (access_level)::text = any (
        (
          array[
            'emergency_only'::character varying,
            'limited'::character varying,
            'full'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint parentalconnections_status_check check (
    (
      (status)::text = any (
        (
          array[
            'pending'::character varying,
            'active'::character varying,
            'declined'::character varying,
            'revoked'::character varying
          ]
        )::text[]
      )
    )
  )
) TABLESPACE pg_default;

create table public.parents (
  parent_id uuid not null default extensions.uuid_generate_v4 (),
  user_id uuid null,
  first_name character varying(100) not null,
  last_name character varying(100) not null,
  email character varying(255) not null,
  phone character varying(20) null,
  address text null,
  created_at timestamp with time zone null default CURRENT_TIMESTAMP,
  updated_at timestamp with time zone null default CURRENT_TIMESTAMP,
  constraint parents_pkey primary key (parent_id),
  constraint parents_email_key unique (email),
  constraint fk_user foreign KEY (user_id) references users (user_id) on delete CASCADE,
  constraint parents_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create index IF not exists idx_parents_user_id on public.parents using btree (user_id) TABLESPACE pg_default;

create trigger update_parents_updated_at BEFORE
update on parents for EACH row
execute FUNCTION update_updated_at_column ();

create table public.password_resets (
  reset_id serial not null,
  reset_token character varying(255) not null,
  created_at timestamp without time zone null default CURRENT_TIMESTAMP,
  expires_at timestamp without time zone not null,
  user_id uuid null,
  constraint passwordresets_pkey primary key (reset_id),
  constraint password_resets_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create table public.questions (
  question_id serial not null,
  question_text text not null,
  is_active boolean default true,
  created_at timestamp without time zone default CURRENT_TIMESTAMP,
  updated_at timestamp without time zone default CURRENT_TIMESTAMP,
  constraint questions_pkey primary key (question_id)
) TABLESPACE pg_default;

create table public.questionnaire_versions (
  version_id serial not null,
  version_name varchar(50) not null,
  is_active boolean default true,
  created_at timestamp without time zone default CURRENT_TIMESTAMP,
  constraint questionnaire_versions_pkey primary key (version_id)
) TABLESPACE pg_default;

create table public.questionnaire_questions (
  version_id integer not null,
  question_id integer not null,
  question_order integer not null,
  constraint questionnaire_questions_pkey primary key (version_id, question_id),
  constraint questionnaire_questions_version_id_fkey foreign key (version_id) references questionnaire_versions (version_id),
  constraint questionnaire_questions_question_id_fkey foreign key (question_id) references questions (question_id)
) TABLESPACE pg_default;

create table public.questionnaire_responses (
  response_id serial not null,
  user_id uuid not null,
  version_id integer not null,
  total_score integer not null,
  submission_timestamp timestamp without time zone default CURRENT_TIMESTAMP,
  constraint questionnaire_responses_pkey primary key (response_id),
  constraint questionnaire_responses_user_id_fkey foreign key (user_id) references users (user_id),
  constraint questionnaire_responses_version_id_fkey foreign key (version_id) references questionnaire_versions (version_id)
) TABLESPACE pg_default;

create table public.questionnaire_answers (
  answer_id serial not null,
  response_id integer not null,
  question_id integer not null,
  chosen_answer integer not null,
  constraint questionnaire_answers_pkey primary key (answer_id),
  constraint questionnaire_answers_response_id_fkey foreign key (response_id) references questionnaire_responses (response_id),
  constraint questionnaire_answers_question_id_fkey foreign key (question_id) references questions (question_id)
) TABLESPACE pg_default;

create table public.stress_gauge_readings (
  reading_id serial not null,
  stress_level integer not null,
  reading_timestamp timestamp without time zone null default CURRENT_TIMESTAMP,
  alert_triggered boolean null default false,
  alert_type character varying(50) null,
  response_action character varying(255) null,
  user_id uuid null,
  constraint stressgaugereadings_pkey primary key (reading_id),
  constraint stress_gauge_readings_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint chk_stress_gauge_level check (
    (
      (stress_level >= 1)
      and (stress_level <= 10)
    )
  )
) TABLESPACE pg_default;

create table public.students (
  student_id serial not null,
  student_code character varying(20) not null,
  course character varying(100) not null,
  year_level integer not null,
  user_id uuid null,
  last_login timestamp with time zone null,
  constraint students_pkey primary key (student_id),
  constraint students_student_code_key unique (student_code),
  constraint students_student_id_key unique (student_id),
  constraint students_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint chk_year_level check (
    (
      (year_level >= 1)
      and (year_level <= 6)
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_students_student_code on public.students using btree (student_code) TABLESPACE pg_default;

create table public.user_achievements (
  achievement_id serial not null,
  achievement_type character varying(50) not null,
  date_earned timestamp without time zone null default CURRENT_TIMESTAMP,
  description text not null,
  points_awarded integer null default 0,
  user_id uuid null,
  constraint userachievements_pkey primary key (achievement_id),
  constraint user_achievements_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create table public.user_activities (
  user_activity_id serial not null,
  activity_id integer not null,
  start_time timestamp without time zone null default CURRENT_TIMESTAMP,
  completion_time timestamp without time zone null,
  user_rating integer null,
  notes text null,
  user_id uuid null,
  constraint useractivities_pkey primary key (user_activity_id),
  constraint user_activities_activity_id_fkey foreign KEY (activity_id) references breathing_exercises (id),
  constraint user_activities_user_id_fkey foreign KEY (user_id) references users (user_id),
  constraint chk_user_rating check (
    (
      (user_rating >= 1)
      and (user_rating <= 5)
    )
  )
) TABLESPACE pg_default;

create table public.user_notifications (
  notification_id serial not null,
  notification_type character varying(50) not null,
  content text not null,
  timestamp timestamp without time zone null default CURRENT_TIMESTAMP,
  is_read boolean null default false,
  action_url character varying(255) null,
  user_id uuid null,
  constraint usernotifications_pkey primary key (notification_id),
  constraint user_notifications_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create table public.user_profiles (
  profile_id serial not null,
  profile_picture character varying(255) null,
  notification_preferences jsonb null,
  theme_preferences character varying(50) null default 'default'::character varying,
  privacy_settings jsonb null,
  emergency_contact_enabled boolean null default true,
  user_id uuid null,
  constraint userprofiles_pkey primary key (profile_id),
  constraint user_profiles_user_id_fkey foreign KEY (user_id) references users (user_id)
) TABLESPACE pg_default;

create table public.users (
  username character varying(50) not null,
  email character varying(100) not null,
  registration_date timestamp without time zone null default CURRENT_TIMESTAMP,
  user_type character varying(10) null default 'student'::character varying,
  user_id uuid not null,
  status character varying(20) not null default 'active'::character varying,
  constraint users_pkey primary key (user_id),
  constraint users_email_key unique (email),
  constraint users_username_key unique (username),
  constraint users_status_check check (
    (
      (status)::text = any (
        (
          array[
            'active'::character varying,
            'suspended'::character varying
          ]
        )::text[]
      )
    )
  ),
  constraint users_user_type_check check (
    (
      (user_type)::text = any (
        array[
          ('student'::character varying)::text,
          ('faculty'::character varying)::text,
          ('staff'::character varying)::text,
          ('admin'::character varying)::text,
          ('counselor'::character varying)::text
        ]
      )
    )
  )
) TABLESPACE pg_default;

create index IF not exists idx_user_email on public.users using btree (email) TABLESPACE pg_default;

-- Sample data for questionnaire system
INSERT INTO public.questionnaire_versions (version_name, is_active) VALUES
('Student Mental Health Questionnaire v1', true);

-- Sample questions for the questionnaire
INSERT INTO public.questions (question_text, is_active) VALUES
('How often have you felt nervous, anxious, or on edge over the past two weeks?', true),
('How often have you been unable to stop or control worrying over the past two weeks?', true),
('How often have you felt little interest or pleasure in doing things over the past two weeks?', true),
('How often have you felt down, depressed, or hopeless over the past two weeks?', true),
('How often have you had trouble falling or staying asleep, or sleeping too much over the past two weeks?', true),
('How often have you felt tired or had little energy over the past two weeks?', true),
('How often have you had poor appetite or been overeating over the past two weeks?', true),
('How often have you had trouble concentrating on things over the past two weeks?', true),
('How often have you been moving or speaking so slowly that other people could have noticed?', true),
('How often have you had thoughts that you would be better off dead or of hurting yourself in some way over the past two weeks?', true);

-- Link questions to the questionnaire version
INSERT INTO public.questionnaire_questions (version_id, question_id, question_order) VALUES
(1, 1, 1),
(1, 2, 2),
(1, 3, 3),
(1, 4, 4),
(1, 5, 5),
(1, 6, 6),
(1, 7, 7),
(1, 8, 8),
(1, 9, 9),
(1, 10, 10);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_questionnaire_responses_user_version ON public.questionnaire_responses (user_id, version_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_answers_response ON public.questionnaire_answers (response_id);
CREATE INDEX IF NOT EXISTS idx_questionnaire_questions_version ON public.questionnaire_questions (version_id, question_order);

create table public.questionnaire_summaries (
    summary_id serial not null,
    response_id integer not null,
    severity_level character varying(20) not null,
    insights text not null,
    recommendations text not null,
    breathing_exercise_id integer,
    created_at timestamp without time zone default CURRENT_TIMESTAMP,
    constraint questionnaire_summaries_pkey primary key (summary_id),
    constraint questionnaire_summaries_response_id_fkey foreign key (response_id) references questionnaire_responses (response_id),
    constraint questionnaire_summaries_breathing_exercise_id_fkey foreign key (breathing_exercise_id) references breathing_exercises (id),
    constraint questionnaire_summaries_severity_level_check check (
        (severity_level)::text = any (
            array[
                'mild'::character varying,
                'moderate'::character varying,
                'severe'::character varying,
                'critical'::character varying
            ]::text[]
        )
    )
) TABLESPACE pg_default;

create index IF not exists idx_questionnaire_summaries_response on public.questionnaire_summaries using btree (response_id) TABLESPACE pg_default;

ALTER TABLE public.counseling_appointments
ADD COLUMN status_message text null;

CREATE TABLE public.counseling_session_notes (
    session_note_id serial PRIMARY KEY,
    appointment_id integer NOT NULL REFERENCES counseling_appointments(appointment_id) ON DELETE CASCADE,
    counselor_id integer NOT NULL REFERENCES counselors(counselor_id),
    student_user_id uuid NOT NULL REFERENCES users(user_id),
    summary text NOT NULL,
    topics_discussed text,
    action_items text,
    recommendations text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);