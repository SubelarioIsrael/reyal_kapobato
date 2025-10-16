-- Simple fix to remove appointment_id from messages table
-- This is a safer approach that only removes the problematic column

-- 1. Drop all old RPC functions that might use appointment_id
DROP FUNCTION IF EXISTS public.get_messages_for_appointment(INTEGER);
DROP FUNCTION IF EXISTS public.mark_messages_as_read_for_appointment(INTEGER, UUID);

-- 2. Remove appointment_id column if it exists
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'messages' 
               AND column_name = 'appointment_id') THEN
        -- Drop foreign key constraint if it exists
        ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_appointment_id_fkey;
        -- Drop index if it exists
        DROP INDEX IF EXISTS idx_messages_appointment_id;
        -- Drop the column
        ALTER TABLE public.messages DROP COLUMN appointment_id;
        RAISE NOTICE 'Removed appointment_id column from messages table';
    ELSE
        RAISE NOTICE 'appointment_id column does not exist in messages table';
    END IF;
END $$;

-- 3. Create indexes for performance (only if they don't exist)
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);  
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON public.messages(is_read);

-- 4. Enable RLS if not already enabled
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 5. Drop old RLS policies that might reference appointment_id
DROP POLICY IF EXISTS "Users can view messages from their appointments" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages to their appointments" ON public.messages;
DROP POLICY IF EXISTS "Users can update their received messages" ON public.messages;

-- 6. Create new RLS policies without appointment_id dependency
DO $$
BEGIN
    -- Only create policies if they don't already exist
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can view their messages') THEN
        CREATE POLICY "Users can view their messages" ON public.messages
            FOR SELECT USING (
                auth.uid() = sender_id OR auth.uid() = receiver_id
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can insert messages') THEN
        CREATE POLICY "Users can insert messages" ON public.messages  
            FOR INSERT WITH CHECK (
                auth.uid() = sender_id
            );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'messages' AND policyname = 'Users can update messages they received') THEN
        CREATE POLICY "Users can update messages they received" ON public.messages
            FOR UPDATE USING (
                auth.uid() = receiver_id
            );
    END IF;
END $$;

-- 7. Create new RPC function for marking messages as read (without appointment_id)
CREATE OR REPLACE FUNCTION public.mark_messages_as_read(
    p_sender_id UUID,
    p_receiver_id UUID
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.messages 
    SET is_read = true, updated_at = CURRENT_TIMESTAMP
    WHERE sender_id = p_sender_id 
    AND receiver_id = p_receiver_id 
    AND is_read = false;
END;
$$;

-- 8. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_messages_as_read(UUID, UUID) TO authenticated;

-- 9. Show current messages table structure to verify
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'messages' 
ORDER BY ordinal_position;