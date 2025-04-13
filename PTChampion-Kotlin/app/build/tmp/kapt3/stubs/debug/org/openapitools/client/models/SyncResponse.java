package org.openapitools.client.models;

import org.openapitools.client.models.SyncResponseData;
import org.openapitools.client.models.UserExercise;
import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Response payload after data synchronization
 *
 * @param success 
 * @param timestamp 
 * @param `data` 
 * @param conflicts
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00004\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0011\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B7\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0005\u0012\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u0012\u0010\b\u0003\u0010\b\u001a\n\u0012\u0004\u0012\u00020\n\u0018\u00010\t\u00a2\u0006\u0002\u0010\u000bJ\t\u0010\u0014\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0015\u001a\u00020\u0005H\u00c6\u0003J\u000b\u0010\u0016\u001a\u0004\u0018\u00010\u0007H\u00c6\u0003J\u0011\u0010\u0017\u001a\n\u0012\u0004\u0012\u00020\n\u0018\u00010\tH\u00c6\u0003J;\u0010\u0018\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00052\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u00072\u0010\b\u0003\u0010\b\u001a\n\u0012\u0004\u0012\u00020\n\u0018\u00010\tH\u00c6\u0001J\u0013\u0010\u0019\u001a\u00020\u00032\b\u0010\u001a\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001b\u001a\u00020\u001cH\u00d6\u0001J\t\u0010\u001d\u001a\u00020\u001eH\u00d6\u0001R\u0019\u0010\b\u001a\n\u0012\u0004\u0012\u00020\n\u0018\u00010\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0013\u0010\u0006\u001a\u0004\u0018\u00010\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013\u00a8\u0006\u001f"}, d2 = {"Lorg/openapitools/client/models/SyncResponse;", "", "success", "", "timestamp", "Ljava/time/OffsetDateTime;", "data", "Lorg/openapitools/client/models/SyncResponseData;", "conflicts", "", "Lorg/openapitools/client/models/UserExercise;", "(ZLjava/time/OffsetDateTime;Lorg/openapitools/client/models/SyncResponseData;Ljava/util/List;)V", "getConflicts", "()Ljava/util/List;", "getData", "()Lorg/openapitools/client/models/SyncResponseData;", "getSuccess", "()Z", "getTimestamp", "()Ljava/time/OffsetDateTime;", "component1", "component2", "component3", "component4", "copy", "equals", "other", "hashCode", "", "toString", "", "app_debug"})
public final class SyncResponse {
    private final boolean success = false;
    @org.jetbrains.annotations.NotNull
    private final java.time.OffsetDateTime timestamp = null;
    @org.jetbrains.annotations.Nullable
    private final org.openapitools.client.models.SyncResponseData data = null;
    @org.jetbrains.annotations.Nullable
    private final java.util.List<org.openapitools.client.models.UserExercise> conflicts = null;
    
    public SyncResponse(@com.squareup.moshi.Json(name = "success")
    boolean success, @com.squareup.moshi.Json(name = "timestamp")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime timestamp, @com.squareup.moshi.Json(name = "data")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncResponseData data, @com.squareup.moshi.Json(name = "conflicts")
    @org.jetbrains.annotations.Nullable
    java.util.List<org.openapitools.client.models.UserExercise> conflicts) {
        super();
    }
    
    public final boolean getSuccess() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime getTimestamp() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.SyncResponseData getData() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.util.List<org.openapitools.client.models.UserExercise> getConflicts() {
        return null;
    }
    
    public final boolean component1() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.SyncResponseData component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.util.List<org.openapitools.client.models.UserExercise> component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.SyncResponse copy(@com.squareup.moshi.Json(name = "success")
    boolean success, @com.squareup.moshi.Json(name = "timestamp")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime timestamp, @com.squareup.moshi.Json(name = "data")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncResponseData data, @com.squareup.moshi.Json(name = "conflicts")
    @org.jetbrains.annotations.Nullable
    java.util.List<org.openapitools.client.models.UserExercise> conflicts) {
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