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
import com.example.ptchampion.domain.repository.WorkoutRepository;
import com.example.ptchampion.domain.model.SaveWorkoutRequest;
import com.example.ptchampion.util.Resource;
import java.time.Instant;
import java.time.ZoneOffset;
import java.time.format.DateTimeFormatter;
import androidx.camera.core.CameraSelector;
import com.example.ptchampion.posedetection.RunningMode;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000:\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b,\b\u0086\b\u0018\u00002\u00020\u0001B\u009b\u0001\u0012\b\b\u0002\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u0007\u0012\b\b\u0002\u0010\t\u001a\u00020\n\u0012\b\b\u0002\u0010\u000b\u001a\u00020\f\u0012\b\b\u0002\u0010\r\u001a\u00020\u000e\u0012\n\b\u0002\u0010\u000f\u001a\u0004\u0018\u00010\u0007\u0012\b\b\u0002\u0010\u0010\u001a\u00020\u000e\u0012\b\b\u0002\u0010\u0011\u001a\u00020\u0012\u0012\b\b\u0002\u0010\u0013\u001a\u00020\n\u0012\n\b\u0002\u0010\u0014\u001a\u0004\u0018\u00010\u0007\u0012\b\b\u0002\u0010\u0015\u001a\u00020\n\u0012\b\b\u0002\u0010\u0016\u001a\u00020\u000e\u00a2\u0006\u0002\u0010\u0017J\t\u0010+\u001a\u00020\u0003H\u00c6\u0003J\t\u0010,\u001a\u00020\u0012H\u00c6\u0003J\t\u0010-\u001a\u00020\nH\u00c6\u0003J\u000b\u0010.\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\t\u0010/\u001a\u00020\nH\u00c6\u0003J\t\u00100\u001a\u00020\u000eH\u00c6\u0003J\u000b\u00101\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u00102\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\u000b\u00103\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\t\u00104\u001a\u00020\nH\u00c6\u0003J\t\u00105\u001a\u00020\fH\u00c6\u0003J\t\u00106\u001a\u00020\u000eH\u00c6\u0003J\u000b\u00107\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\t\u00108\u001a\u00020\u000eH\u00c6\u0003J\u009f\u0001\u00109\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u00052\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00072\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\u00072\b\b\u0002\u0010\t\u001a\u00020\n2\b\b\u0002\u0010\u000b\u001a\u00020\f2\b\b\u0002\u0010\r\u001a\u00020\u000e2\n\b\u0002\u0010\u000f\u001a\u0004\u0018\u00010\u00072\b\b\u0002\u0010\u0010\u001a\u00020\u000e2\b\b\u0002\u0010\u0011\u001a\u00020\u00122\b\b\u0002\u0010\u0013\u001a\u00020\n2\n\b\u0002\u0010\u0014\u001a\u0004\u0018\u00010\u00072\b\b\u0002\u0010\u0015\u001a\u00020\n2\b\b\u0002\u0010\u0016\u001a\u00020\u000eH\u00c6\u0001J\u0013\u0010:\u001a\u00020\n2\b\u0010;\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010<\u001a\u00020\u000eH\u00d6\u0001J\t\u0010=\u001a\u00020\u0007H\u00d6\u0001R\u0011\u0010\u0016\u001a\u00020\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019R\u0011\u0010\u0011\u001a\u00020\u0012\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u001bR\u0013\u0010\b\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u001dR\u0013\u0010\u000f\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001e\u0010\u001dR\u0011\u0010\u0010\u001a\u00020\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010\u0019R\u0013\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010\u001dR\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010!R\u0011\u0010\u0013\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010!R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\"\u0010#R\u0013\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b$\u0010%R\u0011\u0010\r\u001a\u00020\u000e\u00a2\u0006\b\n\u0000\u001a\u0004\b&\u0010\u0019R\u0013\u0010\u0014\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\'\u0010\u001dR\u0011\u0010\u0015\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b(\u0010!R\u0011\u0010\u000b\u001a\u00020\f\u00a2\u0006\b\n\u0000\u001a\u0004\b)\u0010*\u00a8\u0006>"}, d2 = {"Lcom/example/ptchampion/ui/screens/camera/CameraUiState;", "", "permissionState", "Lcom/example/ptchampion/ui/screens/camera/PermissionState;", "poseLandmarkerResult", "Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "initializationError", "", "detectionError", "isInitializing", "", "sessionState", "Lcom/example/ptchampion/ui/screens/camera/SessionState;", "repCount", "", "exerciseFeedback", "formScore", "currentExerciseState", "Lcom/example/ptchampion/domain/exercise/ExerciseState;", "isSaving", "saveError", "saveSuccess", "cameraSelectorSelected", "(Lcom/example/ptchampion/ui/screens/camera/PermissionState;Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;Ljava/lang/String;Ljava/lang/String;ZLcom/example/ptchampion/ui/screens/camera/SessionState;ILjava/lang/String;ILcom/example/ptchampion/domain/exercise/ExerciseState;ZLjava/lang/String;ZI)V", "getCameraSelectorSelected", "()I", "getCurrentExerciseState", "()Lcom/example/ptchampion/domain/exercise/ExerciseState;", "getDetectionError", "()Ljava/lang/String;", "getExerciseFeedback", "getFormScore", "getInitializationError", "()Z", "getPermissionState", "()Lcom/example/ptchampion/ui/screens/camera/PermissionState;", "getPoseLandmarkerResult", "()Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "getRepCount", "getSaveError", "getSaveSuccess", "getSessionState", "()Lcom/example/ptchampion/ui/screens/camera/SessionState;", "component1", "component10", "component11", "component12", "component13", "component14", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "other", "hashCode", "toString", "app_debug"})
public final class CameraUiState {
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.ui.screens.camera.PermissionState permissionState = null;
    @org.jetbrains.annotations.Nullable
    private final com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle poseLandmarkerResult = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String initializationError = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String detectionError = null;
    private final boolean isInitializing = false;
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.ui.screens.camera.SessionState sessionState = null;
    private final int repCount = 0;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String exerciseFeedback = null;
    private final int formScore = 0;
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.domain.exercise.ExerciseState currentExerciseState = null;
    private final boolean isSaving = false;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String saveError = null;
    private final boolean saveSuccess = false;
    private final int cameraSelectorSelected = 0;
    
    public CameraUiState(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.camera.PermissionState permissionState, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle poseLandmarkerResult, @org.jetbrains.annotations.Nullable
    java.lang.String initializationError, @org.jetbrains.annotations.Nullable
    java.lang.String detectionError, boolean isInitializing, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.camera.SessionState sessionState, int repCount, @org.jetbrains.annotations.Nullable
    java.lang.String exerciseFeedback, int formScore, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.ExerciseState currentExerciseState, boolean isSaving, @org.jetbrains.annotations.Nullable
    java.lang.String saveError, boolean saveSuccess, int cameraSelectorSelected) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.camera.PermissionState getPermissionState() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle getPoseLandmarkerResult() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getInitializationError() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getDetectionError() {
        return null;
    }
    
    public final boolean isInitializing() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.camera.SessionState getSessionState() {
        return null;
    }
    
    public final int getRepCount() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getExerciseFeedback() {
        return null;
    }
    
    public final int getFormScore() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.domain.exercise.ExerciseState getCurrentExerciseState() {
        return null;
    }
    
    public final boolean isSaving() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getSaveError() {
        return null;
    }
    
    public final boolean getSaveSuccess() {
        return false;
    }
    
    public final int getCameraSelectorSelected() {
        return 0;
    }
    
    public CameraUiState() {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.camera.PermissionState component1() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.domain.exercise.ExerciseState component10() {
        return null;
    }
    
    public final boolean component11() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component12() {
        return null;
    }
    
    public final boolean component13() {
        return false;
    }
    
    public final int component14() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component4() {
        return null;
    }
    
    public final boolean component5() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.camera.SessionState component6() {
        return null;
    }
    
    public final int component7() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component8() {
        return null;
    }
    
    public final int component9() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.ui.screens.camera.CameraUiState copy(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.camera.PermissionState permissionState, @org.jetbrains.annotations.Nullable
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle poseLandmarkerResult, @org.jetbrains.annotations.Nullable
    java.lang.String initializationError, @org.jetbrains.annotations.Nullable
    java.lang.String detectionError, boolean isInitializing, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.ui.screens.camera.SessionState sessionState, int repCount, @org.jetbrains.annotations.Nullable
    java.lang.String exerciseFeedback, int formScore, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.ExerciseState currentExerciseState, boolean isSaving, @org.jetbrains.annotations.Nullable
    java.lang.String saveError, boolean saveSuccess, int cameraSelectorSelected) {
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