-- +migrate Up
-- Add leaderboard demo data including location and public workouts

DO $$
DECLARE
    john_id INTEGER;
    sarah_id INTEGER;
    mike_id INTEGER;
    emily_id INTEGER;
BEGIN
    -- Update John Smith with location data and profile info
    UPDATE users 
    SET 
        location = 'Fort Bragg, NC',
        latitude = 35.1392,
        longitude = -78.9946,
        last_location = ST_SetSRID(ST_MakePoint(-78.9946, 35.1392), 4326)::geography,
        profile_picture_url = 'https://api.dicebear.com/7.x/avataaars/svg?seed=john-smith',
        updated_at = NOW()
    WHERE email = 'john.smith@example.com'
    RETURNING id INTO john_id;

    -- Make John's existing workouts public for leaderboard
    UPDATE workouts 
    SET is_public = true 
    WHERE user_id = john_id;

    -- Create additional demo users for leaderboard population
    -- User 2: Sarah Johnson - Fort Bragg area
    INSERT INTO users (
        email, username, first_name, last_name, password_hash,
        gender, date_of_birth, location, latitude, longitude, last_location,
        profile_picture_url, created_at, updated_at
    ) VALUES (
        'sarah.johnson@example.com',
        'sjohnson',
        'Sarah',
        'Johnson',
        crypt('DemoUser123!', gen_salt('bf', 14)),
        'female',
        '1993-07-22'::DATE,
        'Fort Bragg, NC',
        35.1522,
        -78.8967,
        ST_SetSRID(ST_MakePoint(-78.8967, 35.1522), 4326)::geography,
        'https://api.dicebear.com/7.x/avataaars/svg?seed=sarah-johnson',
        NOW() - INTERVAL '6 months',
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        location = EXCLUDED.location,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        last_location = EXCLUDED.last_location
    RETURNING id INTO sarah_id;

    -- User 3: Mike Williams - Fort Bragg area
    INSERT INTO users (
        email, username, first_name, last_name, password_hash,
        gender, date_of_birth, location, latitude, longitude, last_location,
        profile_picture_url, created_at, updated_at
    ) VALUES (
        'mike.williams@example.com',
        'mwilliams',
        'Mike',
        'Williams',
        crypt('DemoUser123!', gen_salt('bf', 14)),
        'male',
        '1990-11-03'::DATE,
        'Fayetteville, NC',
        35.0527,
        -78.8784,
        ST_SetSRID(ST_MakePoint(-78.8784, 35.0527), 4326)::geography,
        'https://api.dicebear.com/7.x/avataaars/svg?seed=mike-williams',
        NOW() - INTERVAL '8 months',
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        location = EXCLUDED.location,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        last_location = EXCLUDED.last_location
    RETURNING id INTO mike_id;

    -- User 4: Emily Davis - Different location for global leaderboard
    INSERT INTO users (
        email, username, first_name, last_name, password_hash,
        gender, date_of_birth, location, latitude, longitude, last_location,
        profile_picture_url, created_at, updated_at
    ) VALUES (
        'emily.davis@example.com',
        'edavis',
        'Emily',
        'Davis',
        crypt('DemoUser123!', gen_salt('bf', 14)),
        'female',
        '1997-02-14'::DATE,
        'Fort Hood, TX',
        31.1351,
        -97.7845,
        ST_SetSRID(ST_MakePoint(-97.7845, 31.1351), 4326)::geography,
        'https://api.dicebear.com/7.x/avataaars/svg?seed=emily-davis',
        NOW() - INTERVAL '4 months',
        NOW()
    )
    ON CONFLICT (email) DO UPDATE SET
        location = EXCLUDED.location,
        latitude = EXCLUDED.latitude,
        longitude = EXCLUDED.longitude,
        last_location = EXCLUDED.last_location
    RETURNING id INTO emily_id;

    -- Add public workouts for Sarah (high performer)
    IF sarah_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, form_score, grade, is_public, completed_at, created_at) VALUES
        -- Push-ups
        (sarah_id, 1, 'pushup', 80, 96, 100, true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        (sarah_id, 1, 'pushup', 78, 94, 100, true, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
        -- Sit-ups
        (sarah_id, 2, 'situp', 85, 94, 100, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        (sarah_id, 2, 'situp', 83, 92, 100, true, NOW() - INTERVAL '6 days', NOW() - INTERVAL '6 days'),
        -- Pull-ups
        (sarah_id, 3, 'pullup', 12, 90, 95, true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        -- Running
        (sarah_id, 4, 'run', 780, 96, 98, true, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days');
    END IF;

    -- Add public workouts for Mike (mid-performer)
    IF mike_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, form_score, grade, is_public, completed_at, created_at) VALUES
        -- Push-ups
        (mike_id, 1, 'pushup', 65, 88, 92, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        (mike_id, 1, 'pushup', 62, 86, 88, true, NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days'),
        -- Sit-ups
        (mike_id, 2, 'situp', 70, 85, 88, true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        -- Pull-ups
        (mike_id, 3, 'pullup', 15, 92, 88, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        -- Running
        (mike_id, 4, 'run', 870, 90, 86, true, NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days');
    END IF;

    -- Add public workouts for Emily (elite performer)
    IF emily_id IS NOT NULL THEN
        INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, form_score, grade, is_public, completed_at, created_at) VALUES
        -- Push-ups
        (emily_id, 1, 'pushup', 85, 98, 100, true, NOW() - INTERVAL '12 hours', NOW() - INTERVAL '12 hours'),
        (emily_id, 1, 'pushup', 82, 97, 100, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days'),
        -- Sit-ups
        (emily_id, 2, 'situp', 90, 96, 100, true, NOW() - INTERVAL '1 day', NOW() - INTERVAL '1 day'),
        -- Pull-ups
        (emily_id, 3, 'pullup', 20, 95, 100, true, NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
        -- Running
        (emily_id, 4, 'run', 720, 98, 100, true, NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days');
    END IF;

    -- Also update user_exercises table for backward compatibility
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
    WHERE user_id IN (sarah_id, mike_id, emily_id)
    ON CONFLICT (user_id, exercise_id, created_at) DO NOTHING;

    RAISE NOTICE 'Leaderboard demo data added successfully';
    RAISE NOTICE 'John Smith location: Fort Bragg, NC (%.4f, %.4f)', 35.1392, -78.9946;
    RAISE NOTICE 'Sarah Johnson: Fort Bragg area - Elite female performer';
    RAISE NOTICE 'Mike Williams: Fayetteville, NC - Mid-range performer';
    RAISE NOTICE 'Emily Davis: Fort Hood, TX - Elite overall performer';
END $$;