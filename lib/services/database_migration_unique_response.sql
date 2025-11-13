-- Database Migration: Add UNIQUE constraint to questionnaire_summaries.response_id
-- This prevents duplicate summary entries for the same questionnaire response

-- Add UNIQUE constraint to response_id column in questionnaire_summaries table
-- This ensures each questionnaire response can only have one summary
ALTER TABLE public.questionnaire_summaries
ADD CONSTRAINT questionnaire_summaries_response_id_key UNIQUE (response_id);

-- Note: If there are existing duplicate entries, you'll need to clean them up first:
-- 
-- To find duplicates:
-- SELECT response_id, COUNT(*) 
-- FROM questionnaire_summaries 
-- GROUP BY response_id 
-- HAVING COUNT(*) > 1;
--
-- To remove duplicates (keeping only the first one):
-- DELETE FROM questionnaire_summaries
-- WHERE summary_id NOT IN (
--   SELECT MIN(summary_id)
--   FROM questionnaire_summaries
--   GROUP BY response_id
-- );
