-- Update mock user with a fresh password hash
-- Password: mockpassword
-- Hash generated with bcrypt cost 14

UPDATE users 
SET password_hash = '$2a$14$h1dGU.cq/y.08bzYcRFqX.sEglgaXojiXNyXJj3SZg3MXNXXArUiy',
    updated_at = NOW()
WHERE email = 'mock@example.com';

-- Verify the update
SELECT id, username, email, 
       substring(password_hash, 1, 30) as hash_prefix,
       length(password_hash) as hash_length,
       updated_at
FROM users 
WHERE email = 'mock@example.com';