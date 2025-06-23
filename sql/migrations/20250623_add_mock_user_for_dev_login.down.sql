-- +migrate Down
-- Remove mock user

DELETE FROM users WHERE email = 'mock@example.com';