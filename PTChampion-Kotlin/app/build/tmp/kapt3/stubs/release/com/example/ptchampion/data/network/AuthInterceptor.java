package com.example.ptchampion.data.network;

import com.example.ptchampion.data.repository.UserPreferencesRepository;
import okhttp3.Interceptor;
import okhttp3.Response;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001e\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u0010\u0010\u0005\u001a\u00020\u00062\u0006\u0010\u0007\u001a\u00020\bH\u0016R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u00a8\u0006\t"}, d2 = {"Lcom/example/ptchampion/data/network/AuthInterceptor;", "Lokhttp3/Interceptor;", "userPreferencesRepository", "Lcom/example/ptchampion/data/repository/UserPreferencesRepository;", "(Lcom/example/ptchampion/data/repository/UserPreferencesRepository;)V", "intercept", "Lokhttp3/Response;", "chain", "Lokhttp3/Interceptor$Chain;", "app_release"})
public final class AuthInterceptor implements okhttp3.Interceptor {
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.data.repository.UserPreferencesRepository userPreferencesRepository = null;
    
    @javax.inject.Inject
    public AuthInterceptor(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.data.repository.UserPreferencesRepository userPreferencesRepository) {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public okhttp3.Response intercept(@org.jetbrains.annotations.NotNull
    okhttp3.Interceptor.Chain chain) {
        return null;
    }
}