package org.openapitools.client.models;

import org.openapitools.client.models.SyncRequestData;
import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Request payload for synchronizing data
 *
 * @param userId 
 * @param deviceId 
 * @param lastSyncTimestamp 
 * @param `data`
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000,\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u000f\n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001B/\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0007\u0012\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\t\u00a2\u0006\u0002\u0010\nJ\t\u0010\u0013\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u0014\u001a\u00020\u0005H\u00c6\u0003J\t\u0010\u0015\u001a\u00020\u0007H\u00c6\u0003J\u000b\u0010\u0016\u001a\u0004\u0018\u00010\tH\u00c6\u0003J3\u0010\u0017\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00052\b\b\u0003\u0010\u0006\u001a\u00020\u00072\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\tH\u00c6\u0001J\u0013\u0010\u0018\u001a\u00020\u00192\b\u0010\u001a\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001b\u001a\u00020\u0003H\u00d6\u0001J\t\u0010\u001c\u001a\u00020\u0005H\u00d6\u0001R\u0013\u0010\b\u001a\u0004\u0018\u00010\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000b\u0010\fR\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\r\u0010\u000eR\u0011\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u0012\u00a8\u0006\u001d"}, d2 = {"Lorg/openapitools/client/models/SyncRequest;", "", "userId", "", "deviceId", "", "lastSyncTimestamp", "Ljava/time/OffsetDateTime;", "data", "Lorg/openapitools/client/models/SyncRequestData;", "(ILjava/lang/String;Ljava/time/OffsetDateTime;Lorg/openapitools/client/models/SyncRequestData;)V", "getData", "()Lorg/openapitools/client/models/SyncRequestData;", "getDeviceId", "()Ljava/lang/String;", "getLastSyncTimestamp", "()Ljava/time/OffsetDateTime;", "getUserId", "()I", "component1", "component2", "component3", "component4", "copy", "equals", "", "other", "hashCode", "toString", "app_release"})
public final class SyncRequest {
    private final int userId = 0;
    @org.jetbrains.annotations.NotNull
    private final java.lang.String deviceId = null;
    @org.jetbrains.annotations.NotNull
    private final java.time.OffsetDateTime lastSyncTimestamp = null;
    @org.jetbrains.annotations.Nullable
    private final org.openapitools.client.models.SyncRequestData data = null;
    
    public SyncRequest(@com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "deviceId")
    @org.jetbrains.annotations.NotNull
    java.lang.String deviceId, @com.squareup.moshi.Json(name = "lastSyncTimestamp")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime lastSyncTimestamp, @com.squareup.moshi.Json(name = "data")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncRequestData data) {
        super();
    }
    
    public final int getUserId() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getDeviceId() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime getLastSyncTimestamp() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.SyncRequestData getData() {
        return null;
    }
    
    public final int component1() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.time.OffsetDateTime component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final org.openapitools.client.models.SyncRequestData component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.SyncRequest copy(@com.squareup.moshi.Json(name = "userId")
    int userId, @com.squareup.moshi.Json(name = "deviceId")
    @org.jetbrains.annotations.NotNull
    java.lang.String deviceId, @com.squareup.moshi.Json(name = "lastSyncTimestamp")
    @org.jetbrains.annotations.NotNull
    java.time.OffsetDateTime lastSyncTimestamp, @com.squareup.moshi.Json(name = "data")
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncRequestData data) {
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