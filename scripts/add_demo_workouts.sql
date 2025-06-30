-- Add demo workouts for John Smith and other users
-- This version is compatible with the actual production schema

DO $$
DECLARE
    john_id INTEGER;
    sarah_id INTEGER;
    mike_id INTEGER;
    emily_id INTEGER;
BEGIN
    -- Get John Smith's ID
    SELECT id INTO john_id FROM users WHERE email = 'john.smith@example.com';
    
    IF john_id IS NOT NULL THEN
        -- Clear existing workouts for John
        DELETE FROM workouts WHERE user_id = john_id;
        
        -- Add Push-up workouts
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, completed_at, created_at) VALUES
        (john_id, 1, 'pushup', 75, 100, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        (john_id, 1, 'pushup', 72, 100, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (john_id, 1, 'pushup', 70, 98, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
        (john_id, 1, 'pushup', 68, 96, NOW() - INTERVAL '7 days', NOW() - INTERVAL '7 days');
        
        -- Add Sit-up workouts
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, completed_at, created_at) VALUES
        (john_id, 2, 'situp', 82, 100, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (john_id, 2, 'situp', 80, 100, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
        (john_id, 2, 'situp', 78, 98, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        (john_id, 2, 'situp', 76, 96, NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days');
        
        -- Add Pull-up workouts
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, completed_at, created_at) VALUES
        (john_id, 3, 'pullup', 18, 90, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (john_id, 3, 'pullup', 16, 85, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
        (john_id, 3, 'pullup', 15, 82, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        (john_id, 3, 'pullup', 14, 80, NOW() - INTERVAL '9 days', NOW() - INTERVAL '9 days');
        
        -- Add Running workouts (2-mile run)
        INSERT INTO workouts (user_id, exercise_id, exercise_type, duration_seconds, grade, completed_at, created_at) VALUES
        (john_id, 4, 'run', 810, 94, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (john_id, 4, 'run', 825, 92, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        (john_id, 4, 'run', 840, 90, NOW() - INTERVAL '10 days', NOW() - INTERVAL '10 days');
        
        RAISE NOTICE 'Added workouts for John Smith (ID: %)', john_id;
    END IF;
    
    -- Get other demo users
    SELECT id INTO sarah_id FROM users WHERE email = 'sarah.johnson@example.com';
    SELECT id INTO mike_id FROM users WHERE email = 'mike.williams@example.com';
    SELECT id INTO emily_id FROM users WHERE email = 'emily.davis@example.com';
    
    -- Add workouts for Sarah
    IF sarah_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, duration_seconds, grade, completed_at, created_at) VALUES
        (sarah_id, 1, 'pushup', 80, NULL, 100, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (sarah_id, 2, 'situp', 85, NULL, 100, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (sarah_id, 3, 'pullup', 12, NULL, 95, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (sarah_id, 4, 'run', NULL, 780, 98, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days');
        RAISE NOTICE 'Added workouts for Sarah Johnson (ID: %)', sarah_id;
    END IF;

    -- Add workouts for Mike
    IF mike_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, duration_seconds, grade, completed_at, created_at) VALUES
        (mike_id, 1, 'pushup', 65, NULL, 92, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        (mike_id, 2, 'situp', 70, NULL, 88, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (mike_id, 3, 'pullup', 15, NULL, 88, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (mike_id, 4, 'run', NULL, 870, 86, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days');
        RAISE NOTICE 'Added workouts for Mike Williams (ID: %)', mike_id;
    END IF;

    -- Add workouts for Emily
    IF emily_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, duration_seconds, grade, completed_at, created_at) VALUES
        (emily_id, 1, 'pushup', 85, NULL, 100, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),
        (emily_id, 2, 'situp', 90, NULL, 100, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        (emily_id, 3, 'pullup', 20, NULL, 100, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (emily_id, 4, 'run', NULL, 720, 100, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');
        RAISE NOTICE 'Added workouts for Emily Davis (ID: %)', emily_id;
    END IF;
END $$;

-- Show summary
SELECT u.email, u.username, COUNT(w.id) as workout_count, MAX(w.grade) as best_grade
FROM users u
LEFT JOIN workouts w ON u.id = w.user_id
WHERE u.email IN ('john.smith@example.com', 'sarah.johnson@example.com', 'mike.williams@example.com', 'emily.davis@example.com')
GROUP BY u.email, u.username
ORDER BY u.email;