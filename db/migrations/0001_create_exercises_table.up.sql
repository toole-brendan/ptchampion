-- +migrate Up
CREATE TABLE exercises (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL -- e.g., 'reps', 'timed', 'distance'
);

-- Optional: Add initial exercises
INSERT INTO exercises (name, description, type)
VALUES
    ('Push-up', 'Standard push-up exercise', 'reps'),
    ('Sit-up', 'Standard sit-up exercise', 'reps'),
    ('Pull-up', 'Standard pull-up exercise', 'reps'),
    ('Run', 'Running exercise', 'distance'); 