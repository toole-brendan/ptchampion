package com.example.ptchampion.ui.screens.leaderboard;

import androidx.lifecycle.ViewModel;
import androidx.lifecycle.ViewModelProvider;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.LocalLeaderboardEntry;
import kotlinx.coroutines.flow.StateFlow;

/**
 * Factory for creating a [LocalLeaderboardViewModel] with a specific exerciseId
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000 \n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\u0018\u00002\u00020\u0001B\u0011\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\u0002\u0010\u0004J%\u0010\u0006\u001a\u0002H\u0007\"\b\b\u0000\u0010\u0007*\u00020\b2\f\u0010\t\u001a\b\u0012\u0004\u0012\u0002H\u00070\nH\u0016\u00a2\u0006\u0002\u0010\u000bR\u0012\u0010\u0002\u001a\u0004\u0018\u00010\u0003X\u0082\u0004\u00a2\u0006\u0004\n\u0002\u0010\u0005\u00a8\u0006\f"}, d2 = {"Lcom/example/ptchampion/ui/screens/leaderboard/LocalLeaderboardViewModelFactory;", "Landroidx/lifecycle/ViewModelProvider$Factory;", "exerciseId", "", "(Ljava/lang/Integer;)V", "Ljava/lang/Integer;", "create", "T", "Landroidx/lifecycle/ViewModel;", "modelClass", "Ljava/lang/Class;", "(Ljava/lang/Class;)Landroidx/lifecycle/ViewModel;", "app_release"})
public final class LocalLeaderboardViewModelFactory implements androidx.lifecycle.ViewModelProvider.Factory {
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer exerciseId = null;
    
    public LocalLeaderboardViewModelFactory(@org.jetbrains.annotations.Nullable
    java.lang.Integer exerciseId) {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public <T extends androidx.lifecycle.ViewModel>T create(@org.jetbrains.annotations.NotNull
    java.lang.Class<T> modelClass) {
        return null;
    }
    
    public LocalLeaderboardViewModelFactory() {
        super();
    }
}