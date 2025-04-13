package com.example.ptchampion.ui.screens.leaderboard;

import androidx.compose.runtime.State;
import androidx.lifecycle.ViewModel;
import com.example.ptchampion.domain.repository.LeaderboardRepository;
import com.example.ptchampion.domain.model.LeaderboardEntry;
import com.example.ptchampion.util.Resource;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0010\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001B5\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0006\u0012\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u00a2\u0006\u0002\u0010\u000bJ\u000f\u0010\u0013\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\t\u0010\u0014\u001a\u00020\u0006H\u00c6\u0003J\u000b\u0010\u0015\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\t\u0010\u0016\u001a\u00020\nH\u00c6\u0003J9\u0010\u0017\u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00062\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b2\b\b\u0002\u0010\t\u001a\u00020\nH\u00c6\u0001J\u0013\u0010\u0018\u001a\u00020\u00062\b\u0010\u0019\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001a\u001a\u00020\u001bH\u00d6\u0001J\t\u0010\u001c\u001a\u00020\bH\u00d6\u0001R\u0013\u0010\u0007\u001a\u0004\u0018\u00010\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u000eR\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012\u00a8\u0006\u001d"}, d2 = {"Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardState;", "", "leaderboard", "", "Lcom/example/ptchampion/domain/model/LeaderboardEntry;", "isLoading", "", "error", "", "selectedExerciseType", "Lcom/example/ptchampion/ui/screens/leaderboard/ExerciseType;", "(Ljava/util/List;ZLjava/lang/String;Lcom/example/ptchampion/ui/screens/leaderboard/ExerciseType;)V", "getError", "()Ljava/lang/String;", "()Z", "getLeaderboard", "()Ljava/util/List;", "getSelectedExerciseType", "()Lcom/example/ptchampion/ui/screens/leaderboard/ExerciseType;", "component1", "component2", "component3", "component4", "copy", "equals", "other", "hashCode", "", "toString", "app_release"})
public final class LeaderboardState {
    @org.jetbrains.annotations.NotNull
    private final java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry> leaderboard = null;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String error = null;
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.ui.screens.leaderboard.ExerciseType selectedExerciseType = null;
    
    public LeaderboardState(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry> leaderboard, boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String error, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.ExerciseType selectedExerciseType) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry> getLeaderboard() {
        return null;
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getError() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.leaderboard.ExerciseType getSelectedExerciseType() {
        return null;
    }
    
    public LeaderboardState() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry> component1() {
        return null;
    }
    
    public final boolean component2() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component3() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.leaderboard.ExerciseType component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.leaderboard.LeaderboardState copy(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry> leaderboard, boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String error, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.ExerciseType selectedExerciseType) {
        return null;
    }
    
    @java.lang.Override
    public boolean equals(@org.jetbrains.annotations.Nullable
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public java.lang.String toString() {
        return null;
    }
}