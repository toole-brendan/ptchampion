-- +migrate Down
-- Revert mock user back to original state

DO $$
BEGIN
    -- Revert to original mock user data
    UPDATE users 
    SET email = 'mock@example.com',
        username = 'mockuser',
        first_name = 'Mock',
        last_name = 'User',
        password_hash = crypt('mockpassword', gen_salt('bf', 14)),
        gender = NULL,
        date_of_birth = NULL,
        updated_at = NOW()
    WHERE email = 'john.smith@example.com';
END $$;