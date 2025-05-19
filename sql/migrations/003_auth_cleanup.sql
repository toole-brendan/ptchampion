-- Migration to remove legacy authentication tables and prepare for Redis token storage
-- This migration cleans up any tables that might have been used for token storage
-- as we're moving to Redis for refresh token management

-- Up migration
-- ------------

-- Drop any legacy refresh_tokens table if it exists
DROP TABLE IF EXISTS refresh_tokens;

-- Update users table to track token invalidation timestamp
-- This helps invalidate tokens issued before this timestamp for a user
ALTER TABLE users ADD COLUMN IF NOT EXISTS tokens_invalidated_at TIMESTAMP WITH TIME ZONE;

-- Down migration
-- -------------

-- For rollback, recreate the refresh_tokens table
-- CREATE TABLE IF NOT EXISTS refresh_tokens (
--   id TEXT PRIMARY KEY,
--   user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--   issued_at TIMESTAMP WITH TIME ZONE NOT NULL,
--   expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
--   revoked BOOLEAN DEFAULT FALSE,
--   created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
--   updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
-- );

-- For rollback, remove the tokens_invalidated_at column
-- ALTER TABLE users DROP COLUMN IF EXISTS tokens_invalidated_at; 