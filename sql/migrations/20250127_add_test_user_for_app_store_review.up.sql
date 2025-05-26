-- +migrate Up
-- Add test user for App Store review
-- This migration is idempotent and safe to run multiple times

DO $$
DECLARE
    test_email TEXT := 'testuser@ptchampion.ai';
    test_username TEXT := 'testuser';
    test_password_hash TEXT := '$2a$14$T6noL1xxibNzQgDAZuygmOH6Oygem/SMiFtjaLvp0d1yX.6hi3pXK'; -- TestUser123!
    test_first_name TEXT := 'Test';
    test_last_name TEXT := 'User';
    user_exists BOOLEAN;
BEGIN
    -- Check if test user already exists by email
    SELECT EXISTS(SELECT 1 FROM users WHERE email = test_email) INTO user_exists;
    
    IF NOT user_exists THEN
        -- Insert the test user
        INSERT INTO users (
            username,
            email, 
            password_hash,
            first_name,
            last_name,
            created_at,
            updated_at
        ) VALUES (
            test_username,
            test_email,
            test_password_hash,
            test_first_name,
            test_last_name,
            NOW(),
            NOW()
        );
        
        RAISE NOTICE '✅ Test user created for App Store review:';
        RAISE NOTICE '   Email: %', test_email;
        RAISE NOTICE '   Username: %', test_username;
        RAISE NOTICE '   Password: TestUser123!';
        RAISE NOTICE '   Name: % %', test_first_name, test_last_name;
    ELSE
        RAISE NOTICE '⚠️  Test user already exists with email: %', test_email;
    END IF;
END $$; 