-- +migrate Up
-- Add realistic workout history for John Smith demo user

DO $$
DECLARE
    mock_user_id INTEGER;
BEGIN
    -- Get the mock user ID
    SELECT id INTO mock_user_id FROM users WHERE email = 'john.smith@example.com';
    
    -- Only proceed if user exists
    IF mock_user_id IS NOT NULL THEN
        -- Clear any existing workouts for this user to ensure clean demo data
        DELETE FROM workouts WHERE user_id = mock_user_id;
        
        -- Add Push-up workouts (showing progression)
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, form_score, grade, completed_at, created_at) VALUES
        -- Most recent (yesterday)
        (mock_user_id, 1, 'pushup', 75, 95, 100, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        -- 3 days ago
        (mock_user_id, 1, 'pushup', 72, 93, 100, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        -- 5 days ago
        (mock_user_id, 1, 'pushup', 70, 91, 98, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
        -- 1 week ago
        (mock_user_id, 1, 'pushup', 68, 90, 96, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days');
        
        -- Add Sit-up workouts
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, form_score, grade, completed_at, created_at) VALUES
        -- Most recent (2 days ago)
        (mock_user_id, 2, 'situp', 82, 92, 100, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        -- 4 days ago
        (mock_user_id, 2, 'situp', 80, 90, 100, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
        -- 6 days ago
        (mock_user_id, 2, 'situp', 78, 88, 98, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        -- 8 days ago
        (mock_user_id, 2, 'situp', 76, 87, 96, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days');
        
        -- Add Pull-up workouts
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, form_score, grade, completed_at, created_at) VALUES
        -- Most recent (2 days ago)
        (mock_user_id, 3, 'pullup', 18, 88, 90, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        -- 4 days ago
        (mock_user_id, 3, 'pullup', 16, 86, 85, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
        -- 6 days ago
        (mock_user_id, 3, 'pullup', 15, 85, 82, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        -- 9 days ago
        (mock_user_id, 3, 'pullup', 14, 84, 80, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days');
        
        -- Add Running workouts (2-mile run)
        -- Duration in seconds, distance in meters (2 miles = 3218.69 meters)
        INSERT INTO workouts (user_id, exercise_id, exercise_type, duration_seconds, form_score, grade, completed_at, created_at) VALUES
        -- Most recent (3 days ago) - 13:30 (810 seconds)
        (mock_user_id, 4, 'run', 810, 95, 94, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        -- 6 days ago - 13:45 (825 seconds)
        (mock_user_id, 4, 'run', 825, 93, 92, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        -- 10 days ago - 14:00 (840 seconds)
        (mock_user_id, 4, 'run', 840, 90, 90, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days');
        
        -- Also add to user_exercises table for backward compatibility
        INSERT INTO user_exercises (user_id, exercise_id, repetitions, time_in_seconds, form_score, grade, completed, created_at) 
        SELECT 
            user_id, 
            exercise_id, 
            repetitions, 
            duration_seconds as time_in_seconds,
            form_score, 
            grade, 
            true as completed,
            completed_at as created_at
        FROM workouts 
        WHERE user_id = mock_user_id
        ON CONFLICT (user_id, exercise_id, created_at) DO NOTHING;
        
        RAISE NOTICE 'Added workout history for John Smith (user_id: %)', mock_user_id;
        RAISE NOTICE 'Total workouts added: %', (SELECT COUNT(*) FROM workouts WHERE user_id = mock_user_id);
    ELSE
        RAISE WARNING 'John Smith user not found. Please run the user creation migration first.';
    END IF;
END $$;