-- +migrate Down
ALTER TABLE user_exercises
DROP CONSTRAINT IF EXISTS fk_user_exercises_exercise_id; 