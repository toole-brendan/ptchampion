-- Test query to verify test user exists
SELECT 
    id,
    username,
    email,
    CASE 
        WHEN password_hash LIKE '$2a$%' THEN 'Valid bcrypt hash'
        ELSE 'Invalid hash format'
    END as hash_status,
    length(password_hash) as hash_length,
    created_at,
    updated_at
FROM users 
WHERE email IN ('testuser@ptchampion.ai', 'mock@example.com', 'clicktest@ptchampion.ai')
ORDER BY created_at DESC;