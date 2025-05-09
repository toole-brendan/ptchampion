-- Add is_public flag to workouts table
ALTER TABLE workouts ADD COLUMN is_public BOOLEAN NOT NULL DEFAULT false;

-- For testing purposes, make some existing workouts public
UPDATE workouts SET is_public = true WHERE id % 3 = 0;

-- Create index for better query performance when filtering by is_public
CREATE INDEX idx_workouts_is_public ON workouts(is_public) WHERE is_public = true;

-- Create spatial index for faster local leaderboard queries
CREATE INDEX IF NOT EXISTS idx_users_last_location ON users USING GIST (last_location); 