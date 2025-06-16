-- Remove gender and date_of_birth columns from users table
ALTER TABLE users 
  DROP CONSTRAINT IF EXISTS check_gender,
  DROP CONSTRAINT IF EXISTS check_date_of_birth;

-- Drop the optional index if it was created
-- DROP INDEX IF EXISTS idx_users_gender;

ALTER TABLE users 
  DROP COLUMN IF EXISTS gender,
  DROP COLUMN IF EXISTS date_of_birth; 