-- +migrate Down
-- Drop the specialized K-NN index
DROP INDEX IF EXISTS idx_users_location_knn;

-- Recreate the original index if needed
CREATE INDEX IF NOT EXISTS idx_users_location ON users USING GIST (last_location);
