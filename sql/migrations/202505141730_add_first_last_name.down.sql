-- Down Migration: Revert the separation of first_name and last_name back to display_name

-- Add display_name column if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Backfill display_name from first_name and last_name
UPDATE users 
SET display_name = TRIM(CONCAT(first_name, ' ', last_name))
WHERE first_name IS NOT NULL;

-- For users with empty last_name, just use first_name
UPDATE users
SET display_name = first_name
WHERE last_name = '' OR last_name IS NULL;

-- Recreate the function and triggers that were removed
CREATE OR REPLACE FUNCTION update_display_name_from_username()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.display_name IS NULL OR NEW.display_name = '' THEN
        NEW.display_name = NEW.username;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate insert trigger
DROP TRIGGER IF EXISTS set_display_name_on_insert ON users;
CREATE TRIGGER set_display_name_on_insert
BEFORE INSERT ON users
FOR EACH ROW
WHEN (NEW.display_name IS NULL OR NEW.display_name = '')
EXECUTE FUNCTION update_display_name_from_username();

-- Recreate update trigger
DROP TRIGGER IF EXISTS set_display_name_on_update ON users;
CREATE TRIGGER set_display_name_on_update
BEFORE UPDATE OF username ON users
FOR EACH ROW
WHEN (NEW.display_name IS NULL OR NEW.display_name = '')
EXECUTE FUNCTION update_display_name_from_username();

-- Drop the first_name and last_name columns
ALTER TABLE users DROP COLUMN IF EXISTS first_name;
ALTER TABLE users DROP COLUMN IF EXISTS last_name; 