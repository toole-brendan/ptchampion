package com.example.ptchampion.domain.exercise.analyzers;

import com.example.ptchampion.domain.exercise.AnalysisResult;
import com.example.ptchampion.domain.exercise.ExerciseAnalyzer;
import com.example.ptchampion.domain.exercise.ExerciseState;
import com.example.ptchampion.domain.exercise.utils.AngleCalculator;
import com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark;
import com.example.ptchampion.domain.exercise.utils.PoseLandmark;
import com.example.ptchampion.posedetection.PoseLandmarkerHelper;

/**
 * Concrete implementation of [ExerciseAnalyzer] for pull-ups.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000R\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0007\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010!\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0010\b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u0002\n\u0002\b\u0007\u0018\u00002\u00020\u0001B\u0005\u00a2\u0006\u0002\u0010\u0002J\u0010\u0010\u0011\u001a\u00020\u00122\u0006\u0010\u0013\u001a\u00020\u0014H\u0016J\u0016\u0010\u0015\u001a\u00020\u00162\f\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00190\u0018H\u0002J(\u0010\u001a\u001a\u00020\u00102\u0006\u0010\u001b\u001a\u00020\u00042\u0006\u0010\u001c\u001a\u00020\u00192\u0006\u0010\u001d\u001a\u00020\u00192\u0006\u0010\u001e\u001a\u00020\u0019H\u0002J \u0010\u001f\u001a\u00020 2\u0006\u0010\u001c\u001a\u00020\u00192\u0006\u0010\u001d\u001a\u00020\u00192\u0006\u0010\u001e\u001a\u00020\u0019H\u0002J\u0010\u0010!\u001a\u00020\t2\u0006\u0010\"\u001a\u00020\u0004H\u0002J\u0010\u0010#\u001a\u00020\u00162\u0006\u0010\u0013\u001a\u00020\u0014H\u0016J\b\u0010$\u001a\u00020 H\u0016J\b\u0010%\u001a\u00020 H\u0016J\b\u0010&\u001a\u00020 H\u0016R\u000e\u0010\u0003\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0082D\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\tX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u0014\u0010\n\u001a\b\u0012\u0004\u0012\u00020\f0\u000bX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\r\u001a\u00020\u0004X\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000e\u001a\u00020\tX\u0082\u000e\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u000f\u001a\u00020\u0010X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u00a8\u0006\'"}, d2 = {"Lcom/example/ptchampion/domain/exercise/analyzers/PullupAnalyzer;", "Lcom/example/ptchampion/domain/exercise/ExerciseAnalyzer;", "()V", "CHIN_OVER_BAR_THRESHOLD_Y", "", "FULL_EXTENSION_THRESHOLD", "MIN_BEND_THRESHOLD", "REQUIRED_VISIBILITY", "currentState", "Lcom/example/ptchampion/domain/exercise/ExerciseState;", "formIssues", "", "", "maxElbowAngle", "previousState", "repCount", "", "analyze", "Lcom/example/ptchampion/domain/exercise/AnalysisResult;", "result", "Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "areKeyLandmarksVisible", "", "landmarks", "", "Lcom/example/ptchampion/domain/exercise/utils/MockNormalizedLandmark;", "calculateFormScore", "maxElbowAngleAchieved", "nose", "leftWrist", "rightWrist", "checkChinOverBar", "", "determineState", "elbowAngle", "isValidPose", "reset", "start", "stop", "app_release"})
public final class PullupAnalyzer implements com.example.ptchampion.domain.exercise.ExerciseAnalyzer {
    private int repCount = 0;
    @org.jetbrains.annotations.NotNull
    private com.example.ptchampion.domain.exercise.ExerciseState currentState = com.example.ptchampion.domain.exercise.ExerciseState.IDLE;
    @org.jetbrains.annotations.NotNull
    private com.example.ptchampion.domain.exercise.ExerciseState previousState = com.example.ptchampion.domain.exercise.ExerciseState.IDLE;
    private float maxElbowAngle = 0.0F;
    @org.jetbrains.annotations.NotNull
    private java.util.List<java.lang.String> formIssues;
    private final float FULL_EXTENSION_THRESHOLD = 160.0F;
    private final float MIN_BEND_THRESHOLD = 90.0F;
    private final float CHIN_OVER_BAR_THRESHOLD_Y = 0.05F;
    private final float REQUIRED_VISIBILITY = 0.6F;
    
    public PullupAnalyzer() {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public com.example.ptchampion.domain.exercise.AnalysisResult analyze(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle result) {
        return null;
    }
    
    private final com.example.ptchampion.domain.exercise.ExerciseState determineState(float elbowAngle) {
        return null;
    }
    
    private final void checkChinOverBar(com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark nose, com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark leftWrist, com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark rightWrist) {
    }
    
    private final int calculateFormScore(float maxElbowAngleAchieved, com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark nose, com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark leftWrist, com.example.ptchampion.domain.exercise.utils.MockNormalizedLandmark rightWrist) {
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