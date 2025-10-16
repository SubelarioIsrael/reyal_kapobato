-- Fix RLS policies for messages table to ensure real-time subscriptions work properly
-- This addresses issues with data type mismatches and real-time filtering

-- First, drop all existing policies to start fresh
DROP POLICY IF EXISTS "Users can view messages they are involved in" ON public.messages;
DROP POLICY IF EXISTS "Users can insert messages as sender" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they received" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they sent" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

-- Ensure RLS is enabled
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Create correct SELECT policy for real-time subscriptions
-- This is crucial for real-time subscriptions to work properly
-- Note: Ensuring proper UUID comparison for RLS policy
CREATE POLICY "messages_select_policy" ON public.messages
    FOR SELECT 
    TO authenticated
    USING (
        auth.uid()::text = sender_id::text OR auth.uid()::text = receiver_id::text
    );

-- Create INSERT policy
CREATE POLICY "messages_insert_policy" ON public.messages
    FOR INSERT 
    TO authenticated
    WITH CHECK (auth.uid() = sender_id);

-- Create UPDATE policy for marking messages as read
-- This allows students to mark counselor messages as read
-- Note: Ensuring proper UUID comparison for RLS policy
CREATE POLICY "messages_update_policy" ON public.messages
    FOR UPDATE 
    TO authenticated
    USING (
        auth.uid()::text = receiver_id::text OR auth.uid()::text = sender_id::text
    )
    WITH CHECK (
        auth.uid()::text = receiver_id::text OR auth.uid()::text = sender_id::text
    );

-- Grant necessary permissions for real-time subscriptions
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT USAGE ON SEQUENCE messages_id_seq TO authenticated;

-- Enable realtime for the messages table
ALTER publication supabase_realtime ADD TABLE public.messages;