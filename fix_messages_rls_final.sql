-- Comprehensive fix for messages table RLS policies
-- This addresses the persistent notification badge issue by ensuring 
-- proper RLS policies that work with real-time subscriptions

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can mark received messages as read" ON public.messages;
DROP POLICY IF EXISTS "Users can view messages they are involved in" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages as sender" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they sent" ON public.messages;
DROP POLICY IF EXISTS "messages_select_policy" ON public.messages;
DROP POLICY IF EXISTS "messages_insert_policy" ON public.messages;
DROP POLICY IF EXISTS "messages_update_policy" ON public.messages;

-- Ensure RLS is enabled
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- SELECT policy: Essential for real-time subscriptions to work
CREATE POLICY "messages_select" ON public.messages
    FOR SELECT 
    TO authenticated
    USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

-- INSERT policy: Users can only insert messages as the sender
CREATE POLICY "messages_insert" ON public.messages
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = sender_id);

-- UPDATE policy: Users can update messages they sent or received
-- This is crucial for marking messages as read
CREATE POLICY "messages_update" ON public.messages
    FOR UPDATE 
    TO authenticated
    USING (
        auth.uid() = receiver_id OR auth.uid() = sender_id
    )
    WITH CHECK (
        auth.uid() = receiver_id OR auth.uid() = sender_id
    );

-- Ensure proper permissions
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT USAGE ON SEQUENCE messages_id_seq TO authenticated;

-- Enable realtime for the messages table (crucial for notifications)
ALTER publication supabase_realtime ADD TABLE public.messages;