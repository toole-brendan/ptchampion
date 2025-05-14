-- Migration: Add first_name and last_name fields to users table
-- Replace display_name with separate first_name and last_name fields

-- Add new columns if they don't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'first_name') THEN
        ALTER TABLE users ADD COLUMN first_name TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'users' AND column_name = 'last_name') THEN
        ALTER TABLE users ADD COLUMN last_name TEXT;
    END IF;
END $$;

-- Backfill data from display_name to first_name and last_name
UPDATE users 
SET 
  first_name = CASE 
                WHEN display_name IS NOT NULL AND display_name <> '' 
                THEN split_part(display_name, ' ', 1) 
                ELSE username 
              END,
  last_name = CASE 
               WHEN display_name LIKE '% %' 
               THEN SUBSTRING(display_name FROM POSITION(' ' IN display_name)+1) 
               ELSE '' 
              END;

-- Remove triggers that auto-set display_name
DROP TRIGGER IF EXISTS set_display_name_on_insert ON users;
DROP TRIGGER IF EXISTS set_display_name_on_update ON users;
DROP FUNCTION IF EXISTS update_display_name_from_username();

-- Drop the old display_name column
ALTER TABLE users DROP COLUMN IF EXISTS display_name; 