-- Comprehensive fix for messages table UUID issues
-- This script ensures proper UUID handling and removes all appointment_id dependencies

-- 1. First, let's check the current structure of the messages table
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'messages' AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Drop the messages table completely and recreate it with the correct structure
-- (This is safer than trying to alter an existing table with potential data type issues)

-- Backup existing messages if any exist
CREATE TABLE IF NOT EXISTS messages_backup AS SELECT * FROM public.messages;

-- Drop the existing messages table
DROP TABLE IF EXISTS public.messages CASCADE;

-- 3. Create the messages table with the correct structure
CREATE TABLE public.messages (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sender_id UUID NOT NULL,
    receiver_id UUID NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    message_type TEXT DEFAULT 'text',
    created_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT timezone('utc'::text, now())
);

-- 4. Add foreign key constraints
ALTER TABLE public.messages 
ADD CONSTRAINT messages_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

ALTER TABLE public.messages 
ADD CONSTRAINT messages_receiver_id_fkey 
FOREIGN KEY (receiver_id) REFERENCES public.users(user_id) ON DELETE CASCADE;

-- 5. Create optimized indexes for UUID queries
CREATE INDEX idx_messages_sender_id ON public.messages USING btree(sender_id);
CREATE INDEX idx_messages_receiver_id ON public.messages USING btree(receiver_id);
CREATE INDEX idx_messages_created_at ON public.messages USING btree(created_at DESC);
CREATE INDEX idx_messages_conversation ON public.messages USING btree(sender_id, receiver_id, created_at DESC);
CREATE INDEX idx_messages_unread ON public.messages USING btree(receiver_id, is_read, created_at DESC) WHERE is_read = false;

-- 6. Enable Row Level Security
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for direct messaging (no appointment dependencies)
CREATE POLICY "Users can view their messages" ON public.messages
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

-- 8. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Create trigger for updated_at
CREATE TRIGGER update_messages_updated_at_trigger
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_messages_updated_at();

-- 10. Grant permissions
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE messages_id_seq TO authenticated;

-- 11. Restore messages from backup if they exist and are compatible
-- (Only run this manually after checking the backup structure)
-- INSERT INTO public.messages (sender_id, receiver_id, message, is_read, message_type, created_at)
-- SELECT sender_id::UUID, receiver_id::UUID, message, is_read, message_type, created_at
-- FROM messages_backup
-- WHERE sender_id IS NOT NULL AND receiver_id IS NOT NULL;

-- 12. Drop backup table (only after confirming data migration)
-- DROP TABLE IF EXISTS messages_backup;

-- 13. Add helpful comments
COMMENT ON TABLE public.messages IS 'Direct messaging between users without appointment dependencies';
COMMENT ON COLUMN public.messages.sender_id IS 'UUID of the user who sent the message';
COMMENT ON COLUMN public.messages.receiver_id IS 'UUID of the user who received the message';

-- 14. Test the structure
SELECT 
    'Messages table structure verification:' as info,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_name = 'messages' AND table_schema = 'public'
ORDER BY ordinal_position;