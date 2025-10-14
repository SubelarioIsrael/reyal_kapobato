-- Migration to remove notes column from video_calls table
-- This should be run on the Supabase database

-- Remove the notes column from video_calls table
ALTER TABLE public.video_calls DROP COLUMN IF EXISTS notes;

-- Update the table comment to reflect the change
COMMENT ON TABLE public.video_calls IS 'Video call sessions - notes are now stored in counseling_session_notes table';