package com.example.ptchampion.domain.repository;

import org.openapitools.client.models.LoginRequest;
import org.openapitools.client.models.LoginResponse;
import org.openapitools.client.models.InsertUser;
import org.openapitools.client.models.User;
import com.example.ptchampion.util.Resource;
import kotlinx.coroutines.flow.Flow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000<\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\bf\u0018\u00002\u00020\u0001J\u0011\u0010\u0002\u001a\u00020\u0003H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0004J\u0010\u0010\u0005\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010\u00070\u0006H&J\u001f\u0010\b\u001a\b\u0012\u0004\u0012\u00020\n0\t2\u0006\u0010\u000b\u001a\u00020\fH\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\rJ\u0011\u0010\u000e\u001a\u00020\u0003H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0004J\u001f\u0010\u000f\u001a\b\u0012\u0004\u0012\u00020\u00100\t2\u0006\u0010\u0011\u001a\u00020\u0012H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0013J\u0019\u0010\u0014\u001a\u00020\u00032\u0006\u0010\u0015\u001a\u00020\u0007H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0016\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0017"}, d2 = {"Lcom/example/ptchampion/domain/repository/AuthRepository;", "", "clearAuthToken", "", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getAuthToken", "Lkotlinx/coroutines/flow/Flow;", "", "login", "Lcom/example/ptchampion/util/Resource;", "Lorg/openapitools/client/models/LoginResponse;", "loginRequest", "Lorg/openapitools/client/models/LoginRequest;", "(Lorg/openapitools/client/models/LoginRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "logout", "register", "Lorg/openapitools/client/models/User;", "insertUser", "Lorg/openapitools/client/models/InsertUser;", "(Lorg/openapitools/client/models/InsertUser;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "storeAuthToken", "token", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public abstract interface AuthRepository {
    
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object login(@org.jetbrains.annotations.NotNull
    org.openapitools.client.models.LoginRequest loginRequest, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<org.openapitools.client.models.LoginResponse>> $completion);
    
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object register(@org.jetbrains.annotations.NotNull
    org.openapitools.client.models.InsertUser insertUser, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<org.openapitools.client.models.User>> $completion);
    
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object logout(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion);
    
    /**
     * Stores the authentication token securely.
     * @param token The authentication token to store.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object storeAuthToken(@org.jetbrains.annotations.NotNull
    java.lang.String token, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion);
    
    /**
     * Retrieves the stored authentication token as a Flow.
     * Emits null if no token is stored.
     * @return A Flow emitting the auth token or null.
     */
    @org.jetbrains.annotations.NotNull
    public abstract kotlinx.coroutines.flow.Flow<java.lang.String> getAuthToken();
    
    /**
     * Clears the stored authentication token.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object clearAuthToken(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion);
}