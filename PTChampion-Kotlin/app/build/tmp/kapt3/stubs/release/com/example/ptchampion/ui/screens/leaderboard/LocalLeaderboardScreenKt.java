package com.example.ptchampion.ui.screens.leaderboard;

import android.Manifest;
import android.util.Log;
import androidx.compose.foundation.layout.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.*;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.tooling.preview.Preview;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.LocalLeaderboardEntry;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000\u001e\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\u001a\u0010\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u0003H\u0007\u001a#\u0010\u0004\u001a\u00020\u00012\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u00062\b\b\u0002\u0010\u0007\u001a\u00020\bH\u0007\u00a2\u0006\u0002\u0010\t\u001a\b\u0010\n\u001a\u00020\u0001H\u0007\u00a8\u0006\u000b"}, d2 = {"LocalLeaderboardListItem", "", "entry", "Lcom/example/ptchampion/domain/model/LocalLeaderboardEntry;", "LocalLeaderboardScreen", "exerciseId", "", "viewModel", "Lcom/example/ptchampion/ui/screens/leaderboard/LocalLeaderboardViewModel;", "(Ljava/lang/Integer;Lcom/example/ptchampion/ui/screens/leaderboard/LocalLeaderboardViewModel;)V", "LocalLeaderboardScreenPreview", "app_release"})
public final class LocalLeaderboardScreenKt {
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.runtime.Composable
    public static final void LocalLeaderboardScreen(@org.jetbrains.annotations.Nullable
    java.lang.Integer exerciseId, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.leaderboard.LocalLeaderboardViewModel viewModel) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LocalLeaderboardListItem(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.LocalLeaderboardEntry entry) {
    }
    
    @kotlin.OptIn(markerClass = {androidx.compose.material3.ExperimentalMaterial3Api.class})
    @androidx.compose.ui.tooling.preview.Preview(showBackground = true)
    @androidx.compose.runtime.Composable
    public static final void LocalLeaderboardScreenPreview() {
    }
}