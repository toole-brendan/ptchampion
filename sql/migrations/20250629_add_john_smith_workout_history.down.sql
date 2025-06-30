-- +migrate Down
-- Remove workout history for John Smith demo user

DO $$
DECLARE
    mock_user_id INTEGER;
BEGIN
    -- Get the mock user ID
    SELECT id INTO mock_user_id FROM users WHERE email = 'john.smith@example.com';
    
    -- If user exists, remove their workout data
    IF mock_user_id IS NOT NULL THEN
        DELETE FROM workouts WHERE user_id = mock_user_id;
        DELETE FROM user_exercises WHERE user_id = mock_user_id;
        
        RAISE NOTICE 'Removed workout history for John Smith (user_id: %)', mock_user_id;
    END IF;
END $$;