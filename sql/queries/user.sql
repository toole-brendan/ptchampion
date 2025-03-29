-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
  username, 
  password, 
  display_name
)
VALUES ($1, $2, $3)
RETURNING *;

-- name: UpdateUser :one
UPDATE users
SET 
  username = COALESCE($2, username),
  display_name = COALESCE($3, display_name),
  profile_picture_url = COALESCE($4, profile_picture_url),
  location = COALESCE($5, location),
  latitude = COALESCE($6, latitude),
  longitude = COALESCE($7, longitude),
  updated_at = now()
WHERE id = $1
RETURNING *;

-- TODO: Add queries for additional user operations 