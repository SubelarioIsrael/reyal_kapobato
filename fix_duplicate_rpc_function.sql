-- Fix for the duplicate function name error
-- First drop any existing versions of the mark_messages_read function

-- Drop all existing versions of mark_messages_read function
DROP FUNCTION IF EXISTS mark_messages_read(integer, text);
DROP FUNCTION IF EXISTS mark_messages_read(integer, uuid);
DROP FUNCTION IF EXISTS public.mark_messages_read(integer, text);
DROP FUNCTION IF EXISTS public.mark_messages_read(integer, uuid);

-- Now create the correct version
CREATE OR REPLACE FUNCTION mark_messages_read(
    p_appointment_id integer,
    p_user_id uuid
)
RETURNS integer AS $$
DECLARE
    updated_count integer;
BEGIN
    -- Update messages for the specific appointment where the user is the receiver
    -- and the message is currently unread
    UPDATE messages 
    SET is_read = true
    WHERE 
        appointment_id = p_appointment_id 
        AND receiver_id = p_user_id 
        AND is_read = false;
    
    -- Get the count of updated rows
    GET DIAGNOSTICS updated_count = ROW_COUNT;
    
    -- Return the number of messages that were marked as read
    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION mark_messages_read TO authenticated;

-- Optional: Add a comment to document the function
COMMENT ON FUNCTION mark_messages_read IS 'Marks messages as read for a specific appointment and user. Returns the number of messages updated.';