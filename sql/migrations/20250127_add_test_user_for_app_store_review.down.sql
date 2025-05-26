-- +migrate Down
-- Remove test user for App Store review

DO $$
DECLARE
    test_email TEXT := 'testuser@ptchampion.ai';
    deleted_count INTEGER;
BEGIN
    -- Delete the test user by email
    DELETE FROM users WHERE email = test_email;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    
    IF deleted_count > 0 THEN
        RAISE NOTICE '✅ Test user removed: %', test_email;
    ELSE
        RAISE NOTICE '⚠️  Test user not found: %', test_email;
    END IF;
END $$; 