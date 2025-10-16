-- Fix for appointments with invalid counselor_id (0 or NULL)
-- This addresses the error: "Looking for counselor with counselor_id: 0"

-- First, let's check for problematic appointments
SELECT 
    appointment_id,
    counselor_id,
    user_id,
    appointment_date,
    status,
    notes
FROM counseling_appointments 
WHERE counselor_id <= 0 OR counselor_id IS NULL;

-- Option 1: If there are valid counselors in the system, assign a default counselor
-- You'll need to replace '1' with an actual counselor_id from your counselors table
-- First check what counselors exist:
-- SELECT counselor_id, first_name, last_name, email FROM counselors LIMIT 5;

-- Then update the problematic appointments (uncomment and modify as needed):
-- UPDATE counseling_appointments 
-- SET counselor_id = 1  -- Replace with actual counselor_id
-- WHERE counselor_id <= 0 OR counselor_id IS NULL;

-- Option 2: If these appointments should be deleted (use with caution):
-- DELETE FROM counseling_appointments 
-- WHERE counselor_id <= 0 OR counselor_id IS NULL;

-- Option 3: If you want to keep the appointments but mark them as cancelled:
-- UPDATE counseling_appointments 
-- SET status = 'cancelled',
--     notes = COALESCE(notes, '') || ' [System: Invalid counselor assignment]'
-- WHERE counselor_id <= 0 OR counselor_id IS NULL;

-- After fixing, verify the fix:
-- SELECT COUNT(*) as invalid_appointments 
-- FROM counseling_appointments 
-- WHERE counselor_id <= 0 OR counselor_id IS NULL;

-- Also check if there are any messages for these appointments that need attention:
SELECT 
    m.appointment_id,
    COUNT(*) as message_count,
    ca.counselor_id,
    ca.status
FROM messages m
JOIN counseling_appointments ca ON m.appointment_id = ca.appointment_id
WHERE ca.counselor_id <= 0 OR ca.counselor_id IS NULL
GROUP BY m.appointment_id, ca.counselor_id, ca.status;