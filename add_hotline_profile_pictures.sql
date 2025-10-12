-- Add profile_picture column to mental_health_hotlines table
-- This will store the URL of the uploaded profile picture for each hotline

ALTER TABLE public.mental_health_hotlines 
ADD COLUMN profile_picture TEXT;

-- Add comment to document the column
COMMENT ON COLUMN public.mental_health_hotlines.profile_picture 
IS 'URL to the profile picture image stored in Supabase Storage';

-- Create the storage bucket for hotline profile pictures if it doesn't exist
-- Note: This needs to be run in the Supabase dashboard or using the Supabase CLI
-- INSERT INTO storage.buckets (id, name, public) 
-- VALUES ('hotline-profiles', 'hotline-profiles', true);

-- Set up Row Level Security (RLS) policies for the storage bucket
-- Note: These policies need to be configured in the Supabase dashboard

-- Policy for authenticated users to upload files:
-- CREATE POLICY "Allow authenticated uploads" ON storage.objects 
-- FOR INSERT TO authenticated 
-- WITH CHECK (bucket_id = 'hotline-profiles');

-- Policy for public read access:
-- CREATE POLICY "Allow public downloads" ON storage.objects 
-- FOR SELECT TO public 
-- USING (bucket_id = 'hotline-profiles');

-- Policy for authenticated users to update their uploads:
-- CREATE POLICY "Allow authenticated updates" ON storage.objects 
-- FOR UPDATE TO authenticated 
-- USING (bucket_id = 'hotline-profiles');

-- Policy for authenticated users to delete their uploads:
-- CREATE POLICY "Allow authenticated deletes" ON storage.objects 
-- FOR DELETE TO authenticated 
-- USING (bucket_id = 'hotline-profiles');