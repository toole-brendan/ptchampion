-- +migrate Down
-- Remove leaderboard demo data

DO $$
DECLARE
    john_id INTEGER;
BEGIN
    -- Remove the additional demo users and their workouts
    DELETE FROM users WHERE email IN (
        'sarah.johnson@example.com',
        'mike.williams@example.com',
        'emily.davis@example.com'
    );

    -- Get John's ID
    SELECT id INTO john_id FROM users WHERE email = 'john.smith@example.com';

    -- Revert John's workouts to private
    IF john_id IS NOT NULL THEN
        UPDATE workouts 
        SET is_public = false 
        WHERE user_id = john_id;

        -- Remove John's location data
        UPDATE users 
        SET 
            location = NULL,
            latitude = NULL,
            longitude = NULL,
            last_location = NULL,
            profile_picture_url = NULL,
            updated_at = NOW()
        WHERE id = john_id;
    END IF;

    RAISE NOTICE 'Leaderboard demo data removed successfully';
END $$;