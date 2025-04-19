-- +migrate Up
-- Create a specialized index for K-NN operations (<-> operator)

-- Drop the existing index if needed to recreate it with better properties
DROP INDEX IF EXISTS idx_users_location;

-- Create a new GiST index optimized for K-NN searches (distance operator)
CREATE INDEX idx_users_location_knn ON users USING GIST (last_location);

-- Add a comment explaining the purpose of this index
COMMENT ON INDEX idx_users_location_knn IS 'Specialized index for K-NN operations and spatial queries on user locations';
