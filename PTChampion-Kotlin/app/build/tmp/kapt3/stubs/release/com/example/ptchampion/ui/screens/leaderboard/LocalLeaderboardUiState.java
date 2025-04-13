package com.example.ptchampion.ui.screens.leaderboard;

import androidx.lifecycle.ViewModel;
import androidx.lifecycle.ViewModelProvider;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.LocalLeaderboardEntry;
import kotlinx.coroutines.flow.StateFlow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0018\b\u0086\b\u0018\u00002\u00020\u0001BY\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0006\u0012\b\b\u0002\u0010\u0007\u001a\u00020\b\u0012\u000e\b\u0002\u0010\t\u001a\b\u0012\u0004\u0012\u00020\n0\u0003\u0012\b\b\u0002\u0010\u000b\u001a\u00020\b\u0012\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r\u0012\b\b\u0002\u0010\u000e\u001a\u00020\b\u00a2\u0006\u0002\u0010\u000fJ\u000f\u0010\u0019\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\t\u0010\u001a\u001a\u00020\u0006H\u00c6\u0003J\t\u0010\u001b\u001a\u00020\bH\u00c6\u0003J\u000f\u0010\u001c\u001a\b\u0012\u0004\u0012\u00020\n0\u0003H\u00c6\u0003J\t\u0010\u001d\u001a\u00020\bH\u00c6\u0003J\u000b\u0010\u001e\u001a\u0004\u0018\u00010\rH\u00c6\u0003J\t\u0010\u001f\u001a\u00020\bH\u00c6\u0003J]\u0010 \u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00062\b\b\u0002\u0010\u0007\u001a\u00020\b2\u000e\b\u0002\u0010\t\u001a\b\u0012\u0004\u0012\u00020\n0\u00032\b\b\u0002\u0010\u000b\u001a\u00020\b2\n\b\u0002\u0010\f\u001a\u0004\u0018\u00010\r2\b\b\u0002\u0010\u000e\u001a\u00020\bH\u00c6\u0001J\u0013\u0010!\u001a\u00020\b2\b\u0010\"\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010#\u001a\u00020\u0006H\u00d6\u0001J\t\u0010$\u001a\u00020\rH\u00d6\u0001R\u0013\u0010\f\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013R\u0011\u0010\u000e\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u0011\u0010\u0007\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\u0015R\u0011\u0010\u000b\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\u0015R\u0017\u0010\t\u001a\b\u0012\u0004\u0012\u00020\n0\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0013R\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0018\u00a8\u0006%"}, d2 = {"Lcom/example/ptchampion/ui/screens/leaderboard/LocalLeaderboardUiState;", "", "exercises", "", "Lcom/example/ptchampion/domain/model/ExerciseResponse;", "selectedExerciseId", "", "isExerciseDropdownExpanded", "", "leaderboardEntries", "Lcom/example/ptchampion/domain/model/LocalLeaderboardEntry;", "isLoading", "error", "", "hasLocationPermission", "(Ljava/util/List;IZLjava/util/List;ZLjava/lang/String;Z)V", "getError", "()Ljava/lang/String;", "getExercises", "()Ljava/util/List;", "getHasLocationPermission", "()Z", "getLeaderboardEntries", "getSelectedExerciseId", "()I", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "copy", "equals", "other", "hashCode", "toString", "app_release"})
public final class LocalLeaderboardUiState {
    @org.jetbrains.annotations.NotNull
    private final java.util.List<com.example.ptchampion.domain.model.ExerciseResponse> exercises = null;
    private final int selectedExerciseId = 0;
    private final boolean isExerciseDropdownExpanded = false;
    @org.jetbrains.annotations.NotNull
    private final java.util.List<com.example.ptchampion.domain.model.LocalLeaderboardEntry> leaderboardEntries = null;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String error = null;
    private final boolean hasLocationPermission = false;
    
    public LocalLeaderboardUiState(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.ExerciseResponse> exercises, int selectedExerciseId, boolean isExerciseDropdownExpanded, @org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.LocalLeaderboardEntry> leaderboardEntries, boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String error, boolean hasLocationPermission) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.ExerciseResponse> getExercises() {
        return null;
    }
    
    public final int getSelectedExerciseId() {
        return 0;
    }
    
    public final boolean isExerciseDropdownExpanded() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.LocalLeaderboardEntry> getLeaderboardEntries() {
        return null;
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getError() {
        return null;
    }
    
    public final boolean getHasLocationPermission() {
        return false;
    }
    
    public LocalLeaderboardUiState() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.ExerciseResponse> component1() {
        return null;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final boolean component3() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.LocalLeaderboardEntry> component4() {
        return null;
    }
    
    public final boolean component5() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component6() {
        return null;
    }
    
    public final boolean component7() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.leaderboard.LocalLeaderboardUiState copy(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.ExerciseResponse> exercises, int selectedExerciseId, boolean isExerciseDropdownExpanded, @org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.LocalLeaderboardEntry> leaderboardEntries, boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String error, boolean hasLocationPermission) {
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