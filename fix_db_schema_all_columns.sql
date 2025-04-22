-- Add all required columns to users table

-- 1. Rename password column to password_hash if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'users' AND column_name = 'password') THEN
        ALTER TABLE users RENAME COLUMN password TO password_hash;
        RAISE NOTICE 'Renamed password column to password_hash';
    ELSE
        RAISE NOTICE 'password column already renamed or doesnt exist';
    END IF;
END $$;

-- 2. Add display_name column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'display_name') THEN
        ALTER TABLE users ADD COLUMN display_name VARCHAR(255);
        RAISE NOTICE 'Added display_name column';
    ELSE
        RAISE NOTICE 'display_name column already exists';
    END IF;
END $$;

-- 3. Add profile_picture_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'profile_picture_url') THEN
        ALTER TABLE users ADD COLUMN profile_picture_url VARCHAR(1024);
        RAISE NOTICE 'Added profile_picture_url column';
    ELSE
        RAISE NOTICE 'profile_picture_url column already exists';
    END IF;
END $$;

-- 4. Add location column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'location') THEN
        ALTER TABLE users ADD COLUMN location VARCHAR(255);
        RAISE NOTICE 'Added location column';
    ELSE
        RAISE NOTICE 'location column already exists';
    END IF;
END $$;

-- 5. Add latitude column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'latitude') THEN
        ALTER TABLE users ADD COLUMN latitude VARCHAR(50);
        RAISE NOTICE 'Added latitude column';
    ELSE
        RAISE NOTICE 'latitude column already exists';
    END IF;
END $$;

-- 6. Add longitude column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'longitude') THEN
        ALTER TABLE users ADD COLUMN longitude VARCHAR(50);
        RAISE NOTICE 'Added longitude column';
    ELSE
        RAISE NOTICE 'longitude column already exists';
    END IF;
END $$;

-- 7. Verify all columns exist and print summary
DO $$
DECLARE
    has_password_hash BOOLEAN;
    has_display_name BOOLEAN;
    has_profile_picture_url BOOLEAN;
    has_location BOOLEAN;
    has_latitude BOOLEAN;
    has_longitude BOOLEAN;
BEGIN
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'password_hash') INTO has_password_hash;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'display_name') INTO has_display_name;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'profile_picture_url') INTO has_profile_picture_url;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'location') INTO has_location;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'latitude') INTO has_latitude;
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'longitude') INTO has_longitude;
    
    RAISE NOTICE 'COLUMN VERIFICATION SUMMARY:';
    RAISE NOTICE 'password_hash: %', has_password_hash;
    RAISE NOTICE 'display_name: %', has_display_name;
    RAISE NOTICE 'profile_picture_url: %', has_profile_picture_url;
    RAISE NOTICE 'location: %', has_location;
    RAISE NOTICE 'latitude: %', has_latitude;
    RAISE NOTICE 'longitude: %', has_longitude;
    
    IF has_password_hash AND has_display_name AND has_profile_picture_url AND has_location AND has_latitude AND has_longitude THEN
        RAISE NOTICE '✅ All required columns exist in users table.';
    ELSE
        RAISE NOTICE '❌ Some columns are missing in users table!';
    END IF;
END $$; 