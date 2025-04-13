package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Exercise data to log
 *
 * @param exerciseId 
 * @param reps 
 * @param duration 
 * @param distance 
 * @param notes 
 * @param formScore Optional score (0-100) from client-side form analysis
 * @param completed Whether the exercise was fully completed
 * @param deviceId Optional identifier of the device used for logging
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\"\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0002\b\u0004\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0002\b\u001f\b\u0086\b\u0018\u00002\u00020\u0001Bc\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\n\b\u0003\u0010\u0004\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\b\u0012\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\n\u001a\u0004\u0018\u00010\u000b\u0012\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\b\u00a2\u0006\u0002\u0010\rJ\t\u0010\u001c\u001a\u00020\u0003H\u00c6\u0003J\u0010\u0010\u001d\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u0010\u0010\u001e\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u0010\u0010\u001f\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u000b\u0010 \u001a\u0004\u0018\u00010\bH\u00c6\u0003J\u0010\u0010!\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u0010\u0010\"\u001a\u0004\u0018\u00010\u000bH\u00c6\u0003\u00a2\u0006\u0002\u0010\u000fJ\u000b\u0010#\u001a\u0004\u0018\u00010\bH\u00c6\u0003Jl\u0010$\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\n\b\u0003\u0010\u0004\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\b2\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\n\u001a\u0004\u0018\u00010\u000b2\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\bH\u00c6\u0001\u00a2\u0006\u0002\u0010%J\u0013\u0010&\u001a\u00020\u000b2\b\u0010\'\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010(\u001a\u00020\u0003H\u00d6\u0001J\t\u0010)\u001a\u00020\bH\u00d6\u0001R\u0015\u0010\n\u001a\u0004\u0018\u00010\u000b\u00a2\u0006\n\n\u0002\u0010\u0010\u001a\u0004\b\u000e\u0010\u000fR\u0013\u0010\f\u001a\u0004\u0018\u00010\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012R\u0015\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u0013\u0010\u0014R\u0015\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u0016\u0010\u0014R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0018R\u0015\u0010\t\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u0019\u0010\u0014R\u0013\u0010\u0007\u001a\u0004\u0018\u00010\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u0012R\u0015\u0010\u0004\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u001b\u0010\u0014\u00a8\u0006*"}, d2 = {"Lorg/openapitools/client/models/LogExerciseRequest;", "", "exerciseId", "", "reps", "duration", "distance", "notes", "", "formScore", "completed", "", "deviceId", "(ILjava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/String;Ljava/lang/Integer;Ljava/lang/Boolean;Ljava/lang/String;)V", "getCompleted", "()Ljava/lang/Boolean;", "Ljava/lang/Boolean;", "getDeviceId", "()Ljava/lang/String;", "getDistance", "()Ljava/lang/Integer;", "Ljava/lang/Integer;", "getDuration", "getExerciseId", "()I", "getFormScore", "getNotes", "getReps", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "copy", "(ILjava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/String;Ljava/lang/Integer;Ljava/lang/Boolean;Ljava/lang/String;)Lorg/openapitools/client/models/LogExerciseRequest;", "equals", "other", "hashCode", "toString", "app_release"})
public final class LogExerciseRequest {
    private final int exerciseId = 0;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer reps = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer duration = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer distance = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String notes = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer formScore = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Boolean completed = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String deviceId = null;
    
    public LogExerciseRequest(@com.squareup.moshi.Json(name = "exercise_id")
    int exerciseId, @com.squareup.moshi.Json(name = "reps")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer reps, @com.squareup.moshi.Json(name = "duration")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer duration, @com.squareup.moshi.Json(name = "distance")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer distance, @com.squareup.moshi.Json(name = "notes")
    @org.jetbrains.annotations.Nullable
    java.lang.String notes, @com.squareup.moshi.Json(name = "form_score")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer formScore, @com.squareup.moshi.Json(name = "completed")
    @org.jetbrains.annotations.Nullable
    java.lang.Boolean completed, @com.squareup.moshi.Json(name = "device_id")
    @org.jetbrains.annotations.Nullable
    java.lang.String deviceId) {
        super();
    }
    
    public final int getExerciseId() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getReps() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getDuration() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getDistance() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getNotes() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getFormScore() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Boolean getCompleted() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getDeviceId() {
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
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component4() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component6() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Boolean component7() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component8() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.LogExerciseRequest copy(@com.squareup.moshi.Json(name = "exercise_id")
    int exerciseId, @com.squareup.moshi.Json(name = "reps")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer reps, @com.squareup.moshi.Json(name = "duration")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer duration, @com.squareup.moshi.Json(name = "distance")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer distance, @com.squareup.moshi.Json(name = "notes")
    @org.jetbrains.annotations.Nullable
    java.lang.String notes, @com.squareup.moshi.Json(name = "form_score")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer formScore, @com.squareup.moshi.Json(name = "completed")
    @org.jetbrains.annotations.Nullable
    java.lang.Boolean completed, @com.squareup.moshi.Json(name = "device_id")
    @org.jetbrains.annotations.Nullable
    java.lang.String deviceId) {
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