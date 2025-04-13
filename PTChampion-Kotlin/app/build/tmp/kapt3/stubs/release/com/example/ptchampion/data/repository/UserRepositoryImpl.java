package com.example.ptchampion.data.repository;

import com.example.ptchampion.data.datastore.AuthDataStore;
import org.openapitools.client.apis.UsersApi;
import com.example.ptchampion.domain.model.UpdateLocationRequest;
import com.example.ptchampion.domain.model.UserProfile;
import com.example.ptchampion.domain.repository.UserRepository;
import com.example.ptchampion.util.Resource;
import kotlinx.coroutines.flow.Flow;
import retrofit2.HttpException;
import java.io.IOException;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00006\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u0017\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006J\u0014\u0010\u0007\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\n0\t0\bH\u0016J\u0017\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\f0\tH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\rJ\u001f\u0010\u000e\u001a\b\u0012\u0004\u0012\u00020\f0\t2\u0006\u0010\u000f\u001a\u00020\u0010H\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0011R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0012"}, d2 = {"Lcom/example/ptchampion/data/repository/UserRepositoryImpl;", "Lcom/example/ptchampion/domain/repository/UserRepository;", "usersApi", "Lorg/openapitools/client/apis/UsersApi;", "authDataStore", "Lcom/example/ptchampion/data/datastore/AuthDataStore;", "(Lorg/openapitools/client/apis/UsersApi;Lcom/example/ptchampion/data/datastore/AuthDataStore;)V", "getUserProfileFlow", "Lkotlinx/coroutines/flow/Flow;", "Lcom/example/ptchampion/util/Resource;", "Lcom/example/ptchampion/domain/model/UserProfile;", "refreshUserProfile", "", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "updateUserLocation", "request", "Lcom/example/ptchampion/domain/model/UpdateLocationRequest;", "(Lcom/example/ptchampion/domain/model/UpdateLocationRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_release"})
public final class UserRepositoryImpl implements com.example.ptchampion.domain.repository.UserRepository {
    @org.jetbrains.annotations.NotNull
    private final org.openapitools.client.apis.UsersApi usersApi = null;
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.data.datastore.AuthDataStore authDataStore = null;
    
    @javax.inject.Inject
    public UserRepositoryImpl(@org.jetbrains.annotations.NotNull
    org.openapitools.client.apis.UsersApi usersApi, @org.jetbrains.annotations.NotNull
    com.example.ptchampion.data.datastore.AuthDataStore authDataStore) {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public kotlinx.coroutines.flow.Flow<com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.UserProfile>> getUserProfileFlow() {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object refreshUserProfile(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<kotlin.Unit>> $completion) {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object updateUserLocation(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.UpdateLocationRequest request, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<kotlin.Unit>> $completion) {
        return null;
    }
}