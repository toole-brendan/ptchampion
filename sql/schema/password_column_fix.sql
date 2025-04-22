-- Rename the 'password' column to 'password_hash' to match the code
ALTER TABLE users RENAME COLUMN password TO password_hash; 