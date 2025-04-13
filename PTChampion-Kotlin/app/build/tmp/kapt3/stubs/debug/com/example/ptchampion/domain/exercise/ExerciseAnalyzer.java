package com.example.ptchampion.domain.exercise;

import com.example.ptchampion.posedetection.PoseLandmarkerHelper;

/**
 * Base interface for analyzing exercises based on pose landmark results.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000$\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\bf\u0018\u00002\u00020\u0001J\u0010\u0010\u0002\u001a\u00020\u00032\u0006\u0010\u0004\u001a\u00020\u0005H&J\u0010\u0010\u0006\u001a\u00020\u00072\u0006\u0010\u0004\u001a\u00020\u0005H&J\b\u0010\b\u001a\u00020\tH&J\b\u0010\n\u001a\u00020\tH&J\b\u0010\u000b\u001a\u00020\tH&\u00a8\u0006\f"}, d2 = {"Lcom/example/ptchampion/domain/exercise/ExerciseAnalyzer;", "", "analyze", "Lcom/example/ptchampion/domain/exercise/AnalysisResult;", "result", "Lcom/example/ptchampion/posedetection/PoseLandmarkerHelper$ResultBundle;", "isValidPose", "", "reset", "", "start", "stop", "app_debug"})
public abstract interface ExerciseAnalyzer {
    
    /**
     * Analyzes a single frame of pose landmark data.
     *
     * @param result The pose landmark data bundle for the current frame.
     * @return An [AnalysisResult] containing rep count, feedback, and state.
     */
    @org.jetbrains.annotations.NotNull
    public abstract com.example.ptchampion.domain.exercise.AnalysisResult analyze(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle result);
    
    /**
     * Checks if the detected pose is valid for starting the exercise analysis.
     *
     * @param result The pose landmark data bundle.
     * @return True if the pose is valid, false otherwise.
     */
    public abstract boolean isValidPose(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.posedetection.PoseLandmarkerHelper.ResultBundle result);
    
    /**
     * Starts the exercise analysis session, resetting any internal state.
     */
    public abstract void start();
    
    /**
     * Stops the exercise analysis session.
     */
    public abstract void stop();
    
    /**
     * Resets the analyzer's state (e.g., rep count).
     */
    public abstract void reset();
}