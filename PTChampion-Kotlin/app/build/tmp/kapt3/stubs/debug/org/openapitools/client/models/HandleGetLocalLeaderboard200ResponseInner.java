package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * @param userId 
 * @param username 
 * @param exerciseId 
 * @param score 
 * @param displayName
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000 \n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0012\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001B9\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0007\u001a\u00020\u0003\u0012\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\u0002\u0010\tJ\t\u0010\u0011\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0012\u001a\u00020\u0005H\u00c6\u0003J\t\u0010\u0013\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0014\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u0015\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J=\u0010\u0016\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00052\b\b\u0003\u0010\u0006\u001a\u00020\u00032\b\b\u0003\u0010\u0007\u001a\u00020\u00032\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\u0005H\u00c6\u0001J\u0013\u0010\u0017\u001a\u00020\u00182\b\u0010\u0019\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001a\u001a\u00020\u0003H\u00d6\u0001J\t\u0010\u001b\u001a\u00020\u0005H\u00d6\u0001R\u0013\u0010\b\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000bR\u0011\u0010\u0006\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0011\u0010\u0007\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\rR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\rR\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u000b\u00a8\u0006\u001c"}, d2 = {"Lorg/openapitools/client/models/HandleGetLocalLeaderboard200ResponseInner;", "", "userId", "", "username", "", "exerciseId", "score", "displayName", "(ILjava/lang/String;IILjava/lang/String;)V", "getDisplayName", "()Ljava/lang/String;", "getExerciseId", "()I", "getScore", "getUserId", "getUsername", "component1", "component2", "component3", "component4", "component5", "copy", "equals", "", "other", "hashCode", "toString", "app_debug"})
public final class HandleGetLocalLeaderboard200ResponseInner {
    private final int userId = 0;
    @org.jetbrains.annotations.NotNull
    private final java.lang.String username = null;
    private final int exerciseId = 0;
    private final int score = 0;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String displayName = null;
    
    public HandleGetLocalLeaderboard200ResponseInner(@com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "username")
    @org.jetbrains.annotations.NotNull
    java.lang.String username, @com.squareup.moshi.Json(name = "exerciseId")
    int exerciseId, @com.squareup.moshi.Json(name = "score")
    int score, @com.squareup.moshi.Json(name = "displayName")
    @org.jetbrains.annotations.Nullable
    java.lang.String displayName) {
        super();
    }
    
    public final int getUserId() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getUsername() {
        return null;
    }
    
    public final int getExerciseId() {
        return 0;
    }
    
    public final int getScore() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getDisplayName() {
        return null;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String component2() {
        return null;
    }
    
    public final int component3() {
        return 0;
    }
    
    public final int component4() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.HandleGetLocalLeaderboard200ResponseInner copy(@com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "username")
    @org.jetbrains.annotations.NotNull
    java.lang.String username, @com.squareup.moshi.Json(name = "exerciseId")
    int exerciseId, @com.squareup.moshi.Json(name = "score")
    int score, @com.squareup.moshi.Json(name = "displayName")
    @org.jetbrains.annotations.Nullable
    java.lang.String displayName) {
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