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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000l\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0010\u000b\n\u0002\b\u000b\u0018\u00002\u00020\u0001B\r\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0010\u0010\u001e\u001a\u00020\u001f2\u0006\u0010 \u001a\u00020!H\u0002J\b\u0010\"\u001a\u00020\u001fH\u0002J\b\u0010#\u001a\u00020\u001fH\u0014J\u0016\u0010$\u001a\u00020\u001f2\u0006\u0010%\u001a\u00020&2\u0006\u0010\'\u001a\u00020&J\u0006\u0010(\u001a\u00020\u001fJ\u000e\u0010)\u001a\u00020\u001f2\u0006\u0010 \u001a\u00020!J \u0010*\u001a\u00020\u001f2\u0006\u0010+\u001a\u00020\u000e2\u0006\u0010,\u001a\u00020\u000e2\u0006\u0010-\u001a\u00020\u0019H\u0002J\u0006\u0010.\u001a\u00020\u001fJ\u0006\u0010/\u001a\u00020\u001fJ\u0006\u00100\u001a\u00020\u001fR\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\b\u001a\b\u0012\u0004\u0012\u00020\n0\tX\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u000b\u001a\u0004\u0018\u00010\fX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0012\u0010\r\u001a\u0004\u0018\u00010\u000eX\u0082\u0004\u00a2\u0006\u0004\n\u0002\u0010\u000fR\u0010\u0010\u0010\u001a\u0004\u0018\u00010\u0011X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0012\u001a\u0004\u0018\u00010\u0013X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00070\u0015\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0018\u001a\u0004\u0018\u00010\u0019X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0017\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\n0\u001b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u001d\u00a8\u00061"}, d2 = {"Lcom/example/ptchampion/ui/screens/camera/CameraViewModel;", "Landroidx/lifecycle/ViewModel;", "savedStateHandle", "Landroidx/lifecycle/SavedStateHandle;", "(Landroidx/lifecycle/SavedStateHandle;)V", "_navigationEvent", "Lkotlinx/coroutines/channels/Channel;", "Lcom/example/ptchampion/ui/screens/camera/CameraNavigationEvent;", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/example/ptchampion/ui/screens/camera/CameraUiState;", "exerciseAnalyzer", "Lcom/example/ptchampion/domain/exercise/ExerciseAnalyzer;", "exerciseId", "", "Ljava/lang/Integer;", "exerciseType", "Lcom/example/ptchampion/ui/screens/leaderboard/ExerciseType;", "exerciseTypeString", "", "navigationEvent", "Lkotlinx/coroutines/flow/Flow;", "getNavigationEvent", "()Lkotlinx/coroutines/flow/Flow;", "sessionStartTime", "Ljava/time/Instant;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "closeImageProxy", "", "imageProxy", "Landroidx/camera/core/ImageProxy;", "initializePoseLandmarker", "onCleared", "onPermissionResult", "granted", "", "shouldShowRationale", "pauseSession", "processFrame", "saveWorkoutSession", "reps", "duration", "completedAt", "startSession", "stopSession", "toggleCameraLens", "app_release"})
public final class CameraViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull
    private final androidx.lifecycle.SavedStateHandle savedStateHandle = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.MutableStateFlow<com.example.ptchampion.ui.screens.camera.CameraUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.camera.CameraUiState> uiState = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.channels.Channel<com.example.ptchampion.ui.screens.camera.CameraNavigationEvent> _navigationEvent = null;
    @org.jetbrains.annotations.NotNull
    private final kotlinx.coroutines.flow.Flow<com.example.ptchampion.ui.screens.camera.CameraNavigationEvent> navigationEvent = null;
    @org.jetbrains.annotations.Nullable
    private com.example.ptchampion.domain.exercise.ExerciseAnalyzer exerciseAnalyzer;
    @org.jetbrains.annotations.Nullable
    private java.time.Instant sessionStartTime;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String exerciseTypeString = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer exerciseId = null;
    @org.jetbrains.annotations.Nullable
    private final com.example.ptchampion.ui.screens.leaderboard.ExerciseType exerciseType = null;
    
    public CameraViewModel(@org.jetbrains.annotations.NotNull
    androidx.lifecycle.SavedStateHandle savedStateHandle) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.StateFlow<com.example.ptchampion.ui.screens.camera.CameraUiState> getUiState() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final kotlinx.coroutines.flow.Flow<com.example.ptchampion.ui.screens.camera.CameraNavigationEvent> getNavigationEvent() {
        return null;
    }
    
    private final void initializePoseLandmarker() {
    }
    
    public final void onPermissionResult(boolean granted, boolean shouldShowRationale) {
    }
    
    public final void processFrame(@org.jetbrains.annotations.NotNull
    androidx.camera.core.ImageProxy imageProxy) {
    }
    
    private final void closeImageProxy(androidx.camera.core.ImageProxy imageProxy) {
    }
    
    public final void startSession() {
    }
    
    public final void pauseSession() {
    }
    
    public final void stopSession() {
    }
    
    private final void saveWorkoutSession(int reps, int duration, java.time.Instant completedAt) {
    }
    
    public final void toggleCameraLens() {
    }
    
    @java.lang.Override
    protected void onCleared() {
    }
}