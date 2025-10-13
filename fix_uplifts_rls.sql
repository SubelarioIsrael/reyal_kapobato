-- Fix Row Level Security policies for uplifts table
-- This allows admins to manage daily uplifts

-- Enable RLS on uplifts table (ensure it's enabled)
ALTER TABLE public.uplifts ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Admins can manage uplifts" ON public.uplifts;
DROP POLICY IF EXISTS "Everyone can read uplifts" ON public.uplifts;

-- Policy 1: Allow everyone to read uplifts (students need to see them)
CREATE POLICY "Everyone can read uplifts" ON public.uplifts
    FOR SELECT
    USING (true);

-- Policy 2: Allow admins to manage all uplifts (insert, update, delete)
CREATE POLICY "Admins can manage uplifts" ON public.uplifts
    FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.user_id = auth.uid() 
            AND users.user_type = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE users.user_id = auth.uid() 
            AND users.user_type = 'admin'
        )
    );

-- Verify the policies are created
SELECT schemaname, tablename, policyname, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'uplifts';