-- Ensure all required columns exist in the users table for registration

-- Add email column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'email') THEN
        ALTER TABLE users ADD COLUMN email VARCHAR(255);
        RAISE NOTICE 'Added email column';
    ELSE
        RAISE NOTICE 'email column already exists';
    END IF;
END $$;

-- Add first_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'first_name') THEN
        ALTER TABLE users ADD COLUMN first_name VARCHAR(255);
        RAISE NOTICE 'Added first_name column';
    ELSE
        RAISE NOTICE 'first_name column already exists';
    END IF;
END $$;

-- Add last_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'last_name') THEN
        ALTER TABLE users ADD COLUMN last_name VARCHAR(255);
        RAISE NOTICE 'Added last_name column';
    ELSE
        RAISE NOTICE 'last_name column already exists';
    END IF;
END $$;

-- Check if all required columns exist for registration
DO $$
DECLARE
    has_email BOOLEAN;
    has_first_name BOOLEAN;
    has_last_name BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email') INTO has_email;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'first_name') INTO has_first_name;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_name') INTO has_last_name;
    
    RAISE NOTICE 'COLUMN VERIFICATION SUMMARY:';
    RAISE NOTICE 'email: %', has_email;
    RAISE NOTICE 'first_name: %', has_first_name;
    RAISE NOTICE 'last_name: %', has_last_name;
    
    IF has_email AND has_first_name AND has_last_name THEN
        RAISE NOTICE '✅ All required registration columns exist in users table.';
    ELSE
        RAISE NOTICE '❌ Some registration columns are missing in users table!';
    END IF;
END $$; 