package com.example.ptchampion.ui.screens.leaderboard;

import androidx.compose.runtime.State;
import androidx.lifecycle.ViewModel;
import com.example.ptchampion.domain.repository.LeaderboardRepository;
import com.example.ptchampion.domain.model.LeaderboardEntry;
import com.example.ptchampion.util.Resource;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000,\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\b\u0010\n\u001a\u00020\u000bH\u0002J\u000e\u0010\f\u001a\u00020\u000b2\u0006\u0010\r\u001a\u00020\u000eR\u0014\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00050\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\t\u00a8\u0006\u000f"}, d2 = {"Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardViewModel;", "Landroidx/lifecycle/ViewModel;", "()V", "_state", "Landroidx/compose/runtime/MutableState;", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardState;", "state", "Landroidx/compose/runtime/State;", "getState", "()Landroidx/compose/runtime/State;", "fetchLeaderboard", "", "selectExerciseType", "type", "Lcom/example/ptchampion/ui/screens/leaderboard/ExerciseType;", "app_release"})
public final class LeaderboardViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull
    private final androidx.compose.runtime.MutableState<com.example.ptchampion.ui.screens.leaderboard.LeaderboardState> _state = null;
    @org.jetbrains.annotations.NotNull
    private final androidx.compose.runtime.State<com.example.ptchampion.ui.screens.leaderboard.LeaderboardState> state = null;
    
    public LeaderboardViewModel() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final androidx.compose.runtime.State<com.example.ptchampion.ui.screens.leaderboard.LeaderboardState> getState() {
        return null;
    }
    
    public final void selectExerciseType(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.ExerciseType type) {
    }
    
    private final void fetchLeaderboard() {
    }
}