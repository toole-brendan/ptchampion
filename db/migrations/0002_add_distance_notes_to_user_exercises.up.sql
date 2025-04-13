-- Add distance column
ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS distance INT NULL;

-- Add notes column
ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS notes TEXT NULL;

-- Add index on distance column (optional)
CREATE INDEX IF NOT EXISTS idx_user_exercises_distance ON user_exercises(distance);
