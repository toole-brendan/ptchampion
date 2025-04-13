-- +migrate Up
ALTER TABLE users
ADD COLUMN last_location GEOGRAPHY(Point, 4326); -- SRID 4326 for WGS 84 (standard lat/lon)

-- Add a spatial index for efficient proximity queries
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST (last_location);

-- +migrate Down
-- Drop the index first if it exists
DROP INDEX IF EXISTS idx_users_location;

-- Then drop the column
ALTER TABLE users
DROP COLUMN IF EXISTS last_location; 