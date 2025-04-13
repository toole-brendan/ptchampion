-- +migrate Down
ALTER TABLE workouts
DROP COLUMN IF EXISTS form_score; 