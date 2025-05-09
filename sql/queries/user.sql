-- name: GetUser :one
SELECT * FROM users
WHERE id = $1 LIMIT 1;

-- name: GetUserByUsername :one
SELECT * FROM users
WHERE username = $1 LIMIT 1;

-- name: GetUserByEmail :one
SELECT * FROM users
WHERE email = $1 LIMIT 1;

-- name: CreateUser :one
INSERT INTO users (
  username,
  email, 
  password_hash, 
  display_name
)
VALUES ($1, $2, $3, $4)
RETURNING *;

-- name: UpdateUser :one
UPDATE users
SET 
  username = COALESCE($2, username),
  email = COALESCE($3, email),
  display_name = COALESCE($4, display_name),
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

-- name: CheckUsernameExists :one
SELECT EXISTS (
  SELECT 1 FROM users WHERE username = $1
) AS exists;

-- TODO: Add queries for additional user operations 