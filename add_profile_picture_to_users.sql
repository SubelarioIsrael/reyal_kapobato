-- Add profile_picture column to users table for universal profile image system
-- Using TEXT to store base64-encoded image data directly in the database
ALTER TABLE public.users 
DROP COLUMN IF EXISTS profile_picture;

ALTER TABLE public.users 
ADD COLUMN profile_picture TEXT NULL;

-- Optional: Migrate existing profile pictures from user_profiles table if they exist
-- UPDATE public.users 
-- SET profile_picture = up.profile_picture
-- FROM public.user_profiles up
-- WHERE users.user_id = up.user_id 
-- AND up.profile_picture IS NOT NULL;

-- Optional: Migrate existing counselor profile pictures to users table
-- UPDATE public.users 
-- SET profile_picture = c.profile_picture
-- FROM public.counselors c
-- WHERE users.user_id = c.user_id 
-- AND c.profile_picture IS NOT NULL;