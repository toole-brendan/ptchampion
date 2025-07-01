-- Populate Global Leaderboard with Demo Data
-- Simplified version without pgcrypto dependency

BEGIN;

-- First, make John Smith's workouts public
UPDATE workouts 
SET is_public = true 
WHERE user_id = (SELECT id FROM users WHERE email = 'john.smith@example.com');

-- Use the same password hash as John Smith for all demo users
DO $$
DECLARE
    demo_password_hash TEXT;
    user_record RECORD;
    user_id_var INTEGER;
    workout_date DATE;
    i INTEGER;
    base_score INTEGER;
    variation INTEGER;
    final_score INTEGER;
BEGIN
    -- Get John Smith's password hash to reuse
    SELECT password_hash INTO demo_password_hash 
    FROM users 
    WHERE email = 'john.smith@example.com' 
    LIMIT 1;

    -- Create array of demo users with diverse profiles
    FOR user_record IN 
        SELECT * FROM (VALUES
            -- Elite performers
            ('michael.rodriguez@demo.com', 'mrodriguez', 'Michael', 'Rodriguez', 'male', '1995-03-15'::DATE, 'Fort Bragg, NC', 35.1392, -78.9946),
            ('sarah.thompson@demo.com', 'sthompson', 'Sarah', 'Thompson', 'female', '1997-06-22'::DATE, 'Fort Hood, TX', 31.1352, -97.7896),
            ('james.wilson@demo.com', 'jwilson', 'James', 'Wilson', 'male', '1993-11-08'::DATE, 'Camp Pendleton, CA', 33.3872, -117.5366),
            
            -- High performers
            ('emily.chen@demo.com', 'echen', 'Emily', 'Chen', 'female', '1998-04-20'::DATE, 'Fort Campbell, KY', 36.6724, -87.4620),
            ('david.martinez@demo.com', 'dmartinez', 'David', 'Martinez', 'male', '1996-09-12'::DATE, 'Fort Benning, GA', 32.3574, -84.9557),
            ('jessica.taylor@demo.com', 'jtaylor', 'Jessica', 'Taylor', 'female', '1994-07-05'::DATE, 'Fort Carson, CO', 38.7376, -104.7894),
            
            -- Above average performers
            ('robert.johnson@demo.com', 'rjohnson', 'Robert', 'Johnson', 'male', '1992-02-28'::DATE, 'Fort Stewart, GA', 31.8691, -81.6090),
            ('amanda.davis@demo.com', 'adavis', 'Amanda', 'Davis', 'female', '1999-10-17'::DATE, 'Joint Base Lewis-McChord, WA', 47.1378, -122.4763),
            ('christopher.lee@demo.com', 'clee', 'Christopher', 'Lee', 'male', '1997-01-23'::DATE, 'Fort Bliss, TX', 31.8137, -106.4015),
            
            -- Average performers
            ('nicole.brown@demo.com', 'nbrown', 'Nicole', 'Brown', 'female', '1996-05-30'::DATE, 'Fort Gordon, GA', 33.4208, -82.1584),
            ('william.garcia@demo.com', 'wgarcia', 'William', 'Garcia', 'male', '1994-12-14'::DATE, 'Fort Riley, KS', 39.0815, -96.8061),
            ('sophia.kim@demo.com', 'skim', 'Sophia', 'Kim', 'female', '1998-08-03'::DATE, 'Fort Sill, OK', 34.6509, -98.4073),
            
            -- Below average performers (still passing)
            ('daniel.white@demo.com', 'dwhite', 'Daniel', 'White', 'male', '1993-04-18'::DATE, 'Fort Knox, KY', 37.9161, -85.9563),
            ('olivia.miller@demo.com', 'omiller', 'Olivia', 'Miller', 'female', '1997-11-25'::DATE, 'Fort Polk, LA', 31.0469, -93.0610),
            ('matthew.anderson@demo.com', 'manderson', 'Matthew', 'Anderson', 'male', '1995-07-09'::DATE, 'Fort Drum, NY', 44.0419, -75.8590)
        ) AS t(email, username, first_name, last_name, gender, dob, location, lat, lng)
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
            demo_password_hash, -- Use same hash as John Smith
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
        ON CONFLICT (email) DO UPDATE
        SET latitude = EXCLUDED.latitude,
            longitude = EXCLUDED.longitude,
            last_location = EXCLUDED.last_location
        RETURNING id INTO user_id_var;
    END LOOP;

    -- Generate limited workout data for each user (last 7 days only to reduce data)
    FOR user_record IN 
        SELECT u.id, u.email, u.first_name, u.gender,
               CASE 
                   WHEN u.email IN ('michael.rodriguez@demo.com', 'sarah.thompson@demo.com', 'james.wilson@demo.com') THEN 'elite'
                   WHEN u.email IN ('emily.chen@demo.com', 'david.martinez@demo.com', 'jessica.taylor@demo.com') THEN 'high'
                   WHEN u.email IN ('robert.johnson@demo.com', 'amanda.davis@demo.com', 'christopher.lee@demo.com') THEN 'above_avg'
                   WHEN u.email IN ('nicole.brown@demo.com', 'william.garcia@demo.com', 'sophia.kim@demo.com') THEN 'average'
                   ELSE 'below_avg'
               END as performance_tier
        FROM users u
        WHERE u.email LIKE '%@demo.com'
    LOOP
        -- Generate workouts for the last 7 days only
        FOR i IN 0..6 LOOP
            workout_date := CURRENT_DATE - INTERVAL '1 day' * i;
            
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
                LEAST(100, GREATEST(0, 
                    CASE 
                        WHEN user_record.gender = 'male' THEN
                            CASE 
                                WHEN final_score >= 77 THEN 100
                                WHEN final_score >= 39 THEN 60 + ((final_score - 39) * 40 / 38)
                                ELSE (final_score * 60 / 39)
                            END
                        ELSE
                            CASE 
                                WHEN final_score >= 50 THEN 100
                                WHEN final_score >= 19 THEN 60 + ((final_score - 19) * 40 / 31)
                                ELSE (final_score * 60 / 19)
                            END
                    END
                )),
                true,
                workout_date + INTERVAL '6 hours',
                NOW()
            )
            ON CONFLICT DO NOTHING;

            -- SIT-UPS
            base_score := CASE user_record.performance_tier
                WHEN 'elite' THEN 82
                WHEN 'high' THEN 76
                WHEN 'above_avg' THEN 68
                WHEN 'average' THEN 58
                ELSE 47
            END;
            
            variation := floor(random() * 12 - 6)::INTEGER;
            final_score := GREATEST(base_score + variation, 1);
            
            INSERT INTO workouts (user_id, exercise_id, exercise_type, repetitions, grade, is_public, completed_at, created_at)
            VALUES (
                user_record.id,
                2, -- situp
                'situp',
                final_score,
                LEAST(100, GREATEST(0,
                    CASE 
                        WHEN final_score >= 82 THEN 100
                        WHEN final_score >= 47 THEN 60 + ((final_score - 47) * 40 / 35)
                        ELSE (final_score * 60 / 47)
                    END
                )),
                true,
                workout_date + INTERVAL '7 hours',
                NOW()
            )
            ON CONFLICT DO NOTHING;

            -- PULL-UPS (only every other day)
            IF i % 2 = 0 THEN
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
                        LEAST(100, GREATEST(0,
                            CASE 
                                WHEN user_record.gender = 'male' THEN
                                    CASE 
                                        WHEN final_score >= 20 THEN 100
                                        WHEN final_score >= 3 THEN 60 + ((final_score - 3) * 40 / 17)
                                        ELSE (final_score * 60 / 3)
                                    END
                                ELSE
                                    CASE 
                                        WHEN final_score >= 7 THEN 100
                                        WHEN final_score >= 1 THEN 60 + ((final_score - 1) * 40 / 6)
                                        ELSE 0
                                    END
                            END
                        )),
                        true,
                        workout_date + INTERVAL '8 hours',
                        NOW()
                    )
                    ON CONFLICT DO NOTHING;
                END IF;
            END IF;

            -- 2-MILE RUN (every 3 days)
            IF i % 3 = 0 THEN
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
                    LEAST(100, GREATEST(0,
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
                        END
                    )),
                    true,
                    workout_date + INTERVAL '15 hours',
                    NOW()
                )
                ON CONFLICT DO NOTHING;
            END IF;
            
        END LOOP;
    END LOOP;
END $$;

COMMIT;

-- Verify the data
SELECT 
    'Users with public workouts' as metric,
    COUNT(DISTINCT u.email) as count
FROM users u
JOIN workouts w ON u.id = w.user_id
WHERE w.is_public = true;

-- Check weekly leaderboard for pushups
SELECT 
    u.first_name || ' ' || u.last_name as name,
    u.location,
    MAX(w.repetitions) as best_pushups,
    ROUND(MAX(w.grade)::numeric, 0) as grade
FROM users u
JOIN workouts w ON u.id = w.user_id
WHERE w.exercise_type = 'pushup' 
  AND w.is_public = true
  AND w.completed_at >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY u.id, u.first_name, u.last_name, u.location
ORDER BY best_pushups DESC
LIMIT 10;