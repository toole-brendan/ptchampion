-- Add gender and date_of_birth columns to users table for USMC PFT scoring
ALTER TABLE users 
  ADD COLUMN gender TEXT,
  ADD COLUMN date_of_birth DATE;

-- Add a check constraint to ensure gender is one of the allowed values
ALTER TABLE users 
  ADD CONSTRAINT check_gender 
  CHECK (gender IN ('male', 'female') OR gender IS NULL);

-- Add a check constraint to ensure date_of_birth is not in the future
ALTER TABLE users 
  ADD CONSTRAINT check_date_of_birth 
  CHECK (date_of_birth <= CURRENT_DATE OR date_of_birth IS NULL);

-- Create an index on gender for potential future queries
-- (Optional - only if you plan to filter by gender frequently)
-- CREATE INDEX idx_users_gender ON users(gender);

-- Comment: These fields are nullable initially to support existing users
-- The application should prompt users to fill these fields for USMC PFT scoring 