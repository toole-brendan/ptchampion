package com.example.ptchampion.ui.screens.leaderboard;

import androidx.lifecycle.ViewModel;
import androidx.lifecycle.ViewModelProvider;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.LocalLeaderboardEntry;
import kotlinx.coroutines.flow.StateFlow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000>\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0010$\n\u0002\u0010\u000e\n\u0002\u0010\u000b\n\u0002\b\u0004\u0018\u00002\u00020\u0001B\u0011\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\u0002\u0010\u0004J\u0006\u0010\r\u001a\u00020\u000eJ\b\u0010\u000f\u001a\u00020\u000eH\u0002J\u001a\u0010\u0010\u001a\u00020\u000e2\u0012\u0010\u0011\u001a\u000e\u0012\u0004\u0012\u00020\u0013\u0012\u0004\u0012\u00020\u00140\u0012J\u000e\u0010\u0015\u001a\u00020\u000e2\u0006\u0010\u0002\u001a\u00020\u0003J\u000e\u0010\u0016\u001a\u00020\u000e2\u0006\u0010\u0017\u001a\u00020\u0014R\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0012\u0010\u0002\u001a\u0004\u0018\u00010\u0003X\u0082\u0004\u00a2\u0006\u0004\n\u0002\u0010\bR\u0017\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u00070\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\f\u00a8\u0006\u0018"}, d2 = {"Lcom/example/ptchampion/ui/screens/leaderboard/LocalLeaderboardViewModel;", "Landroidx/lifecycle/ViewModel;", "exerciseId", "", "(Ljava/lang/Integer;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/example/ptchampion/ui/screens/leaderboard/LocalLeaderboardUiState;", "Ljava/lang/Integer;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "fetchLocationAndLoadLeaderboard", "", "loadExercises", "onPermissionResult", "results", "", "", "", "selectExercise", "toggleExerciseDropdown", "expanded", "app_debug"})
public final class LocalLeaderboardViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer exerciseId = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.MutableStateFlow<com.example.ptchampion.ui.screens.leaderboard.LocalLeaderboardUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.leaderboard.LocalLeaderboardUiState> uiState = null;
    
    public LocalLeaderboardViewModel(@org.jetbrains.annotations.Nullable
    java.lang.Integer exerciseId) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.leaderboard.LocalLeaderboardUiState> getUiState() {
        return null;
    }
    
    private final void loadExercises() {
    }
    
    public final void selectExercise(int exerciseId) {
    }
    
    public final void toggleExerciseDropdown(boolean expanded) {
    }
    
    public final void onPermissionResult(@org.jetbrains.annotations.NotNull
    java.util.Map<java.lang.String, java.lang.Boolean> results) {
    }
    
    public final void fetchLocationAndLoadLeaderboard() {
    }
    
    public LocalLeaderboardViewModel() {
        super();
    }
}