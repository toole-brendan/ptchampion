-- +migrate Up
-- Update mock user to John Smith with more realistic demo data

-- First, generate the password hash for 'DemoUser123!'
-- Note: This hash is for bcrypt with cost 14
-- The actual hash needs to be generated, but for this migration we'll use a placeholder
-- In production, you'd run: SELECT crypt('DemoUser123!', gen_salt('bf', 14));

DO $$
DECLARE
    mock_user_id INTEGER;
    password_hash_value TEXT;
BEGIN
    -- Generate password hash for 'DemoUser123!'
    password_hash_value := crypt('DemoUser123!', gen_salt('bf', 14));
    
    -- Update existing mock user or insert new one
    INSERT INTO users (
        email, 
        username, 
        first_name, 
        last_name, 
        password_hash,
        gender,
        date_of_birth,
        created_at,
        updated_at
    ) VALUES (
        'john.smith@example.com',
        'jsmith',
        'John',
        'Smith',
        password_hash_value,
        'male',
        '1995-03-15'::DATE,
        NOW(),
        NOW()
    )
    ON CONFLICT (email) 
    DO UPDATE SET
        username = EXCLUDED.username,
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        password_hash = EXCLUDED.password_hash,
        gender = EXCLUDED.gender,
        date_of_birth = EXCLUDED.date_of_birth,
        updated_at = NOW()
    RETURNING id INTO mock_user_id;

    -- Also update the old mock user email if it exists
    UPDATE users 
    SET email = 'john.smith@example.com',
        username = 'jsmith',
        first_name = 'John',
        last_name = 'Smith',
        password_hash = password_hash_value,
        gender = 'male',
        date_of_birth = '1995-03-15'::DATE,
        updated_at = NOW()
    WHERE email = 'mock@example.com';

    -- Output the credentials for reference
    RAISE NOTICE 'Demo user created/updated:';
    RAISE NOTICE '  Email: john.smith@example.com';
    RAISE NOTICE '  Password: DemoUser123!';
    RAISE NOTICE '  Username: jsmith';
END $$;