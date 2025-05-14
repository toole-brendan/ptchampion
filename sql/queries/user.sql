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
  first_name,
  last_name
)
VALUES ($1, $2, $3, $4, $5)
RETURNING *;

-- name: UpdateUser :one
UPDATE users
SET 
  username = $2,
  email = $3,
  first_name = $4,
  last_name = $5,
  location = $6,
  latitude = $7,
  longitude = $8,
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