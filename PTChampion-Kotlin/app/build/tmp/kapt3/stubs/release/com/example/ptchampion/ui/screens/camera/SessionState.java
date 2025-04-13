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

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0006\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006\u00a8\u0006\u0007"}, d2 = {"Lcom/example/ptchampion/ui/screens/camera/SessionState;", "", "(Ljava/lang/String;I)V", "IDLE", "RUNNING", "PAUSED", "STOPPED", "app_release"})
public enum SessionState {
    /*public static final*/ IDLE /* = new IDLE() */,
    /*public static final*/ RUNNING /* = new RUNNING() */,
    /*public static final*/ PAUSED /* = new PAUSED() */,
    /*public static final*/ STOPPED /* = new STOPPED() */;
    
    SessionState() {
    }
    
    @org.jetbrains.annotations.NotNull
    public static kotlin.enums.EnumEntries<com.example.ptchampion.ui.screens.camera.SessionState> getEntries() {
        return null;
    }
}