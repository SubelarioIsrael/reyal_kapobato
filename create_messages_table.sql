-- Create messages table for appointment chat functionality
CREATE TABLE IF NOT EXISTS public.messages (
    message_id SERIAL PRIMARY KEY,
    appointment_id INTEGER NOT NULL REFERENCES counseling_appointments(appointment_id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_appointment_id ON public.messages(appointment_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON public.messages(created_at);

-- Enable RLS (Row Level Security)
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for messages table
-- Users can view messages where they are either sender or receiver
CREATE POLICY "Users can view messages they are involved in" ON public.messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid()::text = receiver_id
    );

-- Users can insert messages where they are the sender
CREATE POLICY "Users can insert messages as sender" ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can update messages they received (for marking as read)
CREATE POLICY "Users can update messages they received" ON public.messages
    FOR UPDATE USING (auth.uid()::text = receiver_id);

-- Users can update messages they sent (for editing, if needed)
CREATE POLICY "Users can update messages they sent" ON public.messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_messages_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to auto-update updated_at
CREATE TRIGGER update_messages_updated_at_trigger
    BEFORE UPDATE ON public.messages
    FOR EACH ROW
    EXECUTE FUNCTION update_messages_updated_at();

-- Create function to mark messages as read (used by RPC call in Flutter app)
CREATE OR REPLACE FUNCTION public.mark_messages_read(
    p_appointment_id INTEGER,
    p_user_id UUID
) RETURNS INTEGER AS $$
DECLARE
    affected_rows INTEGER;
BEGIN
    UPDATE public.messages 
    SET is_read = true, updated_at = CURRENT_TIMESTAMP
    WHERE appointment_id = p_appointment_id 
      AND receiver_id = p_user_id::text 
      AND is_read = false;
    
    GET DIAGNOSTICS affected_rows = ROW_COUNT;
    RETURN affected_rows;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission on the function
GRANT EXECUTE ON FUNCTION public.mark_messages_read TO authenticated;

-- Grant necessary permissions
GRANT SELECT, INSERT, UPDATE ON public.messages TO authenticated;
GRANT SELECT, UPDATE ON SEQUENCE messages_message_id_seq TO authenticated;