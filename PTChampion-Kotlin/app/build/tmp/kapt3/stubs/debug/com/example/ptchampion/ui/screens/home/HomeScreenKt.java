package com.example.ptchampion.ui.screens.home;

import androidx.annotation.DrawableRes;
import androidx.compose.foundation.layout.*;
import androidx.compose.material.icons.Icons;
import androidx.compose.material.icons.filled.*;
import androidx.compose.material3.*;
import androidx.compose.runtime.Composable;
import androidx.compose.ui.Alignment;
import androidx.compose.ui.Modifier;
import androidx.compose.ui.graphics.vector.ImageVector;
import androidx.compose.ui.text.font.FontWeight;
import androidx.compose.ui.text.style.TextAlign;
import com.example.ptchampion.R;
import com.example.ptchampion.ui.theme.*;

@kotlin.Metadata(mv = {1, 9, 0}, k = 2, xi = 48, d1 = {"\u0000@\n\u0000\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0000\u001a\u0010\u0010\u0000\u001a\u00020\u00012\u0006\u0010\u0002\u001a\u00020\u0003H\u0007\u001ab\u0010\u0004\u001a\u00020\u00012\b\b\u0002\u0010\u0005\u001a\u00020\u00062\u000e\b\u0002\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\u00010\b2\u000e\b\u0002\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u00010\b2\u000e\b\u0002\u0010\n\u001a\b\u0012\u0004\u0012\u00020\u00010\b2\u000e\b\u0002\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\u00010\b2\u000e\b\u0002\u0010\f\u001a\b\u0012\u0004\u0012\u00020\u00010\bH\u0007\u001a\u0014\u0010\r\u001a\u00020\u00012\n\b\u0002\u0010\u000e\u001a\u0004\u0018\u00010\u000fH\u0007\u001a4\u0010\u0010\u001a\u00020\u00012\b\b\u0001\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u00142\b\b\u0002\u0010\u0015\u001a\u00020\u00162\u000e\b\u0002\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00010\bH\u0007\u001a\"\u0010\u0018\u001a\u00020\u00012\u0006\u0010\u0013\u001a\u00020\u00142\u0006\u0010\u0019\u001a\u00020\u00142\b\b\u0002\u0010\u0015\u001a\u00020\u0016H\u0007\u001a\u0014\u0010\u001a\u001a\u00020\u00012\n\b\u0002\u0010\u001b\u001a\u0004\u0018\u00010\u001cH\u0007\u00a8\u0006\u001d"}, d2 = {"BluetoothStatusIndicator", "", "isConnected", "", "HomeScreen", "viewModel", "Lcom/example/ptchampion/ui/screens/home/HomeViewModel;", "onNavigateToExercises", "Lkotlin/Function0;", "onNavigateToPushups", "onNavigateToRun", "onNavigateToSitups", "onNavigateToPullups", "LeaderboardRankCard", "userRank", "Lcom/example/ptchampion/ui/screens/home/UserRank;", "QuickActionButton", "iconResId", "", "label", "", "modifier", "Landroidx/compose/ui/Modifier;", "onClick", "RankItem", "rank", "RecentActivityCard", "recentWorkout", "Lcom/example/ptchampion/ui/screens/home/RecentWorkout;", "app_debug"})
public final class HomeScreenKt {
    
    @androidx.compose.runtime.Composable
    public static final void HomeScreen(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.home.HomeViewModel viewModel, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onNavigateToExercises, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onNavigateToPushups, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onNavigateToRun, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onNavigateToSitups, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onNavigateToPullups) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void QuickActionButton(@androidx.annotation.DrawableRes
    int iconResId, @org.jetbrains.annotations.NotNull
    java.lang.String label, @org.jetbrains.annotations.NotNull
    androidx.compose.ui.Modifier modifier, @org.jetbrains.annotations.NotNull
    kotlin.jvm.functions.Function0<kotlin.Unit> onClick) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void LeaderboardRankCard(@org.jetbrains.annotations.Nullable
    com.example.ptchampion.ui.screens.home.UserRank userRank) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void RankItem(@org.jetbrains.annotations.NotNull
    java.lang.String label, @org.jetbrains.annotations.NotNull
    java.lang.String rank, @org.jetbrains.annotations.NotNull
    androidx.compose.ui.Modifier modifier) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void RecentActivityCard(@org.jetbrains.annotations.Nullable
    com.example.ptchampion.ui.screens.home.RecentWorkout recentWorkout) {
    }
    
    @androidx.compose.runtime.Composable
    public static final void BluetoothStatusIndicator(boolean isConnected) {
    }
}