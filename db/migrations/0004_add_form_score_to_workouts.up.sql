-- +migrate Up
ALTER TABLE workouts
ADD COLUMN form_score INT NULL CHECK (form_score >= 0 AND form_score <= 100); 