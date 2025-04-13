package com.example.ptchampion.domain.exercise;

/**
 * Represents the result of exercise analysis for a single frame.
 *
 * @property repCount Current repetition count.
 * @property feedback Optional feedback message about form or positioning.
 * @property state Current state of the exercise.
 * @property confidence Confidence level of the pose detection (0.0-1.0).
 * @property formScore Quality score for exercise form (0-100).
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0007\n\u0002\b\u0012\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001B5\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u0012\b\b\u0002\u0010\b\u001a\u00020\t\u0012\b\b\u0002\u0010\n\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u000bJ\t\u0010\u0015\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u0016\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\t\u0010\u0017\u001a\u00020\u0007H\u00c6\u0003J\t\u0010\u0018\u001a\u00020\tH\u00c6\u0003J\t\u0010\u0019\u001a\u00020\u0003H\u00c6\u0003J=\u0010\u001a\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u00052\b\b\u0002\u0010\u0006\u001a\u00020\u00072\b\b\u0002\u0010\b\u001a\u00020\t2\b\b\u0002\u0010\n\u001a\u00020\u0003H\u00c6\u0001J\u0013\u0010\u001b\u001a\u00020\u001c2\b\u0010\u001d\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001e\u001a\u00020\u0003H\u00d6\u0001J\t\u0010\u001f\u001a\u00020\u0005H\u00d6\u0001R\u0011\u0010\b\u001a\u00020\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0013\u0010\u0004\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0011\u0010\n\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0011R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014\u00a8\u0006 "}, d2 = {"Lcom/example/ptchampion/domain/exercise/AnalysisResult;", "", "repCount", "", "feedback", "", "state", "Lcom/example/ptchampion/domain/exercise/ExerciseState;", "confidence", "", "formScore", "(ILjava/lang/String;Lcom/example/ptchampion/domain/exercise/ExerciseState;FI)V", "getConfidence", "()F", "getFeedback", "()Ljava/lang/String;", "getFormScore", "()I", "getRepCount", "getState", "()Lcom/example/ptchampion/domain/exercise/ExerciseState;", "component1", "component2", "component3", "component4", "component5", "copy", "equals", "", "other", "hashCode", "toString", "app_debug"})
public final class AnalysisResult {
    private final int repCount = 0;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String feedback = null;
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.domain.exercise.ExerciseState state = null;
    private final float confidence = 0.0F;
    private final int formScore = 0;
    
    public AnalysisResult(int repCount, @org.jetbrains.annotations.Nullable
    java.lang.String feedback, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.ExerciseState state, float confidence, int formScore) {
        super();
    }
    
    public final int getRepCount() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getFeedback() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.domain.exercise.ExerciseState getState() {
        return null;
    }
    
    public final float getConfidence() {
        return 0.0F;
    }
    
    public final int getFormScore() {
        return 0;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.domain.exercise.ExerciseState component3() {
        return null;
    }
    
    public final float component4() {
        return 0.0F;
    }
    
    public final int component5() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.domain.exercise.AnalysisResult copy(int repCount, @org.jetbrains.annotations.Nullable
    java.lang.String feedback, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.exercise.ExerciseState state, float confidence, int formScore) {
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