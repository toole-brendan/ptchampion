-- PT Champion Mock User Creation Script
-- This creates a mock user for the 5-click login feature in production
-- 
-- Login credentials:
-- Email: mock@example.com
-- Password: mockpassword

-- First, check if the user already exists and delete if needed
DELETE FROM users WHERE email = 'mock@example.com';

-- Create the mock user with properly hashed password
INSERT INTO users (
    username,
    email,
    first_name,
    last_name,
    password_hash,
    display_name,
    created_at,
    updated_at
) VALUES (
    'mockuser',
    'mock@example.com',
    'Mock',
    'User',
    '$2a$14$h1dGU.cq/y.08bzYcRFqX.sEglgaXojiXNyXJj3SZg3MXNXXArUiy',
    'Mock User',
    NOW(),
    NOW()
);

-- Verify the user was created
SELECT id, username, email, display_name, created_at 
FROM users 
WHERE email = 'mock@example.com';