package com.example.ptchampion.domain.exercise.analyzers;

import com.example.ptchampion.domain.exercise.AnalysisResult;
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer;
import com.example.ptchampion.domain.exercise.ExerciseState;
import com.example.ptchampion.domain.exercise.utils.AngleCalculator;
import com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark;
import com.example.ptchampion.domain.exercise.utils.PoseLandmark;
import com.example.ptchampion.posedetection.PoseLandmarkerHelper;

/**
 * Concrete implementation of [ExerciseAnalyzer] for sit-ups.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000R\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0007\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010!\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0002\b\t\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0012\u001a\u00020\u00132\u0006\u0010\u0014\u001a\u00020\u0015H\u0016J\u0016\u0010\u0016\u001a\u00020\u00172\f\u0010\u0018\u001a\b\u0012\u0004\u0012\u00020\u001a0\u0019H\u0002J\u0010\u0010\u001b\u001a\u00020\u00112\u0006\u0010\u001c\u001a\u00020\u0004H\u0002J\u0018\u0010\u001d\u001a\u00020\u001e2\u0006\u0010\u001f\u001a\u00020\u001a2\u0006\u0010 \u001a\u00020\u001aH\u0002J\u0010\u0010!\u001a\u00020\t2\u0006\u0010\"\u001a\u00020\u0004H\u0002J\u0010\u0010#\u001a\u00020\u00172\u0006\u0010\u0014\u001a\u00020\u0015H\u0016J\b\u0010$\u001a\u00020\u001eH\u0016J\b\u0010%\u001a\u00020\u001eH\u0016J\b\u0010&\u001a\u00020\u001eH\u0016R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\tX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\n\u001a\b\u0012\u0004\u0012\u00020\f0\u000bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000f\u001a\u00020\tX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0010\u001a\u00020\u0011X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\'"}, d2 = {"Lcom/example/ptchampion/domain/exercise/analyzers/SitupAnalyzer;", "Lcom/example/ptchampion/domain/exercise/ExerciseAnalyzer;", "()V", "HIP_ANGLE_DOWN_THRESHOLD", "", "HIP_ANGLE_UP_THRESHOLD", "REQUIRED_VISIBILITY", "SHOULDER_ALIGNED_THRESHOLD", "currentState", "Lcom/example/ptchampion/domain/exercise/ExerciseState;", "formIssues", "", "", "maxHipAngle", "minShoulderWristDist", "previousState", "repCount", "", "analyze", "Lcom/example/ptchampion/domain/exercise/AnalysisResult;", "result", "Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "areKeyLandmarksVisible", "", "landmarks", "", "Lcom/example/ptchampion/domain/exercise/utils/MockNormalizedLandmark;", "calculateFormScore", "maxHipAngleAchieved", "checkShoulderAlignment", "", "leftShoulder", "rightShoulder", "determineState", "hipAngle", "isValidPose", "reset", "start", "stop", "app_debug"})
public final class SitupAnalyzer implements com.example.ptchampion.domain.exercise.ExerciseAnalyzer {
    private int repCount = 0;
    @org.jetbrains.annotations.NotNull
    private com.example.ptchampion.domain.exercise.ExerciseState currentState = com.example.ptchampion.domain.exercise.ExerciseState.IDLE;
    @org.jetbrains.annotations.NotNull
    private com.example.ptchampion.domain.exercise.ExerciseState previousState = com.example.ptchampion.domain.exercise.ExerciseState.IDLE;
    private float maxHipAngle = 0.0F;
    private float minShoulderWristDist = 3.4028235E38F;
    @org.jetbrains.annotations.NotNull
    private java.util.List<java.lang.String> formIssues;
    private final float HIP_ANGLE_DOWN_THRESHOLD = 110.0F;
    private final float HIP_ANGLE_UP_THRESHOLD = 70.0F;
    private final float SHOULDER_ALIGNED_THRESHOLD = 0.15F;
    private final float REQUIRED_VISIBILITY = 0.5F;
    
    public SitupAnalyzer() {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public com.example.ptchampion.domain.exercise.AnalysisResult analyze(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle result) {
        return null;
    }
    
    private final com.example.ptchampion.domain.exercise.ExerciseState determineState(float hipAngle) {
        return null;
    }
    
    private final void checkShoulderAlignment(com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark leftShoulder, com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark rightShoulder) {
    }
    
    private final int calculateFormScore(float maxHipAngleAchieved) {
        return 0;
    }
    
    private final boolean areKeyLandmarksVisible(java.util.List<com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark> landmarks) {
        return false;
    }
    
    @java.lang.Override
    public boolean isValidPose(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle result) {
        return false;
    }
    
    @java.lang.Override
    public void start() {
    }
    
    @java.lang.Override
    public void stop() {
    }
    
    @java.lang.Override
    public void reset() {
    }
}