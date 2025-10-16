-- Create RPC function to mark messages as read for better real-time updates
-- This function is used by the appointment chat to mark messages as read reliably

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
    SET is_read = true,
        updated_at = now()  -- Optional: add updated_at if you have this column
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