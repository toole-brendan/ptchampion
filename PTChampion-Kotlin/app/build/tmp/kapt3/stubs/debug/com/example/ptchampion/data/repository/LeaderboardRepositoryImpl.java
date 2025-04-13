package com.example.ptchampion.data.repository;

import com.example.ptchampion.domain.model.LeaderboardEntry;
import com.example.ptchampion.domain.repository.LeaderboardRepository;
import com.example.ptchampion.util.Resource;
import org.openapitools.client.apis.LeaderboardApi;
import retrofit2.HttpException;
import java.io.IOException;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000.\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0000\n\u0002\u0010\b\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J-\u0010\u0005\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\b0\u00070\u00062\u0006\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\fH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\rR\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u000e"}, d2 = {"Lcom/example/ptchampion/data/repository/LeaderboardRepositoryImpl;", "Lcom/example/ptchampion/domain/repository/LeaderboardRepository;", "leaderboardApi", "Lorg/openapitools/client/apis/LeaderboardApi;", "(Lorg/openapitools/client/apis/LeaderboardApi;)V", "getLeaderboard", "Lcom/example/ptchampion/util/Resource;", "", "Lcom/example/ptchampion/domain/model/LeaderboardEntry;", "exerciseType", "", "limit", "", "(Ljava/lang/String;ILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public final class LeaderboardRepositoryImpl implements com.example.ptchampion.domain.repository.LeaderboardRepository {
    @org.jetbrains.annotations.NotNull
    private final org.openapitools.client.apis.LeaderboardApi leaderboardApi = null;
    
    @javax.inject.Inject
    public LeaderboardRepositoryImpl(@org.jetbrains.annotations.NotNull
    org.openapitools.client.apis.LeaderboardApi leaderboardApi) {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object getLeaderboard(@org.jetbrains.annotations.NotNull
    java.lang.String exerciseType, int limit, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<java.util.List<com.example.ptchampion.domain.model.LeaderboardEntry>>> $completion) {
        return null;
    }
}