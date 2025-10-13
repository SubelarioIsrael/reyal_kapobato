-- Quick fix for video_calls RLS policy
-- Run this in your Supabase SQL Editor

-- Update the existing policy to allow students to see active calls (same pattern as counselor policy)
ALTER POLICY "student_video_calls_policy" ON "public"."video_calls" 
USING (
  student_user_id = auth.uid() OR
  EXISTS (
    SELECT 1 FROM students 
    WHERE students.user_id = auth.uid() 
    AND video_calls.status = 'active'
  )
);