-- Script to add the missing tokens_invalidated_at column to the users table

-- Add tokens_invalidated_at column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'tokens_invalidated_at') THEN
        ALTER TABLE users ADD COLUMN tokens_invalidated_at TIMESTAMP;
        RAISE NOTICE 'Added tokens_invalidated_at column to users table';
    ELSE
        RAISE NOTICE 'tokens_invalidated_at column already exists in users table';
    END IF;
END $$;

-- Check if the column was added successfully
DO $$
DECLARE
    has_column BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'users' AND column_name = 'tokens_invalidated_at') INTO has_column;
    
    IF has_column THEN
        RAISE NOTICE '✅ tokens_invalidated_at column exists in users table';
    ELSE
        RAISE NOTICE '❌ Failed to add tokens_invalidated_at column to users table';
    END IF;
END $$; 