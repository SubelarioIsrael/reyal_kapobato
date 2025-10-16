-- Complete fix for student chat list - Remove all appointment_id dependencies
-- This script ensures the messages table and all related functions work without appointment_id

-- 1. Drop old RPC functions that use appointment_id
DROP FUNCTION IF EXISTS public.mark_messages_read(INTEGER, UUID);
DROP FUNCTION IF EXISTS public.mark_messages_read(INTEGER, TEXT);

-- 2. Remove appointment_id column and constraints if they still exist
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_appointment_id_fkey;
DROP INDEX IF EXISTS idx_messages_appointment_id;
ALTER TABLE public.messages DROP COLUMN IF EXISTS appointment_id;

-- 3. Ensure the messages table has the correct structure for direct messaging
-- Check if the table needs to be recreated with correct structure
DO $$
BEGIN
    -- Check if sender_id column exists and is correct type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'sender_id' 
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.messages ALTER COLUMN sender_id TYPE UUID USING sender_id::uuid;
    END IF;

    -- Check if receiver_id column exists and is correct type  
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'messages' 
        AND column_name = 'receiver_id' 
        AND data_type = 'uuid'
    ) THEN
        ALTER TABLE public.messages ALTER COLUMN receiver_id TYPE UUID USING receiver_id::uuid;
    END IF;

    -- Ensure proper constraints exist
    ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;
    ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_receiver_id_fkey;
    
    ALTER TABLE public.messages ADD CONSTRAINT messages_sender_id_fkey 
        FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
    ALTER TABLE public.messages ADD CONSTRAINT messages_receiver_id_fkey 
        FOREIGN KEY (receiver_id) REFERENCES public.users(user_id) ON DELETE CASCADE;
END $$;

-- 4. Create proper indexes for the new structure
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON public.messages(sender_id, receiver_id, created_at DESC);

-- 5. Update RLS policies to work without appointment_id
DROP POLICY IF EXISTS "Users can view messages they are involved in" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages as sender" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they sent" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

-- Create comprehensive RLS policies for direct messaging
CREATE POLICY "Users can view messages they are involved in" ON public.messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert messages as sender" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update messages they received" ON public.messages
    FOR UPDATE USING (auth.uid() = receiver_id)
    WITH CHECK (auth.uid() = receiver_id);

CREATE POLICY "Users can update messages they sent" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id)
    WITH CHECK (auth.uid() = sender_id);

-- 6. Create new RPC function for marking messages as read without appointment_id
CREATE OR REPLACE FUNCTION public.mark_conversation_messages_read(
    p_other_user_id UUID
) RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    -- Mark all unread messages from the other user as read
    UPDATE public.messages 
    SET is_read = true, updated_at = CURRENT_TIMESTAMP
    WHERE sender_id = p_other_user_id 
      AND receiver_id = auth.uid()
      AND is_read = false;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create function to get conversation messages between two users
CREATE OR REPLACE FUNCTION public.get_conversation_messages(
    p_other_user_id UUID,
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0
) RETURNS TABLE (
    id BIGINT,
    sender_id UUID,
    receiver_id UUID,
    message TEXT,
    is_read BOOLEAN,
    created_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.sender_id,
        m.receiver_id,
        m.message,
        m.is_read,
        m.created_at
    FROM public.messages m
    WHERE (m.sender_id = auth.uid() AND m.receiver_id = p_other_user_id)
       OR (m.sender_id = p_other_user_id AND m.receiver_id = auth.uid())
    ORDER BY m.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.mark_conversation_messages_read TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_conversation_messages TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE messages_id_seq TO authenticated;

-- 9. Ensure RLS is enabled
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 10. Add helpful comment
COMMENT ON TABLE public.messages IS 'Messages table for direct communication between users without appointment dependencies';