package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * A single recorded workout session
 *
 * @param id 
 * @param userId 
 * @param exerciseId 
 * @param exerciseName 
 * @param grade 
 * @param createdAt 
 * @param completedAt 
 * @param repetitions 
 * @param durationSeconds 
 * @param formScore
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000*\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b!\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001Bo\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0007\u0012\b\b\u0001\u0010\b\u001a\u00020\u0003\u0012\b\b\u0001\u0010\t\u001a\u00020\n\u0012\b\b\u0001\u0010\u000b\u001a\u00020\n\u0012\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\u0002\u0010\u000fJ\t\u0010\u001f\u001a\u00020\u0003H\u00c6\u0003J\u0010\u0010 \u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\t\u0010!\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\"\u001a\u00020\u0003H\u00c6\u0003J\t\u0010#\u001a\u00020\u0007H\u00c6\u0003J\t\u0010$\u001a\u00020\u0003H\u00c6\u0003J\t\u0010%\u001a\u00020\nH\u00c6\u0003J\t\u0010&\u001a\u00020\nH\u00c6\u0003J\u0010\u0010\'\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u0010\u0010(\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014Jx\u0010)\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00032\b\b\u0003\u0010\u0005\u001a\u00020\u00032\b\b\u0003\u0010\u0006\u001a\u00020\u00072\b\b\u0003\u0010\b\u001a\u00020\u00032\b\b\u0003\u0010\t\u001a\u00020\n2\b\b\u0003\u0010\u000b\u001a\u00020\n2\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\u0003H\u00c6\u0001\u00a2\u0006\u0002\u0010*J\u0013\u0010+\u001a\u00020,2\b\u0010-\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010.\u001a\u00020\u0003H\u00d6\u0001J\t\u0010/\u001a\u00020\u0007H\u00d6\u0001R\u0011\u0010\u000b\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\t\u001a\u00020\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0011R\u0015\u0010\r\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u0013\u0010\u0014R\u0011\u0010\u0005\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019R\u0015\u0010\u000e\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u001a\u0010\u0014R\u0011\u0010\b\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0017R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u0017R\u0015\u0010\f\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u001d\u0010\u0014R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001e\u0010\u0017\u00a8\u00060"}, d2 = {"Lorg/openapitools/client/models/WorkoutResponse;", "", "id", "", "userId", "exerciseId", "exerciseName", "", "grade", "createdAt", "Ljava/time/OffsetDateTime;", "completedAt", "repetitions", "durationSeconds", "formScore", "(IIILjava/lang/String;ILjava/time/OffsetDateTime;Ljava/time/OffsetDateTime;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;)V", "getCompletedAt", "()Ljava/time/OffsetDateTime;", "getCreatedAt", "getDurationSeconds", "()Ljava/lang/Integer;", "Ljava/lang/Integer;", "getExerciseId", "()I", "getExerciseName", "()Ljava/lang/String;", "getFormScore", "getGrade", "getId", "getRepetitions", "getUserId", "component1", "component10", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "(IIILjava/lang/String;ILjava/time/OffsetDateTime;Ljava/time/OffsetDateTime;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;)Lorg/openapitools/client/models/WorkoutResponse;", "equals", "", "other", "hashCode", "toString", "app_release"})
public final class WorkoutResponse {
    private final int id = 0;
    private final int userId = 0;
    private final int exerciseId = 0;
    @org.jetbrains.annotations.NotNull
    private final java.lang.String exerciseName = null;
    private final int grade = 0;
    @org.jetbrains.annotations.NotNull
    private final java.time.OffsetDateTime createdAt = null;
    @org.jetbrains.annotations.NotNull
    private final java.time.OffsetDateTime completedAt = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer repetitions = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer durationSeconds = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer formScore = null;
    
    public WorkoutResponse(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "exerciseId")
    int exerciseId, @com.squareup.moshi.Json(name = "exerciseName")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseName, @com.squareup.moshi.Json(name = "grade")
    int grade, @com.squareup.moshi.Json(name = "createdAt")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime createdAt, @com.squareup.moshi.Json(name = "completedAt")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime completedAt, @com.squareup.moshi.Json(name = "repetitions")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer repetitions, @com.squareup.moshi.Json(name = "durationSeconds")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer durationSeconds, @com.squareup.moshi.Json(name = "formScore")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer formScore) {
        super();
    }
    
    public final int getId() {
        return 0;
    }
    
    public final int getUserId() {
        return 0;
    }
    
    public final int getExerciseId() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getExerciseName() {
        return null;
    }
    
    public final int getGrade() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime getCreatedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime getCompletedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getRepetitions() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getDurationSeconds() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getFormScore() {
        return null;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component10() {
        return null;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final int component3() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String component4() {
        return null;
    }
    
    public final int component5() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime component7() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component8() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component9() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.WorkoutResponse copy(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "exerciseId")
    int exerciseId, @com.squareup.moshi.Json(name = "exerciseName")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseName, @com.squareup.moshi.Json(name = "grade")
    int grade, @com.squareup.moshi.Json(name = "createdAt")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime createdAt, @com.squareup.moshi.Json(name = "completedAt")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime completedAt, @com.squareup.moshi.Json(name = "repetitions")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer repetitions, @com.squareup.moshi.Json(name = "durationSeconds")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer durationSeconds, @com.squareup.moshi.Json(name = "formScore")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer formScore) {
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