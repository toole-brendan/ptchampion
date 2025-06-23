-- +migrate Up
-- Add mock user for development login (5 clicks on logo)
-- This migration is idempotent and safe to run multiple times

DO $$
DECLARE
    mock_email TEXT := 'mock@example.com';
    mock_username TEXT := 'mockuser';
    mock_password_hash TEXT := '$2a$14$vQZBvUfgdq1D.d3y3Jq5V.r0Qw5jLuZGXFp7Uw8kP0oXsB9zHHfRO'; -- mockpassword
    mock_first_name TEXT := 'Mock';
    mock_last_name TEXT := 'User';
    user_exists BOOLEAN;
BEGIN
    -- Check if mock user already exists by email
    SELECT EXISTS(SELECT 1 FROM users WHERE email = mock_email) INTO user_exists;
    
    IF NOT user_exists THEN
        -- Insert the mock user
        INSERT INTO users (
            username,
            email, 
            password_hash,
            first_name,
            last_name,
            created_at,
            updated_at
        ) VALUES (
            mock_username,
            mock_email,
            mock_password_hash,
            mock_first_name,
            mock_last_name,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ Mock user created for development login:';
        RAISE NOTICE '   Email: %', mock_email;
        RAISE NOTICE '   Username: %', mock_username;
        RAISE NOTICE '   Password: mockpassword';
        RAISE NOTICE '   Name: % %', mock_first_name, mock_last_name;
        RAISE NOTICE '   Usage: Click the logo 5 times on login page to auto-login';
    ELSE
        RAISE NOTICE '⚠️  Mock user already exists with email: %', mock_email;
    END IF;
END $$;