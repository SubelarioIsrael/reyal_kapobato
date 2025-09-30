-- Fix Row Level Security policies for messages table
-- This allows users to update messages they received

-- Enable RLS on messages table (ensure it's enabled)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can update messages they received" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages they sent" ON public.messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;

-- Allow users to update messages where they are the receiver (for marking as read)
-- This is the key policy for students marking counselor messages as read
CREATE POLICY "Users can update messages they received" 
ON public.messages FOR UPDATE 
TO authenticated
USING (auth.uid()::text = receiver_id)
WITH CHECK (auth.uid()::text = receiver_id);

-- Also allow users to update their own sent messages (for future features like editing)
CREATE POLICY "Users can update messages they sent" 
ON public.messages FOR UPDATE 
TO authenticated
USING (auth.uid()::text = sender_id)
WITH CHECK (auth.uid()::text = sender_id);

-- Create a function to mark messages as read (alternative approach)
CREATE OR REPLACE FUNCTION public.mark_messages_read(
    p_appointment_id INTEGER,
    p_user_id TEXT
) RETURNS INTEGER AS $$
DECLARE
    update_count INTEGER;
BEGIN
    UPDATE public.messages 
    SET is_read = true 
    WHERE appointment_id = p_appointment_id 
      AND receiver_id = p_user_id::uuid 
      AND is_read = false;
    
    GET DIAGNOSTICS update_count = ROW_COUNT;
    RETURN update_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.mark_messages_read TO authenticated;

-- Also grant necessary permissions on the table
GRANT SELECT, UPDATE ON public.messages TO authenticated;

-- Verify current policies (run this separately to check results)
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
-- FROM pg_policies 
-- WHERE tablename = 'messages';