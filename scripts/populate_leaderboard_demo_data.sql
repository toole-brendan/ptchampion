-- Populate Global Leaderboard with Believable Demo Data
-- This script creates diverse users and workout data for PT Champion leaderboard

BEGIN;

-- First, make John Smith's workouts public
UPDATE workouts 
SET is_public = true 
WHERE user_id = (SELECT id FROM users WHERE email = 'john.smith@example.com');

-- Create diverse demo users with realistic military bases and demographics
DO $$
DECLARE
    user_record RECORD;
    workout_date DATE;
    i INTEGER;
    base_score INTEGER;
    variation INTEGER;
    final_score INTEGER;
BEGIN
    -- Create array of demo users with diverse profiles
    FOR user_record IN 
        SELECT * FROM (VALUES
            -- Elite performers
            ('michael.rodriguez@demo.com', 'mrodriguez', 'Michael', 'Rodriguez', 'male', '1995-03-15'::DATE, 'Fort Bragg, NC', 35.1392, -78.9946, 'Elite Ranger'),
            ('sarah.thompson@demo.com', 'sthompson', 'Sarah', 'Thompson', 'female', '1997-06-22'::DATE, 'Fort Hood, TX', 31.1352, -97.7896, 'Army Officer'),
            ('james.wilson@demo.com', 'jwilson', 'James', 'Wilson', 'male', '1993-11-08'::DATE, 'Camp Pendleton, CA', 33.3872, -117.5366, 'Marine Veteran'),
            
            -- High performers
            ('emily.chen@demo.com', 'echen', 'Emily', 'Chen', 'female', '1998-04-20'::DATE, 'Fort Campbell, KY', 36.6724, -87.4620, 'Combat Medic'),
            ('david.martinez@demo.com', 'dmartinez', 'David', 'Martinez', 'male', '1996-09-12'::DATE, 'Fort Benning, GA', 32.3574, -84.9557, 'Infantry Specialist'),
            ('jessica.taylor@demo.com', 'jtaylor', 'Jessica', 'Taylor', 'female', '1994-07-05'::DATE, 'Fort Carson, CO', 38.7376, -104.7894, 'Military Police'),
            
            -- Above average performers
            ('robert.johnson@demo.com', 'rjohnson', 'Robert', 'Johnson', 'male', '1992-02-28'::DATE, 'Fort Stewart, GA', 31.8691, -81.6090, 'Tank Commander'),
            ('amanda.davis@demo.com', 'adavis', 'Amanda', 'Davis', 'female', '1999-10-17'::DATE, 'Joint Base Lewis-McChord, WA', 47.1378, -122.4763, 'Air Force Tech'),
            ('christopher.lee@demo.com', 'clee', 'Christopher', 'Lee', 'male', '1997-01-23'::DATE, 'Fort Bliss, TX', 31.8137, -106.4015, 'Signal Corps'),
            
            -- Average performers
            ('nicole.brown@demo.com', 'nbrown', 'Nicole', 'Brown', 'female', '1996-05-30'::DATE, 'Fort Gordon, GA', 33.4208, -82.1584, 'Cyber Operations'),
            ('william.garcia@demo.com', 'wgarcia', 'William', 'Garcia', 'male', '1994-12-14'::DATE, 'Fort Riley, KS', 39.0815, -96.8061, 'Cavalry Scout'),
            ('sophia.kim@demo.com', 'skim', 'Sophia', 'Kim', 'female', '1998-08-03'::DATE, 'Fort Sill, OK', 34.6509, -98.4073, 'Artillery Specialist'),
            
            -- Below average performers (still passing)
            ('daniel.white@demo.com', 'dwhite', 'Daniel', 'White', 'male', '1993-04-18'::DATE, 'Fort Knox, KY', 37.9161, -85.9563, 'Supply Sergeant'),
            ('olivia.miller@demo.com', 'omiller', 'Olivia', 'Miller', 'female', '1997-11-25'::DATE, 'Fort Polk, LA', 31.0469, -93.0610, 'Admin Specialist'),
            ('matthew.anderson@demo.com', 'manderson', 'Matthew', 'Anderson', 'male', '1995-07-09'::DATE, 'Fort Drum, NY', 44.0419, -75.8590, 'Combat Engineer')
        ) AS t(email, username, first_name, last_name, gender, dob, location, lat, lng, description)
    LOOP
        -- Insert user if not exists
        INSERT INTO users (
            email, username, first_name, last_name, password_hash,
            gender, date_of_birth, location, latitude, longitude,
            last_location, profile_picture_url, created_at, updated_at
        ) VALUES (
            user_record.email,
            user_record.username,
            user_record.first_name,
            user_record.last_name,
            crypt('DemoUser123!', gen_salt('bf', 10)), -- Faster hash for demo
            user_record.gender,
            user_record.dob,
            user_record.location,
            user_record.lat,
            user_record.lng,
            ST_SetSRID(ST_MakePoint(user_record.lng, user_record.lat), 4326)::geography,
            'https://api.dicebear.com/7.x/avataaars/svg?seed=' || user_record.username,
            NOW() - INTERVAL '6 months',
            NOW()
        )
        ON CONFLICT (email) DO NOTHING;
    END LOOP;

    -- Generate workout data for each user
    FOR user_record IN 
        SELECT u.id, u.email, u.first_name, u.gender,
               CASE 
                   -- Elite performers
                   WHEN u.email IN ('michael.rodriguez@demo.com', 'sarah.thompson@demo.com', 'james.wilson@demo.com') THEN 'elite'
                   -- High performers
                   WHEN u.email IN ('emily.chen@demo.com', 'david.martinez@demo.com', 'jessica.taylor@demo.com') THEN 'high'
                   -- Above average
                   WHEN u.email IN ('robert.johnson@demo.com', 'amanda.davis@demo.com', 'christopher.lee@demo.com') THEN 'above_avg'
                   -- Average
                   WHEN u.email IN ('nicole.brown@demo.com', 'william.garcia@demo.com', 'sophia.kim@demo.com') THEN 'average'
                   -- Below average
                   ELSE 'below_avg'
               END as performance_tier
        FROM users u
        WHERE u.email LIKE '%@demo.com'
    LOOP
        -- Generate workouts for the last 30 days
        FOR i IN 0..29 LOOP
            workout_date := CURRENT_DATE - INTERVAL '1 day' * i;
            
            -- Skip some days randomly (people don't work out every day)
            IF random() > 0.7 THEN
                CONTINUE;
            END IF;

            -- PUSH-UPS
            base_score := CASE user_record.performance_tier
                WHEN 'elite' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 75 ELSE 50 END
                WHEN 'high' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 65 ELSE 42 END
                WHEN 'above_avg' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 55 ELSE 35 END
                WHEN 'average' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 45 ELSE 25 END
                ELSE 
                    CASE WHEN user_record.gender = 'male' THEN 35 ELSE 19 END
            END;
            
            variation := floor(random() * 10 - 5)::INTEGER;
            final_score := GREATEST(base_score + variation, 1);
            
            INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, is_public, completed_at, created_at)
            VALUES (
                user_record.id,
                1, -- pushup
                'pushup',
                final_score,
                CASE 
                    WHEN user_record.gender = 'male' THEN
                        CASE 
                            WHEN final_score >= 77 THEN 100
                            WHEN final_score >= 39 THEN 60 + (final_score - 39) * 40 / 38
                            ELSE final_score * 60 / 39
                        END
                    ELSE
                        CASE 
                            WHEN final_score >= 50 THEN 100
                            WHEN final_score >= 19 THEN 60 + (final_score - 19) * 40 / 31
                            ELSE final_score * 60 / 19
                        END
                END,
                true,
                workout_date + INTERVAL '6 hours' + INTERVAL '1 minute' * floor(random() * 720),
                NOW()
            );

            -- SIT-UPS
            base_score := CASE user_record.performance_tier
                WHEN 'elite' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 82 ELSE 82 END
                WHEN 'high' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 76 ELSE 76 END
                WHEN 'above_avg' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 68 ELSE 68 END
                WHEN 'average' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 58 ELSE 58 END
                ELSE 
                    CASE WHEN user_record.gender = 'male' THEN 47 ELSE 47 END
            END;
            
            variation := floor(random() * 12 - 6)::INTEGER;
            final_score := GREATEST(base_score + variation, 1);
            
            INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, is_public, completed_at, created_at)
            VALUES (
                user_record.id,
                2, -- situp
                'situp',
                final_score,
                CASE 
                    WHEN final_score >= 82 THEN 100
                    WHEN final_score >= 47 THEN 60 + (final_score - 47) * 40 / 35
                    ELSE final_score * 60 / 47
                END,
                true,
                workout_date + INTERVAL '7 hours' + INTERVAL '1 minute' * floor(random() * 720),
                NOW()
            );

            -- PULL-UPS (only sometimes - harder exercise)
            IF random() > 0.5 THEN
                base_score := CASE user_record.performance_tier
                    WHEN 'elite' THEN 
                        CASE WHEN user_record.gender = 'male' THEN 20 ELSE 8 END
                    WHEN 'high' THEN 
                        CASE WHEN user_record.gender = 'male' THEN 15 ELSE 5 END
                    WHEN 'above_avg' THEN 
                        CASE WHEN user_record.gender = 'male' THEN 10 ELSE 3 END
                    WHEN 'average' THEN 
                        CASE WHEN user_record.gender = 'male' THEN 6 ELSE 1 END
                    ELSE 
                        CASE WHEN user_record.gender = 'male' THEN 3 ELSE 0 END
                END;
                
                variation := floor(random() * 3 - 1)::INTEGER;
                final_score := GREATEST(base_score + variation, 0);
                
                IF final_score > 0 THEN
                    INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, is_public, completed_at, created_at)
                    VALUES (
                        user_record.id,
                        3, -- pullup
                        'pullup',
                        final_score,
                        CASE 
                            WHEN user_record.gender = 'male' THEN
                                CASE 
                                    WHEN final_score >= 20 THEN 100
                                    WHEN final_score >= 3 THEN 60 + (final_score - 3) * 40 / 17
                                    ELSE final_score * 60 / 3
                                END
                            ELSE
                                CASE 
                                    WHEN final_score >= 7 THEN 100
                                    WHEN final_score >= 1 THEN 60 + (final_score - 1) * 40 / 6
                                    ELSE 0
                                END
                        END,
                        true,
                        workout_date + INTERVAL '8 hours' + INTERVAL '1 minute' * floor(random() * 720),
                        NOW()
                    );
                END IF;
            END IF;

            -- 2-MILE RUN (in seconds)
            base_score := CASE user_record.performance_tier
                WHEN 'elite' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 780 ELSE 936 END  -- 13:00 / 15:36
                WHEN 'high' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 870 ELSE 1020 END -- 14:30 / 17:00
                WHEN 'above_avg' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 960 ELSE 1140 END -- 16:00 / 19:00
                WHEN 'average' THEN 
                    CASE WHEN user_record.gender = 'male' THEN 1080 ELSE 1260 END -- 18:00 / 21:00
                ELSE 
                    CASE WHEN user_record.gender = 'male' THEN 1200 ELSE 1380 END -- 20:00 / 23:00
            END;
            
            variation := floor(random() * 60 - 30)::INTEGER;
            final_score := base_score + variation;
            
            INSERT INTO workouts (user_id, exercise_id, exercise_type, duration_seconds, grade, is_public, completed_at, created_at)
            VALUES (
                user_record.id,
                4, -- run
                'running',
                final_score,
                CASE 
                    WHEN user_record.gender = 'male' THEN
                        CASE 
                            WHEN final_score <= 780 THEN 100  -- 13:00 or faster
                            WHEN final_score <= 1236 THEN 100 - ((final_score - 780) * 40 / 456)  -- 13:00 to 20:36
                            ELSE GREATEST(0, 60 - ((final_score - 1236) * 60 / 300))  -- slower than 20:36
                        END
                    ELSE
                        CASE 
                            WHEN final_score <= 936 THEN 100  -- 15:36 or faster
                            WHEN final_score <= 1392 THEN 100 - ((final_score - 936) * 40 / 456)  -- 15:36 to 23:12
                            ELSE GREATEST(0, 60 - ((final_score - 1392) * 60 / 300))  -- slower than 23:12
                        END
                END,
                true,
                workout_date + INTERVAL '15 hours' + INTERVAL '1 minute' * floor(random() * 360),
                NOW()
            );
            
        END LOOP;
    END LOOP;
END $$;

-- Add some recent workouts (today) for top performers to make leaderboard more dynamic
INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, is_public, completed_at, created_at)
SELECT 
    u.id,
    1,
    'pushup',
    CASE WHEN u.gender = 'male' THEN 77 ELSE 50 END,
    100,
    true,
    CURRENT_DATE + INTERVAL '6 hours',
    NOW()
FROM users u
WHERE u.email IN ('michael.rodriguez@demo.com', 'sarah.thompson@demo.com')
  AND NOT EXISTS (
      SELECT 1 FROM workouts w 
      WHERE w.user_id = u.id 
        AND w.exercise_type = 'pushup' 
        AND w.completed_at::date = CURRENT_DATE
  );

-- Verify the data
SELECT 
    'Total demo users created' as metric,
    COUNT(*) as count
FROM users
WHERE email LIKE '%@demo.com';

SELECT 
    'Total public workouts created' as metric,
    COUNT(*) as count
FROM workouts
WHERE is_public = true
  AND user_id IN (SELECT id FROM users WHERE email LIKE '%@demo.com' OR email = 'john.smith@example.com');

SELECT 
    'Workouts by exercise type' as metric,
    exercise_type,
    COUNT(*) as count
FROM workouts
WHERE is_public = true
GROUP BY exercise_type
ORDER BY exercise_type;

COMMIT;

-- Quick check of leaderboard data
SELECT 
    u.first_name || ' ' || u.last_name as name,
    u.location,
    MAX(w.repetitions) as best_pushups,
    MAX(w.grade) as best_grade
FROM users u
JOIN workouts w ON u.id = w.user_id
WHERE w.exercise_type = 'pushup' 
  AND w.is_public = true
  AND w.completed_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY u.id, u.first_name, u.last_name, u.location
ORDER BY best_pushups DESC
LIMIT 10;