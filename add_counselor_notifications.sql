-- Add notifications_enabled column to counselors table
ALTER TABLE counselors 
ADD COLUMN notifications_enabled BOOLEAN DEFAULT TRUE;

-- Update existing counselors to have notifications enabled by default
UPDATE counselors 
SET notifications_enabled = TRUE 
WHERE notifications_enabled IS NULL;