-- Final comprehensive fix for messaging system
-- This script ensures the messages table works without appointment_id

-- 1. Drop all old RPC functions that might use appointment_id
DROP FUNCTION IF EXISTS public.get_messages_for_appointment(INTEGER);
DROP FUNCTION IF EXISTS public.mark_messages_as_read_for_appointment(INTEGER, UUID);

-- 2. Ensure messages table has correct structure without appointment_id
-- First check if appointment_id column exists and remove it
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

-- 3. Ensure messages table has all required columns
DO $$
BEGIN
    -- Add message_id if it doesn't exist (but don't make it primary key if one already exists)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'message_id') THEN
        -- Check if table already has a primary key
        IF NOT EXISTS (SELECT 1 FROM information_schema.table_constraints 
                       WHERE table_name = 'messages' AND constraint_type = 'PRIMARY KEY') THEN
            ALTER TABLE public.messages ADD COLUMN message_id SERIAL PRIMARY KEY;
        ELSE
            ALTER TABLE public.messages ADD COLUMN message_id SERIAL;
        END IF;
    END IF;
    
    -- Add sender_id if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'sender_id') THEN
        ALTER TABLE public.messages ADD COLUMN sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE;
    END IF;
    
    -- Add receiver_id if it doesn't exist  
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'receiver_id') THEN
        ALTER TABLE public.messages ADD COLUMN receiver_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE;
    END IF;
    
    -- Add message if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'message') THEN
        ALTER TABLE public.messages ADD COLUMN message TEXT NOT NULL;
    END IF;
    
    -- Add message_type if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'message_type') THEN
        ALTER TABLE public.messages ADD COLUMN message_type VARCHAR(20) DEFAULT 'text' 
        CHECK (message_type IN ('text', 'image', 'file'));
    END IF;
    
    -- Add is_read if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'is_read') THEN
        ALTER TABLE public.messages ADD COLUMN is_read BOOLEAN DEFAULT false;
    END IF;
    
    -- Add created_at if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'created_at') THEN
        ALTER TABLE public.messages ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
    
    -- Add updated_at if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'messages' AND column_name = 'updated_at') THEN
        ALTER TABLE public.messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
    END IF;
END $$;

-- 4. Create proper indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);  
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_is_read ON public.messages(is_read);

-- 5. Enable RLS if not already enabled
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 6. Drop old RLS policies that might reference appointment_id
DROP POLICY IF EXISTS "Users can view messages from their appointments" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages to their appointments" ON public.messages;
DROP POLICY IF EXISTS "Users can update their received messages" ON public.messages;

-- 7. Create new RLS policies without appointment_id dependency
CREATE POLICY "Users can view their messages" ON public.messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert messages" ON public.messages  
    FOR INSERT WITH CHECK (
        auth.uid() = sender_id
    );

CREATE POLICY "Users can update messages they received" ON public.messages
    FOR UPDATE USING (
        auth.uid() = receiver_id
    );

-- 8. Create new RPC function for marking messages as read (without appointment_id)
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

-- 9. Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_messages_as_read(UUID, UUID) TO authenticated;

-- 10. Create trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_messages_updated_at ON public.messages;
CREATE TRIGGER update_messages_updated_at 
    BEFORE UPDATE ON public.messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Final verification - show current messages table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'messages' 
ORDER BY ordinal_position;