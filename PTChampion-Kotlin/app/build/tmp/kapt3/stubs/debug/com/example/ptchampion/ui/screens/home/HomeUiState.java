package com.example.ptchampion.ui.screens.home;

import androidx.lifecycle.ViewModel;
import kotlinx.coroutines.flow.StateFlow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000.\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0014\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001BI\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b\u0012\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\n\u0012\b\b\u0002\u0010\u000b\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\fJ\t\u0010\u0015\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u0016\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010\u0017\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010\u0018\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\u000b\u0010\u0019\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\t\u0010\u001a\u001a\u00020\u0003H\u00c6\u0003JM\u0010\u001b\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u00052\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00052\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b2\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\n2\b\b\u0002\u0010\u000b\u001a\u00020\u0003H\u00c6\u0001J\u0013\u0010\u001c\u001a\u00020\u00032\b\u0010\u001d\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001e\u001a\u00020\u001fH\u00d6\u0001J\t\u0010 \u001a\u00020\u0005H\u00d6\u0001R\u0013\u0010\u0006\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0011\u0010\u000b\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\u000fR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0002\u0010\u000fR\u0013\u0010\u0007\u001a\u0004\u0018\u00010\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0013\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u000eR\u0013\u0010\t\u001a\u0004\u0018\u00010\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014\u00a8\u0006!"}, d2 = {"Lcom/example/ptchampion/ui/screens/home/HomeUiState;", "", "isLoading", "", "userName", "", "error", "recentWorkout", "Lcom/example/ptchampion/ui/screens/home/RecentWorkout;", "userRank", "Lcom/example/ptchampion/ui/screens/home/UserRank;", "isBluetoothConnected", "(ZLjava/lang/String;Ljava/lang/String;Lcom/example/ptchampion/ui/screens/home/RecentWorkout;Lcom/example/ptchampion/ui/screens/home/UserRank;Z)V", "getError", "()Ljava/lang/String;", "()Z", "getRecentWorkout", "()Lcom/example/ptchampion/ui/screens/home/RecentWorkout;", "getUserName", "getUserRank", "()Lcom/example/ptchampion/ui/screens/home/UserRank;", "component1", "component2", "component3", "component4", "component5", "component6", "copy", "equals", "other", "hashCode", "", "toString", "app_debug"})
public final class HomeUiState {
    private final boolean isLoading = false;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String userName = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String error = null;
    @org.jetbrains.annotations.Nullable
    private final com.example.ptchampion.ui.screens.home.RecentWorkout recentWorkout = null;
    @org.jetbrains.annotations.Nullable
    private final com.example.ptchampion.ui.screens.home.UserRank userRank = null;
    private final boolean isBluetoothConnected = false;
    
    public HomeUiState(boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String userName, @org.jetbrains.annotations.Nullable
    java.lang.String error, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.ui.screens.home.RecentWorkout recentWorkout, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.ui.screens.home.UserRank userRank, boolean isBluetoothConnected) {
        super();
    }
    
    public final boolean isLoading() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getUserName() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getError() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.ui.screens.home.RecentWorkout getRecentWorkout() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.ui.screens.home.UserRank getUserRank() {
        return null;
    }
    
    public final boolean isBluetoothConnected() {
        return false;
    }
    
    public HomeUiState() {
        super();
    }
    
    public final boolean component1() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.ui.screens.home.RecentWorkout component4() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.ui.screens.home.UserRank component5() {
        return null;
    }
    
    public final boolean component6() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.home.HomeUiState copy(boolean isLoading, @org.jetbrains.annotations.Nullable
    java.lang.String userName, @org.jetbrains.annotations.Nullable
    java.lang.String error, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.ui.screens.home.RecentWorkout recentWorkout, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.ui.screens.home.UserRank userRank, boolean isBluetoothConnected) {
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