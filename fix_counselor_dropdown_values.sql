-- Fix any typos in counselor specialization values
-- This will correct "advicing" to "Academic Advising" in the counselors table

UPDATE public.counselors 
SET specialization = 'Academic Advising' 
WHERE specialization = 'advicing';

-- Also check for other common typos and fix them
UPDATE public.counselors 
SET specialization = 'Academic Counseling' 
WHERE specialization ILIKE '%academic%' AND specialization != 'Academic Counseling' AND specialization != 'Academic Advising';

UPDATE public.counselors 
SET specialization = 'Career Counseling' 
WHERE specialization ILIKE '%career%' AND specialization != 'Career Counseling';

UPDATE public.counselors 
SET specialization = 'Mental Health Counseling' 
WHERE specialization ILIKE '%mental%' AND specialization != 'Mental Health Counseling';

-- Ensure availability_status only contains valid values
UPDATE public.counselors 
SET availability_status = 'available' 
WHERE availability_status NOT IN ('available', 'busy', 'away', 'offline') OR availability_status IS NULL;