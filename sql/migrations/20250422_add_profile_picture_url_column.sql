-- +migrate Up
-- Add profile_picture_url column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'profile_picture_url') THEN
        ALTER TABLE users ADD COLUMN profile_picture_url VARCHAR(1024);
    END IF;
END $$;

-- Add location column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'location') THEN
        ALTER TABLE users ADD COLUMN location VARCHAR(255);
    END IF;
END $$;

-- Add latitude column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'latitude') THEN
        ALTER TABLE users ADD COLUMN latitude NUMERIC(10,7);
    END IF;
END $$;

-- Add longitude column if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                  WHERE table_name = 'users' AND column_name = 'longitude') THEN
        ALTER TABLE users ADD COLUMN longitude NUMERIC(10,7);
    END IF;
END $$;

-- +migrate Down
-- Remove profile_picture_url column if needed
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_name = 'users' AND column_name = 'profile_picture_url') THEN
        ALTER TABLE users DROP COLUMN profile_picture_url;
    END IF;
END $$;

-- Remove location column if needed
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_name = 'users' AND column_name = 'location') THEN
        ALTER TABLE users DROP COLUMN location;
    END IF;
END $$;

-- Remove latitude column if needed
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_name = 'users' AND column_name = 'latitude') THEN
        ALTER TABLE users DROP COLUMN latitude;
    END IF;
END $$;

-- Remove longitude column if needed
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
              WHERE table_name = 'users' AND column_name = 'longitude') THEN
        ALTER TABLE users DROP COLUMN longitude;
    END IF;
END $$; 