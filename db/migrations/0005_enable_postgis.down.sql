-- +migrate Up
-- This file is intentionally left blank for the down migration.
-- The corresponding up migration enables the PostGIS extension.
-- It is generally safer not to automatically drop extensions like PostGIS.

-- +migrate Down
-- Script to disable the extension (use with caution)
-- DROP EXTENSION IF EXISTS postgis; 