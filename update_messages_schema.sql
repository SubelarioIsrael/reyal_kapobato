-- Update messages table schema to remove appointment_id dependency
-- This script should be run in Supabase SQL Editor

-- 1. Drop the old RPC function that uses appointment_id
DROP FUNCTION IF EXISTS public.mark_messages_read(INTEGER, UUID);
DROP FUNCTION IF EXISTS public.mark_messages_read(INTEGER, TEXT);

-- 2. Remove the appointment_id column and related constraints if they exist
-- First, drop the foreign key constraint if it exists
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_appointment_id_fkey;

-- Drop the index on appointment_id if it exists  
DROP INDEX IF EXISTS idx_messages_appointment_id;

-- Drop the appointment_id column if it exists
ALTER TABLE public.messages DROP COLUMN IF EXISTS appointment_id;

-- 3. Create new RPC function that works without appointment_id
-- This function marks messages as read based on sender-receiver relationship
CREATE OR REPLACE FUNCTION public.mark_messages_read_by_users(
    p_sender_id UUID,
    p_receiver_id UUID
) RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE public.messages 
    SET is_read = true, updated_at = CURRENT_TIMESTAMP
    WHERE sender_id = p_sender_id 
      AND receiver_id = p_receiver_id 
      AND is_read = false;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the new function
GRANT EXECUTE ON FUNCTION public.mark_messages_read_by_users TO authenticated;

-- 4. Update RLS policies to remove any appointment_id references
-- Drop existing policies
DROP POLICY IF EXISTS "Users can view messages they are involved in" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages as sender" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they sent" ON public.messages;

-- Recreate policies without appointment_id dependency
CREATE POLICY "Users can view messages they are involved in" ON public.messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert messages as sender" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they received" ON public.messages
    FOR UPDATE USING (auth.uid() = receiver_id);

CREATE POLICY "Users can update messages they sent" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- 5. Ensure the messages table has the correct structure
-- The table should now have these columns:
-- - message_id (SERIAL PRIMARY KEY)
-- - sender_id (UUID NOT NULL REFERENCES users(user_id))
-- - receiver_id (UUID NOT NULL REFERENCES users(user_id))
-- - message (TEXT NOT NULL)
-- - message_type (VARCHAR(20) DEFAULT 'text')
-- - is_read (BOOLEAN DEFAULT false)
-- - created_at (TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP)
-- - updated_at (TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP)

-- Verify the table structure (this is informational - run separately)
-- SELECT column_name, data_type, is_nullable, column_default 
-- FROM information_schema.columns 
-- WHERE table_name = 'messages' AND table_schema = 'public'
-- ORDER BY ordinal_position;