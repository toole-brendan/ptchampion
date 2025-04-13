-- +migrate Up
-- Enable PostGIS extension if not already enabled
CREATE EXTENSION IF NOT EXISTS postgis;

-- +migrate Down
-- Optional: Script to disable the extension (be cautious)
-- DROP EXTENSION IF EXISTS postgis;
-- It's often safer to leave the extension enabled once added. 