package com.example.ptchampion.ui.screens.leaderboard;

import androidx.lifecycle.ViewModel;
import kotlinx.coroutines.flow.StateFlow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000<\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0005\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\n\u001a\u00020\u000bH\u0002J&\u0010\f\u001a\b\u0012\u0004\u0012\u00020\u000e0\r2\u0006\u0010\u000f\u001a\u00020\u00102\u0006\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u0012H\u0002J\u000e\u0010\u0014\u001a\u00020\u000b2\u0006\u0010\u0015\u001a\u00020\u0012J\u000e\u0010\u0016\u001a\u00020\u000b2\u0006\u0010\u0015\u001a\u00020\u0010R\u0014\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00050\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\t\u00a8\u0006\u0017"}, d2 = {"Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardViewModel;", "Landroidx/lifecycle/ViewModel;", "()V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "fetchLeaderboardData", "", "generateMockData", "", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardEntry;", "boardType", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardType;", "exercise", "", "currentUserId", "selectExerciseType", "type", "selectLeaderboardType", "app_debug"})
public final class LeaderboardViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.MutableStateFlow<com.example.ptchampion.ui.screens.leaderboard.LeaderboardUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.leaderboard.LeaderboardUiState> uiState = null;
    
    public LeaderboardViewModel() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.leaderboard.LeaderboardUiState> getUiState() {
        return null;
    }
    
    public final void selectExerciseType(@org.jetbrains.annotations.NotNull
    java.lang.String type) {
    }
    
    public final void selectLeaderboardType(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LeaderboardType type) {
    }
    
    private final void fetchLeaderboardData() {
    }
    
    private final java.util.List<com.example.ptchampion.ui.screens.leaderboard.LeaderboardEntry> generateMockData(com.example.ptchampion.ui.screens.leaderboard.LeaderboardType boardType, java.lang.String exercise, java.lang.String currentUserId) {
        return null;
    }
}