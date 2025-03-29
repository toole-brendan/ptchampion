package handlers

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"time"

	"ptchampion/internal/api/utils"
	dbStore "ptchampion/internal/store/postgres"

	"github.com/golang-jwt/jwt/v5"
	"github.com/lib/pq"
	"golang.org/x/crypto/bcrypt"
)

// RegisterUserRequest defines the expected JSON payload for user registration
type RegisterUserRequest struct {
	Username    string `json:"username" validate:"required,alphanum,min=3,max=30"`
	Password    string `json:"password" validate:"required,min=8"`
	DisplayName string `json:"display_name"`
}

// LoginRequest defines the payload for login
type LoginRequest struct {
	Username string `json:"username" validate:"required"`
	Password string `json:"password" validate:"required"`
}

// LoginResponse defines the response on successful login
type LoginResponse struct {
	Token string       `json:"token"`
	User  UserResponse `json:"user"`
}

// RegisterUser handles user registration requests
func (h *Handler) RegisterUser(w http.ResponseWriter, r *http.Request) {
	var req RegisterUserRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode registration request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request struct
	if err := utils.Validate.Struct(req); err != nil {
		log.Printf("INFO: Invalid registration request: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		if encodeErr := json.NewEncoder(w).Encode(utils.ValidationErrorResponse(err)); encodeErr != nil {
			log.Printf("ERROR: Failed to encode validation error response: %v", encodeErr)
		}
		return
	}

	// Hash the password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("ERROR: Failed to hash password: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// Prepare user data for database insertion
	params := dbStore.CreateUserParams{
		Username: req.Username,
		Password: string(hashedPassword),
		DisplayName: sql.NullString{
			String: req.DisplayName,
			Valid:  req.DisplayName != "",
		},
	}

	// Insert user into database
	user, err := h.Queries.CreateUser(r.Context(), params)
	if err != nil {
		// Check for unique constraint violation (duplicate username)
		if pqErr, ok := err.(*pq.Error); ok && pqErr.Code == "23505" {
			log.Printf("INFO: Attempt to register duplicate username: %s", params.Username)
			// Check if the constraint is specifically on the username column
			if strings.Contains(pqErr.Constraint, "users_username_key") {
				http.Error(w, "Username already exists", http.StatusConflict) // 409 Conflict
				return
			}
		}
		// Handle other errors
		log.Printf("ERROR: Failed to create user: %v", err)
		http.Error(w, "Failed to register user", http.StatusInternalServerError)
		return
	}

	// Create response object (don't send password back)
	resp := UserResponse{
		ID:                user.ID,
		Username:          user.Username,
		DisplayName:       getNullString(user.DisplayName),
		ProfilePictureURL: getNullString(user.ProfilePictureUrl),
		Location:          getNullString(user.Location),
		CreatedAt:         getNullTime(user.CreatedAt),
		UpdatedAt:         getNullTime(user.UpdatedAt),
	}

	// Send response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	if err := json.NewEncoder(w).Encode(resp); err != nil {
		log.Printf("ERROR: Failed to encode registration response: %v", err)
	}
}

// LoginUser handles user login requests
func (h *Handler) LoginUser(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		log.Printf("ERROR: Failed to decode login request: %v", err)
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	// Validate the request struct
	if err := utils.Validate.Struct(req); err != nil {
		log.Printf("INFO: Invalid login request: %v", err)
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusBadRequest)
		if encodeErr := json.NewEncoder(w).Encode(utils.ValidationErrorResponse(err)); encodeErr != nil {
			log.Printf("ERROR: Failed to encode validation error response: %v", encodeErr)
		}
		return
	}

	// 1. Find user by username
	user, err := h.Queries.GetUserByUsername(r.Context(), req.Username)
	if err != nil {
		if err == sql.ErrNoRows {
			http.Error(w, "Invalid username or password", http.StatusUnauthorized)
		} else {
			log.Printf("ERROR: Failed to get user by username '%s': %v", req.Username, err)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
		}
		return
	}

	// 2. Compare password hash
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(req.Password)); err != nil {
		// Passwords don't match
		http.Error(w, "Invalid username or password", http.StatusUnauthorized)
		return
	}

	// 3. Generate JWT Token
	claims := jwt.MapClaims{
		"sub": user.ID,                               // Subject (user ID)
		"usr": user.Username,                         // Username
		"exp": time.Now().Add(time.Hour * 24).Unix(), // Expiration time (e.g., 24 hours)
		"iat": time.Now().Unix(),                     // Issued at
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(h.Config.JWTSecret))
	if err != nil {
		log.Printf("ERROR: Failed to sign JWT token: %v", err)
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	// 4. Prepare response
	userResp := UserResponse{
		ID:                user.ID,
		Username:          user.Username,
		DisplayName:       getNullString(user.DisplayName),
		ProfilePictureURL: getNullString(user.ProfilePictureUrl),
		Location:          getNullString(user.Location),
		CreatedAt:         getNullTime(user.CreatedAt),
		UpdatedAt:         getNullTime(user.UpdatedAt),
	}
	loginResp := LoginResponse{
		Token: tokenString,
		User:  userResp,
	}

	// 5. Send response
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	if err := json.NewEncoder(w).Encode(loginResp); err != nil {
		log.Printf("ERROR: Failed to encode login response: %v", err)
	}
}
