-- +migrate Up

-- This migration is idempotent and can be run against a database that already has the email field

-- Ensure users table structure is clean and contains all needed fields
DO $$
BEGIN
    -- Add email column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'email') THEN
        ALTER TABLE users ADD COLUMN email TEXT;
        -- Initially populate email with username (assuming username exists and was used for email)
        UPDATE users SET email = username;
        -- Make email not null and unique
        ALTER TABLE users ALTER COLUMN email SET NOT NULL;
        ALTER TABLE users ADD CONSTRAINT users_email_key UNIQUE (email);
    END IF;
END $$;

-- Ensure username is set properly for display purposes
-- If username column already exists (unlikely), this will ensure it's properly set up
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_name = 'users' AND column_name = 'username') THEN
        -- Username already exists, make sure it has proper constraints
        -- This might fail if there are null usernames, which would need handling
        ALTER TABLE users ALTER COLUMN username SET NOT NULL;
        ALTER TABLE users ADD CONSTRAINT IF NOT EXISTS users_username_key UNIQUE (username);
    END IF;
END $$;

-- Create indexes for email and username columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_email') THEN
        CREATE INDEX idx_users_email ON users(email);
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_users_username') THEN
        CREATE INDEX idx_users_username ON users(username);
    END IF;
END $$;

-- +migrate Down
-- Remove indexes first
DROP INDEX IF EXISTS idx_users_email;
DROP INDEX IF EXISTS idx_users_username;

-- Remove email column constraints
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_email_key;

-- Do not remove the email column as it might break existing data
-- Instead, leave it but make it nullable
ALTER TABLE users ALTER COLUMN email DROP NOT NULL; 