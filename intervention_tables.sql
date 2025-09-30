-- Chat messages table for storing conversation history
CREATE TABLE IF NOT EXISTS public.chat_messages (
    message_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    message_content TEXT NOT NULL,
    sender VARCHAR(10) NOT NULL CHECK (sender IN ('user', 'bot')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_chat_messages_user_time (user_id, created_at)
);

-- Intervention logs table for tracking intervention triggers
CREATE TABLE IF NOT EXISTS public.intervention_logs (
    log_id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    intervention_level VARCHAR(20) NOT NULL CHECK (intervention_level IN ('moderate', 'high')),
    trigger_message TEXT NOT NULL,
    triggered_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_intervention_logs_user_time (user_id, triggered_at)
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_user_id ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_intervention_logs_user_id ON public.intervention_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_intervention_logs_triggered_at ON public.intervention_logs(triggered_at);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intervention_logs ENABLE ROW LEVEL SECURITY;

-- Policy for chat_messages - users can only see their own messages
CREATE POLICY "Users can view own chat messages" ON public.chat_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own chat messages" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can update messages they received" 
ON messages FOR UPDATE 
USING (auth.uid()::text = receiver_id);

CREATE POLICY "Users can delete own chat messages" ON public.chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Policy for intervention_logs - users can only see their own logs
CREATE POLICY "Users can view own intervention logs" ON public.intervention_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own intervention logs" ON public.intervention_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function to automatically clean old chat messages (for privacy)
CREATE OR REPLACE FUNCTION clean_old_chat_messages()
RETURNS void AS $$
BEGIN
    DELETE FROM public.chat_messages 
    WHERE created_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Function to automatically clean old intervention logs
CREATE OR REPLACE FUNCTION clean_old_intervention_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM public.intervention_logs 
    WHERE triggered_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean old data (if using pg_cron extension)
-- SELECT cron.schedule('clean-chat-messages', '0 2 * * *', 'SELECT clean_old_chat_messages();');
-- SELECT cron.schedule('clean-intervention-logs', '0 3 * * *', 'SELECT clean_old_intervention_logs();'); 