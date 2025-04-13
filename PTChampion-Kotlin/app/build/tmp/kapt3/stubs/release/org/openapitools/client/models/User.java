package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * User profile information
 *
 * @param id 
 * @param username 
 * @param displayName 
 * @param profilePictureUrl 
 * @param location 
 * @param latitude 
 * @param longitude 
 * @param lastSyncedAt 
 * @param createdAt 
 * @param updatedAt
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b \n\u0002\u0010\u000b\n\u0002\b\u0004\b\u0086\b\u0018\u00002\u00020\u0001By\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0005\u0012\n\b\u0001\u0010\u0006\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0001\u0010\u0007\u001a\u0004\u0018\u00010\b\u0012\n\b\u0001\u0010\t\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0001\u0010\n\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0001\u0010\u000b\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0001\u0010\f\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0001\u0010\r\u001a\u0004\u0018\u00010\u0005\u0012\n\b\u0001\u0010\u000e\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\u0002\u0010\u000fJ\t\u0010\u001d\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u001e\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\t\u0010\u001f\u001a\u00020\u0005H\u00c6\u0003J\u000b\u0010 \u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010!\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\u000b\u0010\"\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010#\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010$\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010%\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J\u000b\u0010&\u001a\u0004\u0018\u00010\u0005H\u00c6\u0003J}\u0010\'\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u00052\n\b\u0003\u0010\u0006\u001a\u0004\u0018\u00010\u00052\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\b2\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\u00052\n\b\u0003\u0010\n\u001a\u0004\u0018\u00010\u00052\n\b\u0003\u0010\u000b\u001a\u0004\u0018\u00010\u00052\n\b\u0003\u0010\f\u001a\u0004\u0018\u00010\u00052\n\b\u0003\u0010\r\u001a\u0004\u0018\u00010\u00052\n\b\u0003\u0010\u000e\u001a\u0004\u0018\u00010\u0005H\u00c6\u0001J\u0013\u0010(\u001a\u00020)2\b\u0010*\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010+\u001a\u00020\u0003H\u00d6\u0001J\t\u0010,\u001a\u00020\u0005H\u00d6\u0001R\u0013\u0010\r\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0013\u0010\u0006\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0011R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u0014R\u0013\u0010\f\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0015\u0010\u0011R\u0013\u0010\n\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0011R\u0013\u0010\t\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0011R\u0013\u0010\u000b\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0011R\u0013\u0010\u0007\u001a\u0004\u0018\u00010\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0019\u0010\u001aR\u0013\u0010\u000e\u001a\u0004\u0018\u00010\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001b\u0010\u0011R\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u0011\u00a8\u0006-"}, d2 = {"Lorg/openapitools/client/models/User;", "", "id", "", "username", "", "displayName", "profilePictureUrl", "Ljava/net/URI;", "location", "latitude", "longitude", "lastSyncedAt", "createdAt", "updatedAt", "(ILjava/lang/String;Ljava/lang/String;Ljava/net/URI;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V", "getCreatedAt", "()Ljava/lang/String;", "getDisplayName", "getId", "()I", "getLastSyncedAt", "getLatitude", "getLocation", "getLongitude", "getProfilePictureUrl", "()Ljava/net/URI;", "getUpdatedAt", "getUsername", "component1", "component10", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "", "other", "hashCode", "toString", "app_release"})
public final class User {
    private final int id = 0;
    @org.jetbrains.annotations.NotNull
    private final java.lang.String username = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String displayName = null;
    @org.jetbrains.annotations.Nullable
    private final java.net.URI profilePictureUrl = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String location = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String latitude = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String longitude = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String lastSyncedAt = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String createdAt = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String updatedAt = null;
    
    public User(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "username")
    @org.jetbrains.annotations.NotNull
    java.lang.String username, @com.squareup.moshi.Json(name = "displayName")
    @org.jetbrains.annotations.Nullable
    java.lang.String displayName, @com.squareup.moshi.Json(name = "profilePictureUrl")
    @org.jetbrains.annotations.Nullable
    java.net.URI profilePictureUrl, @com.squareup.moshi.Json(name = "location")
    @org.jetbrains.annotations.Nullable
    java.lang.String location, @com.squareup.moshi.Json(name = "latitude")
    @org.jetbrains.annotations.Nullable
    java.lang.String latitude, @com.squareup.moshi.Json(name = "longitude")
    @org.jetbrains.annotations.Nullable
    java.lang.String longitude, @com.squareup.moshi.Json(name = "lastSyncedAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String lastSyncedAt, @com.squareup.moshi.Json(name = "createdAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String createdAt, @com.squareup.moshi.Json(name = "updatedAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String updatedAt) {
        super();
    }
    
    public final int getId() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getUsername() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getDisplayName() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.net.URI getProfilePictureUrl() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getLocation() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getLatitude() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getLongitude() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String getLastSyncedAt() {
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
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.net.URI component4() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component6() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component7() {
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
    public final org.openapitools.client.models.User copy(@com.squareup.moshi.Json(name = "id")
    int id, @com.squareup.moshi.Json(name = "username")
    @org.jetbrains.annotations.NotNull
    java.lang.String username, @com.squareup.moshi.Json(name = "displayName")
    @org.jetbrains.annotations.Nullable
    java.lang.String displayName, @com.squareup.moshi.Json(name = "profilePictureUrl")
    @org.jetbrains.annotations.Nullable
    java.net.URI profilePictureUrl, @com.squareup.moshi.Json(name = "location")
    @org.jetbrains.annotations.Nullable
    java.lang.String location, @com.squareup.moshi.Json(name = "latitude")
    @org.jetbrains.annotations.Nullable
    java.lang.String latitude, @com.squareup.moshi.Json(name = "longitude")
    @org.jetbrains.annotations.Nullable
    java.lang.String longitude, @com.squareup.moshi.Json(name = "lastSyncedAt")
    @org.jetbrains.annotations.Nullable
    java.lang.String lastSyncedAt, @com.squareup.moshi.Json(name = "createdAt")
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
}