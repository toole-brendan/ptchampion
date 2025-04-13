package com.example.ptchampion.domain.model;

import java.time.Instant;

/**
 * Domain model representing a workout session
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0010\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B+\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\b\u0010\u0004\u001a\u0004\u0018\u00010\u0003\u0012\b\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\t\u0010\u0011\u001a\u00020\u0003H\u00c6\u0003J\u0010\u0010\u0012\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\fJ\u0010\u0010\u0013\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\fJ\t\u0010\u0014\u001a\u00020\u0007H\u00c6\u0003J:\u0010\u0015\u001a\u00020\u00002\b\b\u0002\u0010\u0002\u001a\u00020\u00032\n\b\u0002\u0010\u0004\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0006\u001a\u00020\u0007H\u00c6\u0001\u00a2\u0006\u0002\u0010\u0016J\u0013\u0010\u0017\u001a\u00020\u00182\b\u0010\u0019\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001a\u001a\u00020\u0003H\u00d6\u0001J\t\u0010\u001b\u001a\u00020\u001cH\u00d6\u0001R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\nR\u0015\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\r\u001a\u0004\b\u000b\u0010\fR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0015\u0010\u0004\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\r\u001a\u0004\b\u0010\u0010\f\u00a8\u0006\u001d"}, d2 = {"Lcom/example/ptchampion/domain/model/WorkoutSession;", "", "exerciseId", "", "repetitions", "durationSeconds", "completedAt", "Ljava/time/Instant;", "(ILjava/lang/Integer;Ljava/lang/Integer;Ljava/time/Instant;)V", "getCompletedAt", "()Ljava/time/Instant;", "getDurationSeconds", "()Ljava/lang/Integer;", "Ljava/lang/Integer;", "getExerciseId", "()I", "getRepetitions", "component1", "component2", "component3", "component4", "copy", "(ILjava/lang/Integer;Ljava/lang/Integer;Ljava/time/Instant;)Lcom/example/ptchampion/domain/model/WorkoutSession;", "equals", "", "other", "hashCode", "toString", "", "app_debug"})
public final class WorkoutSession {
    private final int exerciseId = 0;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer repetitions = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer durationSeconds = null;
    @org.jetbrains.annotations.NotNull
    private final java.time.Instant completedAt = null;
    
    public WorkoutSession(int exerciseId, @org.jetbrains.annotations.Nullable
    java.lang.Integer repetitions, @org.jetbrains.annotations.Nullable
    java.lang.Integer durationSeconds, @org.jetbrains.annotations.NotNull
    java.time.Instant completedAt) {
        super();
    }
    
    public final int getExerciseId() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getRepetitions() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getDurationSeconds() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.Instant getCompletedAt() {
        return null;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component3() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.Instant component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final com.example.ptchampion.domain.model.WorkoutSession copy(int exerciseId, @org.jetbrains.annotations.Nullable
    java.lang.Integer repetitions, @org.jetbrains.annotations.Nullable
    java.lang.Integer durationSeconds, @org.jetbrains.annotations.NotNull
    java.time.Instant completedAt) {
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