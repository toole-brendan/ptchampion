CREATE TABLE user_social_accounts (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider TEXT NOT NULL,               -- e.g. 'google' or 'apple'
    provider_user_id TEXT NOT NULL,       -- external unique ID (Google sub, Apple sub)
    email TEXT,                           -- optionally store email for reference
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(provider, provider_user_id)    -- ensure one entry per provider user
); 