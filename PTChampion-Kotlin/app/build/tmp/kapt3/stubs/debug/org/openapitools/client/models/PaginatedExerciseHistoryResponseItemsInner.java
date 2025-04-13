package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * @param id 
 * @param userId 
 * @param exerciseId 
 * @param exerciseName 
 * @param exerciseType 
 * @param grade 
 * @param createdAt 
 * @param reps 
 * @param timeInSeconds 
 * @param distance 
 * @param notes
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000*\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b#\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001B{\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0007\u0012\b\b\u0001\u0010\b\u001a\u00020\u0007\u0012\b\b\u0001\u0010\t\u001a\u00020\u0003\u0012\b\b\u0001\u0010\n\u001a\u00020\u000b\u0012\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u000f\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\u0002\u0010\u0010J\t\u0010!\u001a\u00020\u0003H\u00c6\u0003J\u0010\u0010\"\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u000b\u0010#\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\t\u0010$\u001a\u00020\u0003H\u00c6\u0003J\t\u0010%\u001a\u00020\u0003H\u00c6\u0003J\t\u0010&\u001a\u00020\u0007H\u00c6\u0003J\t\u0010\'\u001a\u00020\u0007H\u00c6\u0003J\t\u0010(\u001a\u00020\u0003H\u00c6\u0003J\t\u0010)\u001a\u00020\u000bH\u00c6\u0003J\u0010\u0010*\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u0010\u0010+\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0014J\u0084\u0001\u0010,\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00032\b\b\u0003\u0010\u0005\u001a\u00020\u00032\b\b\u0003\u0010\u0006\u001a\u00020\u00072\b\b\u0003\u0010\b\u001a\u00020\u00072\b\b\u0003\u0010\t\u001a\u00020\u00032\b\b\u0003\u0010\n\u001a\u00020\u000b2\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u000f\u001a\u0004\u0018\u00010\u0007H\u00c6\u0001\u00a2\u0006\u0002\u0010-J\u0013\u0010.\u001a\u00020/2\b\u00100\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u00101\u001a\u00020\u0003H\u00d6\u0001J\t\u00102\u001a\u00020\u0007H\u00d6\u0001R\u0011\u0010\n\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012R\u0015\u0010\u000e\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u0013\u0010\u0014R\u0011\u0010\u0005\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0019R\u0011\u0010\b\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u0019R\u0011\u0010\t\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0017R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u0017R\u0013\u0010\u000f\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u0019R\u0015\u0010\f\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u001e\u0010\u0014R\u0015\u0010\r\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0015\u001a\u0004\b\u001f\u0010\u0014R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010\u0017\u00a8\u00063"}, d2 = {"Lorg/openapitools/client/models/PaginatedExerciseHistoryResponseItemsInner;", "", "id", "", "userId", "exerciseId", "exerciseName", "", "exerciseType", "grade", "createdAt", "Ljava/time/OffsetDateTime;", "reps", "timeInSeconds", "distance", "notes", "(IIILjava/lang/String;Ljava/lang/String;ILjava/time/OffsetDateTime;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/String;)V", "getCreatedAt", "()Ljava/time/OffsetDateTime;", "getDistance", "()Ljava/lang/Integer;", "Ljava/lang/Integer;", "getExerciseId", "()I", "getExerciseName", "()Ljava/lang/String;", "getExerciseType", "getGrade", "getId", "getNotes", "getReps", "getTimeInSeconds", "getUserId", "component1", "component10", "component11", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "(IIILjava/lang/String;Ljava/lang/String;ILjava/time/OffsetDateTime;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/String;)Lorg/openapitools/client/models/PaginatedExerciseHistoryResponseItemsInner;", "equals", "", "other", "hashCode", "toString", "app_debug"})
public final class PaginatedExerciseHistoryResponseItemsInner {
    private final int id = 0;
    private final int userId = 0;
    private final int exerciseId = 0;
    @org.jetbrains.annotations.NotNull
    private final java.lang.String exerciseName = null;
    @org.jetbrains.annotations.NotNull
    private final java.lang.String exerciseType = null;
    private final int grade = 0;
    @org.jetbrains.annotations.NotNull
    private final java.time.OffsetDateTime createdAt = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer reps = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer timeInSeconds = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer distance = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String notes = null;
    
    public PaginatedExerciseHistoryResponseItemsInner(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "user_id")
    int userId, @com.squareup.moshi.Json(name = "exercise_id")
    int exerciseId, @com.squareup.moshi.Json(name = "exercise_name")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseName, @com.squareup.moshi.Json(name = "exercise_type")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseType, @com.squareup.moshi.Json(name = "grade")
    int grade, @com.squareup.moshi.Json(name = "created_at")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime createdAt, @com.squareup.moshi.Json(name = "reps")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer reps, @com.squareup.moshi.Json(name = "time_in_seconds")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer timeInSeconds, @com.squareup.moshi.Json(name = "distance")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer distance, @com.squareup.moshi.Json(name = "notes")
    @org.jetbrains.annotations.Nullable
    java.lang.String notes) {
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
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getExerciseType() {
        return null;
    }
    
    public final int getGrade() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime getCreatedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getReps() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getTimeInSeconds() {
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
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer component10() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component11() {
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
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String component5() {
        return null;
    }
    
    public final int component6() {
        return 0;
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
    public final org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner copy(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "user_id")
    int userId, @com.squareup.moshi.Json(name = "exercise_id")
    int exerciseId, @com.squareup.moshi.Json(name = "exercise_name")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseName, @com.squareup.moshi.Json(name = "exercise_type")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseType, @com.squareup.moshi.Json(name = "grade")
    int grade, @com.squareup.moshi.Json(name = "created_at")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime createdAt, @com.squareup.moshi.Json(name = "reps")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer reps, @com.squareup.moshi.Json(name = "time_in_seconds")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer timeInSeconds, @com.squareup.moshi.Json(name = "distance")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer distance, @com.squareup.moshi.Json(name = "notes")
    @org.jetbrains.annotations.Nullable
    java.lang.String notes) {
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