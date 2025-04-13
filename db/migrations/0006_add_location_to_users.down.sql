-- +migrate Up
-- Corresponding up migration adds the column and index.

-- +migrate Down
-- Drop the index first if it exists
DROP INDEX IF EXISTS idx_users_location;

-- Then drop the column
ALTER TABLE users
DROP COLUMN IF EXISTS last_location; 