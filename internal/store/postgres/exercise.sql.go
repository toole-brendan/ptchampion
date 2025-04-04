// Code generated by sqlc. DO NOT EDIT.
// versions:
//   sqlc v1.28.0
// source: exercise.sql

package db

import (
	"context"
	"database/sql"
)

const getExercise = `-- name: GetExercise :one
SELECT id, name, description, type FROM exercises
WHERE id = $1 LIMIT 1
`

func (q *Queries) GetExercise(ctx context.Context, id int32) (Exercise, error) {
	row := q.db.QueryRowContext(ctx, getExercise, id)
	var i Exercise
	err := row.Scan(
		&i.ID,
		&i.Name,
		&i.Description,
		&i.Type,
	)
	return i, err
}

const getExercisesByType = `-- name: GetExercisesByType :many
SELECT id, name, description, type FROM exercises
WHERE type = $1
ORDER BY name
`

func (q *Queries) GetExercisesByType(ctx context.Context, type_ string) ([]Exercise, error) {
	rows, err := q.db.QueryContext(ctx, getExercisesByType, type_)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []Exercise{}
	for rows.Next() {
		var i Exercise
		if err := rows.Scan(
			&i.ID,
			&i.Name,
			&i.Description,
			&i.Type,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const getLeaderboard = `-- name: GetLeaderboard :many
SELECT 
    u.id AS user_id,
    u.username,
    u.display_name,
    u.profile_picture_url,
    MAX(ue.grade) AS max_grade,
    MAX(ue.created_at) AS last_attempt_date
FROM 
    user_exercises ue
JOIN 
    users u ON ue.user_id = u.id
JOIN
    exercises e ON ue.exercise_id = e.id
WHERE 
    e.type = $1
    AND ue.grade IS NOT NULL
GROUP BY 
    u.id, u.username, u.display_name, u.profile_picture_url
ORDER BY 
    max_grade DESC, last_attempt_date ASC
LIMIT 100
`

type GetLeaderboardRow struct {
	UserID            int32          `json:"user_id"`
	Username          string         `json:"username"`
	DisplayName       sql.NullString `json:"display_name"`
	ProfilePictureUrl sql.NullString `json:"profile_picture_url"`
	MaxGrade          interface{}    `json:"max_grade"`
	LastAttemptDate   interface{}    `json:"last_attempt_date"`
}

func (q *Queries) GetLeaderboard(ctx context.Context, type_ string) ([]GetLeaderboardRow, error) {
	rows, err := q.db.QueryContext(ctx, getLeaderboard, type_)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []GetLeaderboardRow{}
	for rows.Next() {
		var i GetLeaderboardRow
		if err := rows.Scan(
			&i.UserID,
			&i.Username,
			&i.DisplayName,
			&i.ProfilePictureUrl,
			&i.MaxGrade,
			&i.LastAttemptDate,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const getUserExercises = `-- name: GetUserExercises :many
SELECT 
    ue.id,
    ue.user_id,
    ue.exercise_id,
    ue.repetitions,
    ue.time_in_seconds,
    ue.distance,
    ue.grade,
    ue.notes,
    ue.created_at,
    e.name AS exercise_name,
    e.type AS exercise_type
FROM 
    user_exercises ue
JOIN 
    exercises e ON ue.exercise_id = e.id
WHERE 
    ue.user_id = $1
ORDER BY 
    ue.created_at DESC
`

type GetUserExercisesRow struct {
	ID            int32          `json:"id"`
	UserID        int32          `json:"user_id"`
	ExerciseID    int32          `json:"exercise_id"`
	Repetitions   sql.NullInt32  `json:"repetitions"`
	TimeInSeconds sql.NullInt32  `json:"time_in_seconds"`
	Distance      sql.NullInt32  `json:"distance"`
	Grade         sql.NullInt32  `json:"grade"`
	Notes         sql.NullString `json:"notes"`
	CreatedAt     sql.NullTime   `json:"created_at"`
	ExerciseName  string         `json:"exercise_name"`
	ExerciseType  string         `json:"exercise_type"`
}

func (q *Queries) GetUserExercises(ctx context.Context, userID int32) ([]GetUserExercisesRow, error) {
	rows, err := q.db.QueryContext(ctx, getUserExercises, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []GetUserExercisesRow{}
	for rows.Next() {
		var i GetUserExercisesRow
		if err := rows.Scan(
			&i.ID,
			&i.UserID,
			&i.ExerciseID,
			&i.Repetitions,
			&i.TimeInSeconds,
			&i.Distance,
			&i.Grade,
			&i.Notes,
			&i.CreatedAt,
			&i.ExerciseName,
			&i.ExerciseType,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const getUserExercisesByType = `-- name: GetUserExercisesByType :many
SELECT ue.id, ue.user_id, ue.exercise_id, ue.repetitions, ue.time_in_seconds, ue.distance, ue.form_score, ue.grade, ue.completed, ue.metadata, ue.notes, ue.device_id, ue.created_at, e.name as exercise_name, e.type as exercise_type
FROM user_exercises ue
JOIN exercises e ON e.id = ue.exercise_id
WHERE ue.user_id = $1 AND e.type = $2
ORDER BY ue.created_at DESC
`

type GetUserExercisesByTypeParams struct {
	UserID int32  `json:"user_id"`
	Type   string `json:"type"`
}

type GetUserExercisesByTypeRow struct {
	ID            int32          `json:"id"`
	UserID        int32          `json:"user_id"`
	ExerciseID    int32          `json:"exercise_id"`
	Repetitions   sql.NullInt32  `json:"repetitions"`
	TimeInSeconds sql.NullInt32  `json:"time_in_seconds"`
	Distance      sql.NullInt32  `json:"distance"`
	FormScore     sql.NullInt32  `json:"form_score"`
	Grade         sql.NullInt32  `json:"grade"`
	Completed     sql.NullBool   `json:"completed"`
	Metadata      sql.NullString `json:"metadata"`
	Notes         sql.NullString `json:"notes"`
	DeviceID      sql.NullString `json:"device_id"`
	CreatedAt     sql.NullTime   `json:"created_at"`
	ExerciseName  string         `json:"exercise_name"`
	ExerciseType  string         `json:"exercise_type"`
}

func (q *Queries) GetUserExercisesByType(ctx context.Context, arg GetUserExercisesByTypeParams) ([]GetUserExercisesByTypeRow, error) {
	rows, err := q.db.QueryContext(ctx, getUserExercisesByType, arg.UserID, arg.Type)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []GetUserExercisesByTypeRow{}
	for rows.Next() {
		var i GetUserExercisesByTypeRow
		if err := rows.Scan(
			&i.ID,
			&i.UserID,
			&i.ExerciseID,
			&i.Repetitions,
			&i.TimeInSeconds,
			&i.Distance,
			&i.FormScore,
			&i.Grade,
			&i.Completed,
			&i.Metadata,
			&i.Notes,
			&i.DeviceID,
			&i.CreatedAt,
			&i.ExerciseName,
			&i.ExerciseType,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const listExercises = `-- name: ListExercises :many
SELECT id, name, description, type FROM exercises
ORDER BY name
`

func (q *Queries) ListExercises(ctx context.Context) ([]Exercise, error) {
	rows, err := q.db.QueryContext(ctx, listExercises)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	items := []Exercise{}
	for rows.Next() {
		var i Exercise
		if err := rows.Scan(
			&i.ID,
			&i.Name,
			&i.Description,
			&i.Type,
		); err != nil {
			return nil, err
		}
		items = append(items, i)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}
	return items, nil
}

const logUserExercise = `-- name: LogUserExercise :one
INSERT INTO user_exercises (
  user_id, 
  exercise_id, 
  repetitions, 
  form_score, 
  time_in_seconds, 
  distance,
  grade,
  notes,
  completed, 
  metadata, 
  device_id
)
VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
RETURNING id, user_id, exercise_id, repetitions, time_in_seconds, distance, form_score, grade, completed, metadata, notes, device_id, created_at
`

type LogUserExerciseParams struct {
	UserID        int32          `json:"user_id"`
	ExerciseID    int32          `json:"exercise_id"`
	Repetitions   sql.NullInt32  `json:"repetitions"`
	FormScore     sql.NullInt32  `json:"form_score"`
	TimeInSeconds sql.NullInt32  `json:"time_in_seconds"`
	Distance      sql.NullInt32  `json:"distance"`
	Grade         sql.NullInt32  `json:"grade"`
	Notes         sql.NullString `json:"notes"`
	Completed     sql.NullBool   `json:"completed"`
	Metadata      sql.NullString `json:"metadata"`
	DeviceID      sql.NullString `json:"device_id"`
}

func (q *Queries) LogUserExercise(ctx context.Context, arg LogUserExerciseParams) (UserExercise, error) {
	row := q.db.QueryRowContext(ctx, logUserExercise,
		arg.UserID,
		arg.ExerciseID,
		arg.Repetitions,
		arg.FormScore,
		arg.TimeInSeconds,
		arg.Distance,
		arg.Grade,
		arg.Notes,
		arg.Completed,
		arg.Metadata,
		arg.DeviceID,
	)
	var i UserExercise
	err := row.Scan(
		&i.ID,
		&i.UserID,
		&i.ExerciseID,
		&i.Repetitions,
		&i.TimeInSeconds,
		&i.Distance,
		&i.FormScore,
		&i.Grade,
		&i.Completed,
		&i.Metadata,
		&i.Notes,
		&i.DeviceID,
		&i.CreatedAt,
	)
	return i, err
}
