-- +migrate Up
ALTER TABLE user_exercises
ADD CONSTRAINT fk_user_exercises_exercise_id
FOREIGN KEY (exercise_id) REFERENCES exercises(id); 