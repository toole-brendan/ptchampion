-- Fix the database schema issues

-- 1. Rename password column to password_hash if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'users' AND column_name = 'password') THEN
        ALTER TABLE users RENAME COLUMN password TO password_hash;
    END IF;
END $$;

-- 2. Add display_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'display_name') THEN
        ALTER TABLE users ADD COLUMN display_name VARCHAR(255);
    END IF;
END $$;

-- Fix for missing display_name column error
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Fix for missing grade column error
ALTER TABLE user_exercises ADD COLUMN IF NOT EXISTS grade INTEGER;

-- Print success message
DO $$
BEGIN
    RAISE NOTICE 'Database schema migration completed successfully.';
END $$; 