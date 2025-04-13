package org.openapitools.client.models;

import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Fields to update in user profile
 *
 * @param username 
 * @param displayName 
 * @param profilePictureUrl 
 * @param location 
 * @param latitude 
 * @param longitude
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0013\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001BM\u0012\n\b\u0003\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0004\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u0012\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\t\u0012\n\b\u0003\u0010\n\u001a\u0004\u0018\u00010\t\u00a2\u0006\u0002\u0010\u000bJ\u000b\u0010\u0015\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010\u0016\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010\u0017\u001a\u0004\u0018\u00010\u0006H\u00c6\u0003J\u000b\u0010\u0018\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010\u0019\u001a\u0004\u0018\u00010\tH\u00c6\u0003J\u000b\u0010\u001a\u001a\u0004\u0018\u00010\tH\u00c6\u0003JQ\u0010\u001b\u001a\u00020\u00002\n\b\u0003\u0010\u0002\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0004\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u00062\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\u00032\n\b\u0003\u0010\b\u001a\u0004\u0018\u00010\t2\n\b\u0003\u0010\n\u001a\u0004\u0018\u00010\tH\u00c6\u0001J\u0013\u0010\u001c\u001a\u00020\u001d2\b\u0010\u001e\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001f\u001a\u00020 H\u00d6\u0001J\t\u0010!\u001a\u00020\u0003H\u00d6\u0001R\u0013\u0010\u0004\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0013\u0010\b\u001a\u0004\u0018\u00010\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0013\u0010\u0007\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\rR\u0013\u0010\n\u001a\u0004\u0018\u00010\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\u000fR\u0013\u0010\u0005\u001a\u0004\u0018\u00010\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013R\u0013\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\r\u00a8\u0006\""}, d2 = {"Lorg/openapitools/client/models/UpdateUserRequest;", "", "username", "", "displayName", "profilePictureUrl", "Ljava/net/URI;", "location", "latitude", "Ljava/math/BigDecimal;", "longitude", "(Ljava/lang/String;Ljava/lang/String;Ljava/net/URI;Ljava/lang/String;Ljava/math/BigDecimal;Ljava/math/BigDecimal;)V", "getDisplayName", "()Ljava/lang/String;", "getLatitude", "()Ljava/math/BigDecimal;", "getLocation", "getLongitude", "getProfilePictureUrl", "()Ljava/net/URI;", "getUsername", "component1", "component2", "component3", "component4", "component5", "component6", "copy", "equals", "", "other", "hashCode", "", "toString", "app_debug"})
public final class UpdateUserRequest {
    @org.jetbrains.annotations.Nullable
    private final java.lang.String username = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String displayName = null;
    @org.jetbrains.annotations.Nullable
    private final java.net.URI profilePictureUrl = null;
    @org.jetbrains.annotations.Nullable
    private final java.lang.String location = null;
    @org.jetbrains.annotations.Nullable
    private final java.math.BigDecimal latitude = null;
    @org.jetbrains.annotations.Nullable
    private final java.math.BigDecimal longitude = null;
    
    public UpdateUserRequest(@com.squareup.moshi.Json(name = "username")
    @org.jetbrains.annotations.Nullable
    java.lang.String username, @com.squareup.moshi.Json(name = "display_name")
    @org.jetbrains.annotations.Nullable
    java.lang.String displayName, @com.squareup.moshi.Json(name = "profile_picture_url")
    @org.jetbrains.annotations.Nullable
    java.net.URI profilePictureUrl, @com.squareup.moshi.Json(name = "location")
    @org.jetbrains.annotations.Nullable
    java.lang.String location, @com.squareup.moshi.Json(name = "latitude")
    @org.jetbrains.annotations.Nullable
    java.math.BigDecimal latitude, @com.squareup.moshi.Json(name = "longitude")
    @org.jetbrains.annotations.Nullable
    java.math.BigDecimal longitude) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable
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
    public final java.math.BigDecimal getLatitude() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.math.BigDecimal getLongitude() {
        return null;
    }
    
    public UpdateUserRequest() {
        super();
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component1() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.net.URI component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.lang.String component4() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.math.BigDecimal component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable
    public final java.math.BigDecimal component6() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.UpdateUserRequest copy(@com.squareup.moshi.Json(name = "username")
    @org.jetbrains.annotations.Nullable
    java.lang.String username, @com.squareup.moshi.Json(name = "display_name")
    @org.jetbrains.annotations.Nullable
    java.lang.String displayName, @com.squareup.moshi.Json(name = "profile_picture_url")
    @org.jetbrains.annotations.Nullable
    java.net.URI profilePictureUrl, @com.squareup.moshi.Json(name = "location")
    @org.jetbrains.annotations.Nullable
    java.lang.String location, @com.squareup.moshi.Json(name = "latitude")
    @org.jetbrains.annotations.Nullable
    java.math.BigDecimal latitude, @com.squareup.moshi.Json(name = "longitude")
    @org.jetbrains.annotations.Nullable
    java.math.BigDecimal longitude) {
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