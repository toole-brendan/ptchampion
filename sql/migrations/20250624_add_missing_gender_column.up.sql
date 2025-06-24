-- Add gender column that's missing in production
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender TEXT;