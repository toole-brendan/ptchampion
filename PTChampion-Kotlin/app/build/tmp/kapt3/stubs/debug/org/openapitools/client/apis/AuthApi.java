package org.openapitools.client.apis;

import retrofit2.http.*;
import retrofit2.Call;
import okhttp3.RequestBody;
import com.squareup.moshi.Json;
import org.openapitools.client.models.InsertUser;
import org.openapitools.client.models.LoginRequest;
import org.openapitools.client.models.LoginResponse;
import org.openapitools.client.models.User;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000&\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\bf\u0018\u00002\u00020\u0001J\u001a\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0006H\'J\u001a\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\b0\u00032\n\b\u0003\u0010\t\u001a\u0004\u0018\u00010\nH\'\u00a8\u0006\u000b"}, d2 = {"Lorg/openapitools/client/apis/AuthApi;", "", "authLoginPost", "Lretrofit2/Call;", "Lorg/openapitools/client/models/LoginResponse;", "loginRequest", "Lorg/openapitools/client/models/LoginRequest;", "authRegisterPost", "Lorg/openapitools/client/models/User;", "insertUser", "Lorg/openapitools/client/models/InsertUser;", "app_debug"})
public abstract interface AuthApi {
    
    /**
     * POST auth/login
     * Authenticate a user and get JWT token
     *
     * Responses:
     * - 200: Login successful
     * - 400: Invalid input
     * - 401: Invalid username or password
     * - 500: Internal Server Error
     *
     * @param loginRequest  (optional)
     * @return [Call]<[LoginResponse]>
     */
    @retrofit2.http.POST(value = "auth/login")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<org.openapitools.client.models.LoginResponse> authLoginPost(@retrofit2.http.Body
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.LoginRequest loginRequest);
    
    /**
     * POST auth/register
     * Register a new user
     *
     * Responses:
     * - 201: User created successfully
     * - 400: Invalid input (e.g., validation error)
     * - 409: Username already exists
     * - 500: Internal Server Error
     *
     * @param insertUser  (optional)
     * @return [Call]<[User]>
     */
    @retrofit2.http.POST(value = "auth/register")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<org.openapitools.client.models.User> authRegisterPost(@retrofit2.http.Body
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.InsertUser insertUser);
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 3, xi = 48)
    public static final class DefaultImpls {
    }
}