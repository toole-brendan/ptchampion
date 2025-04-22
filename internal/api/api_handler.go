package api

import (
	"ptchampion/internal/api/handlers" // Import the handlers package
	"ptchampion/internal/config"
	dbStore "ptchampion/internal/store/postgres"

	"log"
	"net/http"

	"github.com/labstack/echo/v4"
)

// ApiHandler embeds the core handlers.Handler and implements the ServerInterface
type ApiHandler struct {
	*handlers.Handler // Embed the handlers.Handler
}

// Ensure ApiHandler implements ServerInterface (compile-time check)
var _ ServerInterface = (*ApiHandler)(nil)

// NewApiHandler creates a new ApiHandler
func NewApiHandler(cfg *config.Config, queries *dbStore.Queries) *ApiHandler {
	coreHandler := handlers.NewHandler(cfg, queries) // Create the core handler
	return &ApiHandler{
		Handler: coreHandler, // Embed it
	}
}

// --- Implement ServerInterface methods by calling embedded handler methods ---

func (h *ApiHandler) PostAuthLogin(ctx echo.Context) error {
	// Call the embedded handler method directly
	return h.Handler.PostAuthLogin(ctx)
}

func (h *ApiHandler) PostAuthRegister(ctx echo.Context) error {
	// Call the embedded handler method directly
	return h.Handler.PostAuthRegister(ctx)
}

func (h *ApiHandler) GetExercises(ctx echo.Context, params GetExercisesParams) error {
	// Call the exported handler that lists all exercises
	// Pass only the context as the underlying handler doesn't need params
	return h.Handler.HandleListExercises(ctx)
}

func (h *ApiHandler) PostExercises(ctx echo.Context) error {
	// Call the updated handler method directly
	return h.Handler.LogExercise(ctx)
}

func (h *ApiHandler) GetLeaderboardExerciseType(ctx echo.Context, exerciseType GetLeaderboardExerciseTypeParamsExerciseType, params GetLeaderboardExerciseTypeParams) error {
	// Set exerciseType as a path parameter for GetLeaderboard to use
	ctx.SetParamNames("exerciseType")
	ctx.SetParamValues(string(exerciseType))

	// Call the updated handler method
	return h.Handler.GetLeaderboard(ctx)
}

func (h *ApiHandler) PostSync(ctx echo.Context) error {
	// Call the updated handler method directly
	return h.Handler.PostSync(ctx)
}

func (h *ApiHandler) PatchUsersMe(ctx echo.Context) error {
	// Call the updated handler method directly
	return h.Handler.UpdateCurrentUser(ctx)
}

// Implement HandleGetLocalLeaderboard to match the ServerInterface
func (h *ApiHandler) HandleGetLocalLeaderboard(ctx echo.Context, params HandleGetLocalLeaderboardParams) error {
	// Call the exported handler method
	// The underlying handler parses query params directly from ctx, so params are not passed
	return h.Handler.HandleGetLocalLeaderboard(ctx)
}

// Add missing HandleGetWorkouts implementation
func (h *ApiHandler) HandleGetWorkouts(ctx echo.Context, params HandleGetWorkoutsParams) error {
	// Call the handler for user exercise history (assuming GetUserExercises handles /workouts logic)
	return h.Handler.GetUserExercises(ctx)
}

// Add missing HandleUpdateUserLocation implementation
func (h *ApiHandler) HandleUpdateUserLocation(ctx echo.Context) error {
	// Assuming there's a handler function UpdateUserLocation in handlers/profile_handler.go or similar
	// return h.Handler.UpdateUserLocation(ctx) // Example call
	// Placeholder implementation:
	log.Println("HandleUpdateUserLocation called, but handler not implemented/connected yet.")
	return ctx.JSON(http.StatusNotImplemented, "Update location not implemented")
}

// FeaturesHandler implements a fallback feature flags endpoint
func (h *ApiHandler) FeaturesHandler(ctx echo.Context) error {
	return h.Handler.FeaturesHandler(ctx)
}
