package org.openapitools.client.models;

import org.openapitools.client.models.User;
import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Authentication token and user profile
 *
 * @param token 
 * @param user
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\t\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001B\u0019\u0012\b\b\u0001\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006J\t\u0010\u000b\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\f\u001a\u00020\u0005H\u00c6\u0003J\u001d\u0010\r\u001a\u00020\u00002\b\b\u0003\u0010\u0002\u001a\u00020\u00032\b\b\u0003\u0010\u0004\u001a\u00020\u0005H\u00c6\u0001J\u0013\u0010\u000e\u001a\u00020\u000f2\b\u0010\u0010\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u0011\u001a\u00020\u0012H\u00d6\u0001J\t\u0010\u0013\u001a\u00020\u0003H\u00d6\u0001R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0007\u0010\bR\u0011\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\b\n\u0000\u001a\u0004\b\t\u0010\n\u00a8\u0006\u0014"}, d2 = {"Lorg/openapitools/client/models/LoginResponse;", "", "token", "", "user", "Lorg/openapitools/client/models/User;", "(Ljava/lang/String;Lorg/openapitools/client/models/User;)V", "getToken", "()Ljava/lang/String;", "getUser", "()Lorg/openapitools/client/models/User;", "component1", "component2", "copy", "equals", "", "other", "hashCode", "", "toString", "app_debug"})
public final class LoginResponse {
    @org.jetbrains.annotations.NotNull
    private final java.lang.String token = null;
    @org.jetbrains.annotations.NotNull
    private final org.openapitools.client.models.User user = null;
    
    public LoginResponse(@com.squareup.moshi.Json(name = "token")
    @org.jetbrains.annotations.NotNull
    java.lang.String token, @com.squareup.moshi.Json(name = "user")
    @org.jetbrains.annotations.NotNull
    org.openapitools.client.models.User user) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String getToken() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.User getUser() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.lang.String component1() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.User component2() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.LoginResponse copy(@com.squareup.moshi.Json(name = "token")
    @org.jetbrains.annotations.NotNull
    java.lang.String token, @com.squareup.moshi.Json(name = "user")
    @org.jetbrains.annotations.NotNull
    org.openapitools.client.models.User user) {
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