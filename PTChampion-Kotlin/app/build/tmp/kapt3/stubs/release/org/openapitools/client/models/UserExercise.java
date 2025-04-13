package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Details of a completed or tracked exercise
 *
 * @param id 
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
 * @param createdAt 
 * @param updatedAt
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0002\b\u0007\n\u0002\u0010\u000b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b+\b\u0086\b\u0018\u00002\u00020\u0001:\u0001:B\u0099\u0001\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0003\u0012\n\b\u0001\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0001\u0010\u0007\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0001\u0010\b\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0001\u0010\t\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0001\u0010\n\u001a\u00020\u000b\u0012\n\b\u0001\u0010\f\u001a\u0004\u0018\u00010\r\u0012\n\b\u0001\u0010\u000e\u001a\u0004\u0018\u00010\r\u0012\n\b\u0001\u0010\u000f\u001a\u0004\u0018\u00010\u0010\u0012\n\b\u0001\u0010\u0011\u001a\u0004\u0018\u00010\r\u0012\n\b\u0001\u0010\u0012\u001a\u0004\u0018\u00010\r\u00a2\u0006\u0002\u0010\u0013J\t\u0010\'\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010(\u001a\u0004\u0018\u00010\rH\u00c6\u0003J\u000b\u0010)\u001a\u0004\u0018\u00010\u0010H\u00c6\u0003J\u000b\u0010*\u001a\u0004\u0018\u00010\rH\u00c6\u0003J\u000b\u0010+\u001a\u0004\u0018\u00010\rH\u00c6\u0003J\t\u0010,\u001a\u00020\u0003H\u00c6\u0003J\t\u0010-\u001a\u00020\u0003H\u00c6\u0003J\u0010\u0010.\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u001cJ\u0010\u0010/\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u001cJ\u0010\u00100\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u001cJ\u0010\u00101\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003\u00a2\u0006\u0002\u0010\u001cJ\t\u00102\u001a\u00020\u000bH\u00c6\u0003J\u000b\u00103\u001a\u0004\u0018\u00010\rH\u00c6\u0003J\u00a2\u0001\u00104\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00032\b\b\u0003\u0010\u0005\u001a\u00020\u00032\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\u00032\b\b\u0003\u0010\n\u001a\u00020\u000b2\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\r2\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\r2\n\b\u0003\u0010\u000f\u001a\u0004\u0018\u00010\u00102\n\b\u0003\u0010\u0011\u001a\u0004\u0018\u00010\r2\n\b\u0003\u0010\u0012\u001a\u0004\u0018\u00010\rH\u00c6\u0001\u00a2\u0006\u0002\u00105J\u0013\u00106\u001a\u00020\u000b2\b\u00107\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u00108\u001a\u00020\u0003H\u00d6\u0001J\t\u00109\u001a\u00020\rH\u00d6\u0001R\u0011\u0010\n\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u0013\u0010\u0011\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0017R\u0013\u0010\u000e\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0017R\u0011\u0010\u0005\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u001aR\u0015\u0010\u0007\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u001d\u001a\u0004\b\u001b\u0010\u001cR\u0015\u0010\t\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u001d\u001a\u0004\b\u001e\u0010\u001cR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010\u001aR\u0013\u0010\f\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010\u0017R\u0015\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u001d\u001a\u0004\b!\u0010\u001cR\u0013\u0010\u000f\u001a\u0004\u0018\u00010\u0010\u00a2\u0006\b\n\u0000\u001a\u0004\b\"\u0010#R\u0015\u0010\b\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\n\n\u0002\u0010\u001d\u001a\u0004\b$\u0010\u001cR\u0013\u0010\u0012\u001a\u0004\u0018\u00010\r\u00a2\u0006\b\n\u0000\u001a\u0004\b%\u0010\u0017R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b&\u0010\u001a\u00a8\u0006;"}, d2 = {"Lorg/openapitools/client/models/UserExercise;", "", "id", "", "userId", "exerciseId", "repetitions", "formScore", "timeInSeconds", "grade", "completed", "", "metadata", "", "deviceId", "syncStatus", "Lorg/openapitools/client/models/UserExercise$SyncStatus;", "createdAt", "updatedAt", "(IIILjava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;ZLjava/lang/String;Ljava/lang/String;Lorg/openapitools/client/models/UserExercise$SyncStatus;Ljava/lang/String;Ljava/lang/String;)V", "getCompleted", "()Z", "getCreatedAt", "()Ljava/lang/String;", "getDeviceId", "getExerciseId", "()I", "getFormScore", "()Ljava/lang/Integer;", "Ljava/lang/Integer;", "getGrade", "getId", "getMetadata", "getRepetitions", "getSyncStatus", "()Lorg/openapitools/client/models/UserExercise$SyncStatus;", "getTimeInSeconds", "getUpdatedAt", "getUserId", "component1", "component10", "component11", "component12", "component13", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "(IIILjava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;Ljava/lang/Integer;ZLjava/lang/String;Ljava/lang/String;Lorg/openapitools/client/models/UserExercise$SyncStatus;Ljava/lang/String;Ljava/lang/String;)Lorg/openapitools/client/models/UserExercise;", "equals", "other", "hashCode", "toString", "SyncStatus", "app_release"})
public final class UserExercise {
    private final int id = 0;
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
    private final boolean completed = false;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String metadata = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String deviceId = null;
    @org.jetbrains.annotations.Nullable
    private final org.openapitools.client.models.UserExercise.SyncStatus syncStatus = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String createdAt = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String updatedAt = null;
    
    public UserExercise(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "userId")
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
    boolean completed, @com.squareup.moshi.Json(name = "metadata")
    @org.jetbrains.annotations.Nullable
    java.lang.String metadata, @com.squareup.moshi.Json(name = "deviceId")
    @org.jetbrains.annotations.Nullable
    java.lang.String deviceId, @com.squareup.moshi.Json(name = "syncStatus")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.UserExercise.SyncStatus syncStatus, @com.squareup.moshi.Json(name = "createdAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String createdAt, @com.squareup.moshi.Json(name = "updatedAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String updatedAt) {
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
    
    public final boolean getCompleted() {
        return false;
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
    public final org.openapitools.client.models.UserExercise.SyncStatus getSyncStatus() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getCreatedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getUpdatedAt() {
        return null;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component10() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.UserExercise.SyncStatus component11() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component12() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component13() {
        return null;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final int component3() {
        return 0;
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
    public final java.lang.Integer component7() {
        return null;
    }
    
    public final boolean component8() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component9() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.UserExercise copy(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "userId")
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
    boolean completed, @com.squareup.moshi.Json(name = "metadata")
    @org.jetbrains.annotations.Nullable
    java.lang.String metadata, @com.squareup.moshi.Json(name = "deviceId")
    @org.jetbrains.annotations.Nullable
    java.lang.String deviceId, @com.squareup.moshi.Json(name = "syncStatus")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.UserExercise.SyncStatus syncStatus, @com.squareup.moshi.Json(name = "createdAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String createdAt, @com.squareup.moshi.Json(name = "updatedAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String updatedAt) {
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
    
    /**
     * Values: synced,pending,conflict
     */
    @com.squareup.moshi.JsonClass(generateAdapter = false)
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0007\b\u0087\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u000f\b\u0002\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006j\u0002\b\u0007j\u0002\b\bj\u0002\b\t\u00a8\u0006\n"}, d2 = {"Lorg/openapitools/client/models/UserExercise$SyncStatus;", "", "value", "", "(Ljava/lang/String;ILjava/lang/String;)V", "getValue", "()Ljava/lang/String;", "synced", "pending", "conflict", "app_release"})
    public static enum SyncStatus {
        @com.squareup.moshi.Json(name = "synced")
        /*public static final*/ synced /* = new synced(null) */,
        @com.squareup.moshi.Json(name = "pending")
        /*public static final*/ pending /* = new pending(null) */,
        @com.squareup.moshi.Json(name = "conflict")
        /*public static final*/ conflict /* = new conflict(null) */;
        @org.jetbrains.annotations.NotNull
        private final java.lang.String value = null;
        
        SyncStatus(java.lang.String value) {
        }
        
        @org.jetbrains.annotations.NotNull
        public final java.lang.String getValue() {
            return null;
        }
        
        @org.jetbrains.annotations.NotNull
        public static kotlin.enums.EnumEntries<org.openapitools.client.models.UserExercise.SyncStatus> getEntries() {
            return null;
        }
    }
}