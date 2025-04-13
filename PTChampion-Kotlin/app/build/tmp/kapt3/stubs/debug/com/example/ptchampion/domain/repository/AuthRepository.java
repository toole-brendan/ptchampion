package com.example.ptchampion.domain.repository;

import org.openapitools.client.models.LoginRequest;
import org.openapitools.client.models.LoginResponse;
import org.openapitools.client.models.InsertUser;
import org.openapitools.client.models.User;
import com.example.ptchampion.util.Resource;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000*\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\bf\u0018\u00002\u00020\u0001J\u001f\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\u0006\u0010\u0005\u001a\u00020\u0006H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0007J\u001f\u0010\b\u001a\b\u0012\u0004\u0012\u00020\t0\u00032\u0006\u0010\n\u001a\u00020\u000bH\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\f\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\r"}, d2 = {"Lcom/example/ptchampion/domain/repository/AuthRepository;", "", "login", "Lcom/example/ptchampion/util/Resource;", "Lorg/openapitools/client/models/LoginResponse;", "loginRequest", "Lorg/openapitools/client/models/LoginRequest;", "(Lorg/openapitools/client/models/LoginRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "register", "Lorg/openapitools/client/models/User;", "insertUser", "Lorg/openapitools/client/models/InsertUser;", "(Lorg/openapitools/client/models/InsertUser;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public abstract interface AuthRepository {
    
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object login(@org.jetbrains.annotations.NotNull
    org.openapitools.client.models.LoginRequest loginRequest, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<org.openapitools.client.models.LoginResponse>> $completion);
    
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object register(@org.jetbrains.annotations.NotNull
    org.openapitools.client.models.InsertUser insertUser, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<org.openapitools.client.models.User>> $completion);
}