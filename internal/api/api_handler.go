package api

import (
	"ptchampion/internal/api/handlers" // Import the handlers package
	"ptchampion/internal/config"
	dbStore "ptchampion/internal/store/postgres"

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
	// We can now call the updated handler method directly
	return h.Handler.GetUserExercises(ctx)
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
