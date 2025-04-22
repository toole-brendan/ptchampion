-- Update the existing users table to allow NULL for email, first_name, last_name columns
DO $$
BEGIN
    -- Update email column to allow NULL values
    ALTER TABLE users ALTER COLUMN email DROP NOT NULL;
    RAISE NOTICE 'Made email column nullable';
EXCEPTION
    WHEN undefined_column THEN
        RAISE NOTICE 'email column does not exist or is already nullable';
    WHEN others THEN
        RAISE NOTICE 'Failed to modify email column: %', SQLERRM;
END $$;

DO $$
BEGIN
    -- Update first_name column to allow NULL values
    ALTER TABLE users ALTER COLUMN first_name DROP NOT NULL;
    RAISE NOTICE 'Made first_name column nullable';
EXCEPTION
    WHEN undefined_column THEN
        RAISE NOTICE 'first_name column does not exist or is already nullable';
    WHEN others THEN
        RAISE NOTICE 'Failed to modify first_name column: %', SQLERRM;
END $$;

DO $$
BEGIN
    -- Update last_name column to allow NULL values
    ALTER TABLE users ALTER COLUMN last_name DROP NOT NULL;
    RAISE NOTICE 'Made last_name column nullable';
EXCEPTION
    WHEN undefined_column THEN
        RAISE NOTICE 'last_name column does not exist or is already nullable';
    WHEN others THEN
        RAISE NOTICE 'Failed to modify last_name column: %', SQLERRM;
END $$; 