-- Fix video_calls table RLS policies to allow student access
-- This script ensures students can read video_calls records to join calls

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Students can read active video calls" ON video_calls;
DROP POLICY IF EXISTS "Counselors can manage video calls" ON video_calls;
DROP POLICY IF EXISTS "Users can read their own video calls" ON video_calls;

-- Enable RLS on video_calls table (ensure it's enabled)
ALTER TABLE video_calls ENABLE ROW LEVEL SECURITY;

-- Policy 1: Students can read active video calls (to join them)
-- Uses the same pattern as counselor policy - checks students table
CREATE POLICY "Students can read active video calls" ON video_calls
  FOR SELECT TO authenticated
  USING (
    student_user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM students 
      WHERE students.user_id = auth.uid() 
      AND video_calls.status = 'active'
    ) OR
    EXISTS (
      SELECT 1 FROM counselors 
      WHERE counselors.counselor_id = video_calls.counselor_id 
      AND counselors.user_id = auth.uid()
    )
  );

-- Policy 2: Counselors can manage all video calls
CREATE POLICY "Counselors can manage video calls" ON video_calls
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.user_id = auth.uid() 
      AND users.user_type = 'counselor'
    )
  );

-- Policy 3: Users can update video calls they are part of (when student joins)
CREATE POLICY "Users can update their video calls" ON video_calls
  FOR UPDATE TO authenticated
  USING (
    student_user_id = auth.uid() OR 
    EXISTS (
      SELECT 1 FROM counselors 
      WHERE counselors.counselor_id = video_calls.counselor_id 
      AND counselors.user_id = auth.uid()
    )
  );

-- Policy 4: Allow inserting video calls for counselors
CREATE POLICY "Counselors can create video calls" ON video_calls
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE users.user_id = auth.uid() 
      AND users.user_type = 'counselor'
    )
  );

-- Verify policies are created
SELECT schemaname, tablename, policyname, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'video_calls';