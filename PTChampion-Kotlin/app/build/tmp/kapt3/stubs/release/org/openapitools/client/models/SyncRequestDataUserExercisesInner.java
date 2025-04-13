package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * @param userId 
 * @param exerciseId 
 * @param repetitions 
 * @param formScore 
 * @param timeInSeconds 
 * @param grade 
 * @param completed 
 * @param metadata 
 * @param deviceId 
 * @param syncStatus
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000 \n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0002\b\u0006\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0002\b$\b\u0086\b\u0018\u00002\u00020\u0001By\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0003\u0012\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\n\u0012\n\b\u0003\u0010\u000b\u001a\u0004\u0018\u00010\f\u0012\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\f\u0012\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\f\u00a2\u0006\u0002\u0010\u000fJ\t\u0010 \u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010!\u001a\u0004\u0018\u00010\fH\u00c6\u0003J\t\u0010\"\u001a\u00020\u0003H\u00c6\u0003J\u0010\u0010#\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0018J\u0010\u0010$\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0018J\u0010\u0010%\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0018J\u0010\u0010&\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u0018J\u0010\u0010\'\u001a\u0004\u0018\u00010\nH\u00c6\u0003\u00a2\u0006\u0002\u0010\u0011J\u000b\u0010(\u001a\u0004\u0018\u00010\fH\u00c6\u0003J\u000b\u0010)\u001a\u0004\u0018\u00010\fH\u00c6\u0003J\u0082\u0001\u0010*\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\n2\n\b\u0003\u0010\u000b\u001a\u0004\u0018\u00010\f2\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\f2\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\fH\u00c6\u0001\u00a2\u0006\u0002\u0010+J\u0013\u0010,\u001a\u00020\n2\b\u0010-\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010.\u001a\u00020\u0003H\u00d6\u0001J\t\u0010/\u001a\u00020\fH\u00d6\u0001R\u0015\u0010\t\u001a\u0004\u0018\u00010\n\u00a2\u0006\n\n\u0002\u0010\u0012\u001a\u0004\b\u0010\u0010\u0011R\u0013\u0010\r\u001a\u0004\u0018\u00010\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0016R\u0015\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0019\u001a\u0004\b\u0017\u0010\u0018R\u0015\u0010\b\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0019\u001a\u0004\b\u001a\u0010\u0018R\u0013\u0010\u000b\u001a\u0004\u0018\u00010\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0014R\u0015\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0019\u001a\u0004\b\u001c\u0010\u0018R\u0013\u0010\u000e\u001a\u0004\u0018\u00010\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001d\u0010\u0014R\u0015\u0010\u0007\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u0019\u001a\u0004\b\u001e\u0010\u0018R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010\u0016\u00a8\u00060"}, d2 = {"Lorg/openapitools/client/models/SyncRequestDataUserExercisesInner;", "", "userId", "", "exerciseId", "repetitions", "formScore", "timeInSeconds", "grade", "completed", "", "metadata", "", "deviceId", "syncStatus", "(IILjava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Boolean;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", "getCompleted", "()Ljava/lang/Boolean;", "Ljava/lang/Boolean;", "getDeviceId", "()Ljava/lang/String;", "getExerciseId", "()I", "getFormScore", "()Ljava/lang/Integer;", "Ljava/lang/Integer;", "getGrade", "getMetadata", "getRepetitions", "getSyncStatus", "getTimeInSeconds", "getUserId", "component1", "component10", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "(IILjava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Boolean;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Lorg/openapitools/client/models/SyncRequestDataUserExercisesInner;", "equals", "other", "hashCode", "toString", "app_release"})
public final class SyncRequestDataUserExercisesInner {
    private final int userId = 0;
    private final int exerciseId = 0;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer repetitions = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer formScore = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer timeInSeconds = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Integer grade = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.Boolean completed = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String metadata = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String deviceId = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String syncStatus = null;
    
    public SyncRequestDataUserExercisesInner(@com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "exerciseId")
    int exerciseId, @com.squareup.moshi.Json(name = "repetitions")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer repetitions, @com.squareup.moshi.Json(name = "formScore")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer formScore, @com.squareup.moshi.Json(name = "timeInSeconds")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer timeInSeconds, @com.squareup.moshi.Json(name = "grade")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer grade, @com.squareup.moshi.Json(name = "completed")
    @org.jetbrains.annotations.Nullable
    java.lang.Boolean completed, @com.squareup.moshi.Json(name = "metadata")
    @org.jetbrains.annotations.Nullable
    java.lang.String metadata, @com.squareup.moshi.Json(name = "deviceId")
    @org.jetbrains.annotations.Nullable
    java.lang.String deviceId, @com.squareup.moshi.Json(name = "syncStatus")
    @org.jetbrains.annotations.Nullable
    java.lang.String syncStatus) {
        super();
    }
    
    public final int getUserId() {
        return 0;
    }
    
    public final int getExerciseId() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getRepetitions() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getFormScore() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getTimeInSeconds() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Integer getGrade() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.Boolean getCompleted() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getMetadata() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getDeviceId() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getSyncStatus() {
        return null;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component10() {
        return null;
    }
    
    public final int component2() {
        return 0;
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
    public final java.lang.Integer component5() {
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
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component9() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.SyncRequestDataUserExercisesInner copy(@com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "exerciseId")
    int exerciseId, @com.squareup.moshi.Json(name = "repetitions")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer repetitions, @com.squareup.moshi.Json(name = "formScore")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer formScore, @com.squareup.moshi.Json(name = "timeInSeconds")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer timeInSeconds, @com.squareup.moshi.Json(name = "grade")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer grade, @com.squareup.moshi.Json(name = "completed")
    @org.jetbrains.annotations.Nullable
    java.lang.Boolean completed, @com.squareup.moshi.Json(name = "metadata")
    @org.jetbrains.annotations.Nullable
    java.lang.String metadata, @com.squareup.moshi.Json(name = "deviceId")
    @org.jetbrains.annotations.Nullable
    java.lang.String deviceId, @com.squareup.moshi.Json(name = "syncStatus")
    @org.jetbrains.annotations.Nullable
    java.lang.String syncStatus) {
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