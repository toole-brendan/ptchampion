-- Update existing users to set display_name = username (Option A)
UPDATE users 
SET display_name = username 
WHERE display_name IS NULL OR display_name = '';

-- Ensure all future updates maintain this relationship through a trigger
CREATE OR REPLACE FUNCTION update_display_name_from_username()
RETURNS TRIGGER AS $$
BEGIN
    NEW.display_name = NEW.username;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for INSERT operations
DROP TRIGGER IF EXISTS set_display_name_on_insert ON users;
CREATE TRIGGER set_display_name_on_insert
BEFORE INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION update_display_name_from_username();

-- Create trigger for UPDATE operations that change username
DROP TRIGGER IF EXISTS set_display_name_on_update ON users;
CREATE TRIGGER set_display_name_on_update
BEFORE UPDATE ON users
FOR EACH ROW
WHEN (NEW.username IS DISTINCT FROM OLD.username)
EXECUTE FUNCTION update_display_name_from_username(); 