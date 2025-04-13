package com.example.ptchampion.ui.screens.history;

import androidx.lifecycle.ViewModel;
import com.example.ptchampion.domain.repository.WorkoutRepository;
import com.example.ptchampion.domain.model.WorkoutResponse;
import com.example.ptchampion.util.Resource;
import kotlinx.coroutines.flow.StateFlow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0002\b\u0014\b\u0086\b\u0018\u00002\u00020\u0001B?\u0012\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0006\u0012\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u0012\b\b\u0002\u0010\u000b\u001a\u00020\u0006\u00a2\u0006\u0002\u0010\fJ\u000f\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\t\u0010\u0015\u001a\u00020\u0006H\u00c6\u0003J\u000b\u0010\u0016\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\t\u0010\u0017\u001a\u00020\nH\u00c6\u0003J\t\u0010\u0018\u001a\u00020\u0006H\u00c6\u0003JC\u0010\u0019\u001a\u00020\u00002\u000e\b\u0002\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00062\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b2\b\b\u0002\u0010\t\u001a\u00020\n2\b\b\u0002\u0010\u000b\u001a\u00020\u0006H\u00c6\u0001J\u0013\u0010\u001a\u001a\u00020\u00062\b\u0010\u001b\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001c\u001a\u00020\nH\u00d6\u0001J\t\u0010\u001d\u001a\u00020\bH\u00d6\u0001R\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0013\u0010\u0007\u001a\u0004\u0018\u00010\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u0011\u0010\u000b\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\u0011R\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0011R\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013\u00a8\u0006\u001e"}, d2 = {"Lcom/example/ptchampion/ui/screens/history/HistoryUiState;", "", "workouts", "", "Lcom/example/ptchampion/domain/model/WorkoutResponse;", "isLoading", "", "error", "", "currentPage", "", "isLastPage", "(Ljava/util/List;ZLjava/lang/String;IZ)V", "getCurrentPage", "()I", "getError", "()Ljava/lang/String;", "()Z", "getWorkouts", "()Ljava/util/List;", "component1", "component2", "component3", "component4", "component5", "copy", "equals", "other", "hashCode", "toString", "app_release"})
public final class HistoryUiState {
    @org.jetbrains.annotations.NotNull
    private final java.util.List<com.example.ptchampion.domain.model.WorkoutResponse> workouts = null;
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String error = null;
    private final int currentPage = 0;
    private final boolean isLastPage = false;
    
    public HistoryUiState(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.WorkoutResponse> workouts, boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String error, int currentPage, boolean isLastPage) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.WorkoutResponse> getWorkouts() {
        return null;
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getError() {
        return null;
    }
    
    public final int getCurrentPage() {
        return 0;
    }
    
    public final boolean isLastPage() {
        return false;
    }
    
    public HistoryUiState() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<com.example.ptchampion.domain.model.WorkoutResponse> component1() {
        return null;
    }
    
    public final boolean component2() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component3() {
        return null;
    }
    
    public final int component4() {
        return 0;
    }
    
    public final boolean component5() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.history.HistoryUiState copy(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.WorkoutResponse> workouts, boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String error, int currentPage, boolean isLastPage) {
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