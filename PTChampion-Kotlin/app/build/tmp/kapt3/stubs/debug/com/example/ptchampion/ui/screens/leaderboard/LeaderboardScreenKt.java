package com.example.ptchampion.ui.screens.leaderboard;

import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.style.TextAlign;
import com.example.ptchampion.ui.theme.*;
import java.util.concurrent.TimeUnit;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000@\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010 \n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\t\n\u0000\u001a2\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00032\f\u0010\u0004\u001a\b\u0012\u0004\u0012\u00020\u00030\u00052\u0012\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u00010\u0007H\u0007\u001a\u0010\u0010\b\u001a\u00020\u00012\u0006\u0010\t\u001a\u00020\nH\u0007\u001a \u0010\u000b\u001a\u00020\u00012\u0006\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\n2\u0006\u0010\t\u001a\u00020\nH\u0007\u001a\u0012\u0010\u000f\u001a\u00020\u00012\b\b\u0002\u0010\u0010\u001a\u00020\u0011H\u0007\u001a$\u0010\u0012\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u00132\u0012\u0010\u0006\u001a\u000e\u0012\u0004\u0012\u00020\u0013\u0012\u0004\u0012\u00020\u00010\u0007H\u0007\u001a\u0010\u0010\u0014\u001a\u00020\u00012\u0006\u0010\u0015\u001a\u00020\u0013H\u0007\u001a\u000e\u0010\u0016\u001a\u00020\u00032\u0006\u0010\u0017\u001a\u00020\u0018\u00a8\u0006\u0019"}, d2 = {"ExerciseTypeDropdown", "", "selectedType", "", "availableTypes", "", "onTypeSelected", "Lkotlin/Function1;", "LeaderboardHeaderRow", "isTimeBased", "", "LeaderboardListItem", "entry", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardEntry;", "isCurrentUser", "LeaderboardScreen", "viewModel", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardViewModel;", "LeaderboardTypeToggle", "Lcom/example/ptchampion/ui/screens/leaderboard/LeaderboardType;", "ListHeader", "leaderboardType", "formatDuration", "millis", "", "app_debug"})
public final class LeaderboardScreenKt {
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardScreen(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LeaderboardViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardTypeToggle(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LeaderboardType selectedType, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super com.example.ptchampion.ui.screens.leaderboard.LeaderboardType, kotlin.Unit> onTypeSelected) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void ListHeader(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LeaderboardType leaderboardType) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void ExerciseTypeDropdown(@org.jetbrains.annotations.NotNull
    java.lang.String selectedType, @org.jetbrains.annotations.NotNull
    java.util.List<java.lang.String> availableTypes, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function1<? super java.lang.String, kotlin.Unit> onTypeSelected) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardHeaderRow(boolean isTimeBased) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardListItem(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LeaderboardEntry entry, boolean isCurrentUser, boolean isTimeBased) {
    }
    
    @org.jetbrains.annotations.NotNull
    public static final java.lang.String formatDuration(long millis) {
        return null;
    }
}