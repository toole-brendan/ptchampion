package com.example.ptchampion.ui.screens.camera;

import android.util.Log;
import androidx.lifecycle.ViewModel;
import com.example.ptchampion.posedetection.PoseLandmarkerHelper;
import kotlinx.coroutines.Dispatchers;
import kotlinx.coroutines.flow.StateFlow;
import androidx.camera.core.ImageProxy;
import com.example.ptchampion.domain.exercise.ExerciseState;
import androidx.lifecycle.SavedStateHandle;
import com.example.ptchampion.domain.exercise.AnalysisResult;
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer;
import com.example.ptchampion.domain.exercise.analyzers.PullupAnalyzer;
import com.example.ptchampion.domain.exercise.analyzers.PushupAnalyzer;
import com.example.ptchampion.domain.exercise.analyzers.SitupAnalyzer;
import com.example.ptchampion.ui.screens.leaderboard.ExerciseType;
import com.example.ptchampion.domain.repository.WorkoutRepository;
import com.example.ptchampion.domain.model.SaveWorkoutRequest;
import com.example.ptchampion.util.Resource;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import androidx.camera.core.CameraSelector;
import com.example.ptchampion.posedetection.RunningMode;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u000b\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B\u0019\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0005J\t\u0010\t\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\n\u001a\u00020\u0003H\u00c6\u0003J\u001d\u0010\u000b\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u0003H\u00c6\u0001J\u0013\u0010\f\u001a\u00020\u00032\b\u0010\r\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u000e\u001a\u00020\u000fH\u00d6\u0001J\t\u0010\u0010\u001a\u00020\u0011H\u00d6\u0001R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0007R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\b\u0010\u0007\u00a8\u0006\u0012"}, d2 = {"Lcom/example/ptchampion/ui/screens/camera/PermissionState;", "", "hasPermission", "", "shouldShowRationale", "(ZZ)V", "getHasPermission", "()Z", "getShouldShowRationale", "component1", "component2", "copy", "equals", "other", "hashCode", "", "toString", "", "app_release"})
public final class PermissionState {
    private final boolean hasPermission = false;
    private final boolean shouldShowRationale = false;
    
    public PermissionState(boolean hasPermission, boolean shouldShowRationale) {
        super();
    }
    
    public final boolean getHasPermission() {
        return false;
    }
    
    public final boolean getShouldShowRationale() {
        return false;
    }
    
    public PermissionState() {
        super();
    }
    
    public final boolean component1() {
        return false;
    }
    
    public final boolean component2() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.camera.PermissionState copy(boolean hasPermission, boolean shouldShowRationale) {
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