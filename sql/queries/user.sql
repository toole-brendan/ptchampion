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

-- name: UpdateUserLocation :exec
UPDATE users
SET 
  last_location = ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography, -- $2 = longitude, $3 = latitude
  updated_at = now()
WHERE id = $1;

-- TODO: Add queries for additional user operations 