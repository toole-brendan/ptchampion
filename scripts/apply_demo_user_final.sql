-- Final Azure-compatible demo user migrations
-- This version handles existing data and missing columns

-- 1. Update existing mock user to John Smith
DO $$
DECLARE
    mock_user_id INTEGER;
    password_hash_value TEXT;
BEGIN
    -- Pre-computed bcrypt hash for 'DemoUser123!' with cost factor 14
    password_hash_value := '$2a$14$5ZQqHxJlJ3K6fK2Z9XYKFOqGqPQ6TqDwK7MXfLALmLrBx8rOgQDPe';
    
    -- Update the existing mock@example.com user to become John Smith
    UPDATE users 
    SET username = 'jsmith',
        first_name = 'John',
        last_name = 'Smith',
        password_hash = password_hash_value,
        gender = 'male',
        date_of_birth = '1995-03-15'::DATE,
        updated_at = NOW()
    WHERE email = 'mock@example.com'
    RETURNING id INTO mock_user_id;

    -- Update email last to avoid conflicts
    UPDATE users
    SET email = 'john.smith@example.com'
    WHERE id = mock_user_id;

    RAISE NOTICE 'Demo user updated:';
    RAISE NOTICE '  Email: john.smith@example.com';
    RAISE NOTICE '  Password: DemoUser123!';
    RAISE NOTICE '  Username: jsmith';
    RAISE NOTICE '  User ID: %', mock_user_id;
END $$;

-- 2. Add workout history for John Smith
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
        
        RAISE NOTICE 'Added workout history for John Smith (user_id: %)', mock_user_id;
        RAISE NOTICE 'Total workouts added: %', (SELECT COUNT(*) FROM workouts WHERE user_id = mock_user_id);
    ELSE
        RAISE WARNING 'John Smith user not found. Please run the user creation migration first.';
    END IF;
END $$;

-- 3. Update John Smith's profile for leaderboard
DO $$
DECLARE
    john_id INTEGER;
BEGIN
    -- Update John Smith with location data and profile info
    UPDATE users 
    SET 
        location = 'Fort Bragg, NC',
        latitude = 35.1392,
        longitude = -78.9946,
        profile_picture_url = 'https://api.dicebear.com/7.x/avataaars/svg?seed=john-smith',
        updated_at = NOW()
    WHERE email = 'john.smith@example.com'
    RETURNING id INTO john_id;

    RAISE NOTICE 'Updated John Smith profile with location data';
END $$;

-- 4. Create additional demo users for leaderboard (simplified)
DO $$
DECLARE
    sarah_id INTEGER;
    mike_id INTEGER;
    emily_id INTEGER;
    password_hash_value TEXT;
BEGIN
    -- Same password hash for all demo users
    password_hash_value := '$2a$14$5ZQqHxJlJ3K6fK2Z9XYKFOqGqPQ6TqDwK7MXfLALmLrBx8rOgQDPe';

    -- User 2: Sarah Johnson - Fort Bragg area
    INSERT INTO users (
        email, username, first_name, last_name, password_hash,
        gender, date_of_birth, location, latitude, longitude,
        profile_picture_url, created_at, updated_at
    ) VALUES (
        'sarah.johnson@example.com',
        'sjohnson',
        'Sarah',
        'Johnson',
        password_hash_value,
        'female',
        '1993-07-22'::DATE,
        'Fort Bragg, NC',
        35.1522,
        -78.8967,
        'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah-johnson',
        NOW() - INTERVAL '6 months',
        NOW()
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO sarah_id;

    -- User 3: Mike Williams - Fort Bragg area
    INSERT INTO users (
        email, username, first_name, last_name, password_hash,
        gender, date_of_birth, location, latitude, longitude,
        profile_picture_url, created_at, updated_at
    ) VALUES (
        'mike.williams@example.com',
        'mwilliams',
        'Mike',
        'Williams',
        password_hash_value,
        'male',
        '1990-11-03'::DATE,
        'Fayetteville, NC',
        35.0527,
        -78.8784,
        'https://api.dicebear.com/7.x/avataaars/svg?seed=mike-williams',
        NOW() - INTERVAL '8 months',
        NOW()
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO mike_id;

    -- User 4: Emily Davis - Different location for global leaderboard
    INSERT INTO users (
        email, username, first_name, last_name, password_hash,
        gender, date_of_birth, location, latitude, longitude,
        profile_picture_url, created_at, updated_at
    ) VALUES (
        'emily.davis@example.com',
        'edavis',
        'Emily',
        'Davis',
        password_hash_value,
        'female',
        '1997-02-14'::DATE,
        'Fort Hood, TX',
        31.1351,
        -97.7845,
        'https://api.dicebear.com/7.x/avataaars/svg?seed=emily-davis',
        NOW() - INTERVAL '4 months',
        NOW()
    )
    ON CONFLICT (email) DO NOTHING
    RETURNING id INTO emily_id;

    -- Add workouts for Sarah
    IF sarah_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, duration_seconds, form_score, grade, completed_at, created_at) VALUES
        (sarah_id, 1, 'pushup', 80, NULL, 96, 100, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (sarah_id, 2, 'situp', 85, NULL, 94, 100, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (sarah_id, 3, 'pullup', 12, NULL, 90, 95, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (sarah_id, 4, 'run', NULL, 780, 96, 98, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days');
    END IF;

    -- Add workouts for Mike
    IF mike_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, duration_seconds, form_score, grade, completed_at, created_at) VALUES
        (mike_id, 1, 'pushup', 65, NULL, 88, 92, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        (mike_id, 2, 'situp', 70, NULL, 85, 88, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (mike_id, 3, 'pullup', 15, NULL, 92, 88, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (mike_id, 4, 'run', NULL, 870, 90, 86, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days');
    END IF;

    -- Add workouts for Emily
    IF emily_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, duration_seconds, form_score, grade, completed_at, created_at) VALUES
        (emily_id, 1, 'pushup', 85, NULL, 98, 100, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),
        (emily_id, 2, 'situp', 90, NULL, 96, 100, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        (emily_id, 3, 'pullup', 20, NULL, 95, 100, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (emily_id, 4, 'run', NULL, 720, 98, 100, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');
    END IF;

    RAISE NOTICE 'Demo users created successfully';
END $$;

-- Summary
SELECT 'Demo Data Summary:' as info
UNION ALL
SELECT '=================='
UNION ALL
SELECT ''
UNION ALL
SELECT 'Users created:'
UNION ALL
SELECT '- john.smith@example.com (Password: DemoUser123!)'
UNION ALL
SELECT '- sarah.johnson@example.com'
UNION ALL
SELECT '- mike.williams@example.com'
UNION ALL
SELECT '- emily.davis@example.com'
UNION ALL
SELECT ''
UNION ALL
SELECT 'Total users: ' || COUNT(*)::text FROM users WHERE email IN ('john.smith@example.com', 'sarah.johnson@example.com', 'mike.williams@example.com', 'emily.davis@example.com')
UNION ALL
SELECT 'Total workouts: ' || COUNT(*)::text FROM workouts WHERE user_id IN (SELECT id FROM users WHERE email IN ('john.smith@example.com', 'sarah.johnson@example.com', 'mike.williams@example.com', 'emily.davis@example.com'));