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
import android.content.Context;
import androidx.datastore.core.DataStore;
import androidx.datastore.preferences.core.Preferences;
import kotlinx.coroutines.flow.Flow;
import androidx.datastore.preferences.core.PreferenceDataStoreFactory;
import dagger.hilt.android.qualifiers.ApplicationContext;

@javax.inject.Singleton
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000T\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0006\b\u0007\u0018\u00002\u00020\u0001:\u0001\u001fB\u0019\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\b\b\u0001\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006J\u0011\u0010\n\u001a\u00020\u000bH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\fJ\u0010\u0010\r\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010\u000f0\u000eH\u0016J\u001f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00120\u00112\u0006\u0010\u0013\u001a\u00020\u0014H\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015J\u0011\u0010\u0016\u001a\u00020\u000bH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\fJ\u001f\u0010\u0017\u001a\b\u0012\u0004\u0012\u00020\u00180\u00112\u0006\u0010\u0019\u001a\u00020\u001aH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001bJ\u0019\u0010\u001c\u001a\u00020\u000b2\u0006\u0010\u001d\u001a\u00020\u000fH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001eR\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0014\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\bX\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006 "}, d2 = {"Lcom/example/ptchampion/data/repository/AuthRepositoryImpl;", "Lcom/example/ptchampion/domain/repository/AuthRepository;", "api", "Lorg/openapitools/client/apis/AuthApi;", "context", "Landroid/content/Context;", "(Lorg/openapitools/client/apis/AuthApi;Landroid/content/Context;)V", "dataStore", "Landroidx/datastore/core/DataStore;", "Landroidx/datastore/preferences/core/Preferences;", "clearAuthToken", "", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getAuthToken", "Lkotlinx/coroutines/flow/Flow;", "", "login", "Lcom/example/ptchampion/util/Resource;", "Lorg/openapitools/client/models/LoginResponse;", "loginRequest", "Lorg/openapitools/client/models/LoginRequest;", "(Lorg/openapitools/client/models/LoginRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "logout", "register", "Lorg/openapitools/client/models/User;", "insertUser", "Lorg/openapitools/client/models/InsertUser;", "(Lorg/openapitools/client/models/InsertUser;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "storeAuthToken", "token", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "PreferencesKeys", "app_debug"})
public final class AuthRepositoryImpl implements com.example.ptchampion.domain.repository.AuthRepository {
    @org.jetbrains.annotations.NotNull
    private final org.openapitools.client.apis.AuthApi api = null;
    @org.jetbrains.annotations.NotNull
    private final android.content.Context context = null;
    @org.jetbrains.annotations.NotNull
    private final androidx.datastore.core.DataStore<androidx.datastore.preferences.core.Preferences> dataStore = null;
    
    @javax.inject.Inject
    public AuthRepositoryImpl(@org.jetbrains.annotations.NotNull
    org.openapitools.client.apis.AuthApi api, @dagger.hilt.android.qualifiers.ApplicationContext
    @org.jetbrains.annotations.NotNull
    android.content.Context context) {
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
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object storeAuthToken(@org.jetbrains.annotations.NotNull
    java.lang.String token, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public kotlinx.coroutines.flow.Flow<java.lang.String> getAuthToken() {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object clearAuthToken(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object logout(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0018\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u000e\n\u0002\b\u0003\b\u00c2\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u0017\u0010\u0003\u001a\b\u0012\u0004\u0012\u00020\u00050\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0006\u0010\u0007\u00a8\u0006\b"}, d2 = {"Lcom/example/ptchampion/data/repository/AuthRepositoryImpl$PreferencesKeys;", "", "()V", "AUTH_TOKEN", "Landroidx/datastore/preferences/core/Preferences$Key;", "", "getAUTH_TOKEN", "()Landroidx/datastore/preferences/core/Preferences$Key;", "app_debug"})
    static final class PreferencesKeys {
        @org.jetbrains.annotations.NotNull
        private static final androidx.datastore.preferences.core.Preferences.Key<java.lang.String> AUTH_TOKEN = null;
        @org.jetbrains.annotations.NotNull
        public static final com.example.ptchampion.data.repository.AuthRepositoryImpl.PreferencesKeys INSTANCE = null;
        
        private PreferencesKeys() {
            super();
        }
        
        @org.jetbrains.annotations.NotNull
        public final androidx.datastore.preferences.core.Preferences.Key<java.lang.String> getAUTH_TOKEN() {
            return null;
        }
    }
}