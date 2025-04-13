package com.example.ptchampion.ui.screens.leaderboard;

import androidx.compose.foundation.layout.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.text.font.FontWeight;
import com.example.ptchampion.domain.model.LeaderboardEntry;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u00002\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\u001a$\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\u0012\u0010\u0004\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u0005H\u0007\u001a\u0018\u0010\u0006\u001a\u00020\u00012\u0006\u0010\u0007\u001a\u00020\b2\u0006\u0010\t\u001a\u00020\nH\u0007\u001a\u0016\u0010\u000b\u001a\u00020\u00012\f\u0010\f\u001a\b\u0012\u0004\u0012\u00020\n0\rH\u0007\u001a\u0012\u0010\u000e\u001a\u00020\u00012\b\b\u0002\u0010\u000f\u001a\u00020\u0010H\u0007\u00a8\u0006\u0011"}, d2 = {"ExerciseTypeSelector", "", "selectedType", "Lcom/example/ptchampion/ui/screens/leaderboard/ExerciseType;", "onTypeSelected", "Lkotlin/Function1;", "LeaderboardItem", "rank", "", "entry", "Lcom/example/ptchampion/domain/model/LeaderboardEntry;", "LeaderboardList", "leaderboard", "", "LeaderboardScreen", "viewModel", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardViewModel;", "app_debug"})
public final class LeaderboardScreenKt {
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardScreen(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LeaderboardViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void ExerciseTypeSelector(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.ExerciseType selectedType, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super com.example.ptchampion.ui.screens.leaderboard.ExerciseType, kotlin.Unit> onTypeSelected) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardList(@org.jetbrains.annotations.NotNull
    java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry> leaderboard) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardItem(int rank, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.LeaderboardEntry entry) {
    }
}