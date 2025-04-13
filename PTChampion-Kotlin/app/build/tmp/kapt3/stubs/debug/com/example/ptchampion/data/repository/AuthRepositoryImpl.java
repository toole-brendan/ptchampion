package com.example.ptchampion.data.repository;

import com.example.ptchampion.domain.repository.AuthRepository;
import org.openapitools.client.apis.AuthApi;
import org.openapitools.client.models.LoginRequest;
import org.openapitools.client.models.LoginResponse;
import org.openapitools.client.models.InsertUser;
import org.openapitools.client.models.User;
import com.example.ptchampion.util.Resource;
import kotlinx.coroutines.Dispatchers;
import retrofit2.HttpException;
import java.io.IOException;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u001f\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u00062\u0006\u0010\b\u001a\u00020\tH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\nJ\u001f\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\f0\u00062\u0006\u0010\r\u001a\u00020\u000eH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u000fR\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0010"}, d2 = {"Lcom/example/ptchampion/data/repository/AuthRepositoryImpl;", "Lcom/example/ptchampion/domain/repository/AuthRepository;", "api", "Lorg/openapitools/client/apis/AuthApi;", "(Lorg/openapitools/client/apis/AuthApi;)V", "login", "Lcom/example/ptchampion/util/Resource;", "Lorg/openapitools/client/models/LoginResponse;", "loginRequest", "Lorg/openapitools/client/models/LoginRequest;", "(Lorg/openapitools/client/models/LoginRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "register", "Lorg/openapitools/client/models/User;", "insertUser", "Lorg/openapitools/client/models/InsertUser;", "(Lorg/openapitools/client/models/InsertUser;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public final class AuthRepositoryImpl implements com.example.ptchampion.domain.repository.AuthRepository {
    @org.jetbrains.annotations.NotNull
    private final org.openapitools.client.apis.AuthApi api = null;
    
    @javax.inject.Inject
    public AuthRepositoryImpl(@org.jetbrains.annotations.NotNull
    org.openapitools.client.apis.AuthApi api) {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object login(@org.jetbrains.annotations.NotNull
    org.openapitools.client.models.LoginRequest loginRequest, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<org.openapitools.client.models.LoginResponse>> $completion) {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object register(@org.jetbrains.annotations.NotNull
    org.openapitools.client.models.InsertUser insertUser, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<org.openapitools.client.models.User>> $completion) {
        return null;
    }
}