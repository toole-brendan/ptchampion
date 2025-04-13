package com.example.ptchampion.data.repository;

import com.example.ptchampion.data.network.WorkoutApiService;
import com.example.ptchampion.domain.model.SaveWorkoutRequest;
import com.example.ptchampion.domain.model.WorkoutResponse;
import com.example.ptchampion.domain.repository.WorkoutRepository;
import com.example.ptchampion.util.Resource;
import retrofit2.HttpException;
import java.io.IOException;
import javax.inject.Inject;
import javax.inject.Singleton;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse;

@javax.inject.Singleton
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000>\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u001d\u0010\u0005\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\b0\u00070\u0006H\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\tJ\'\u0010\n\u001a\b\u0012\u0004\u0012\u00020\u000b0\u00062\u0006\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\rH\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u000fJ\u001f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00110\u00062\u0006\u0010\u0012\u001a\u00020\u0013H\u0096@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0014R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0015"}, d2 = {"Lcom/example/ptchampion/data/repository/WorkoutRepositoryImpl;", "Lcom/example/ptchampion/domain/repository/WorkoutRepository;", "workoutApiService", "Lcom/example/ptchampion/data/network/WorkoutApiService;", "(Lcom/example/ptchampion/data/network/WorkoutApiService;)V", "getExercises", "Lcom/example/ptchampion/util/Resource;", "", "Lcom/example/ptchampion/domain/model/ExerciseResponse;", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getWorkoutHistory", "Lcom/example/ptchampion/domain/model/PaginatedWorkoutResponse;", "page", "", "pageSize", "(IILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "saveWorkout", "Lcom/example/ptchampion/domain/model/WorkoutResponse;", "request", "Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;", "(Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public final class WorkoutRepositoryImpl implements com.example.ptchampion.domain.repository.WorkoutRepository {
    @org.jetbrains.annotations.NotNull
    private final com.example.ptchampion.data.network.WorkoutApiService workoutApiService = null;
    
    @javax.inject.Inject
    public WorkoutRepositoryImpl(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.data.network.WorkoutApiService workoutApiService) {
        super();
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object saveWorkout(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.SaveWorkoutRequest request, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.WorkoutResponse>> $completion) {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object getExercises(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<java.util.List<com.example.ptchampion.domain.model.ExerciseResponse>>> $completion) {
        return null;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.Nullable
    public java.lang.Object getWorkoutHistory(int page, int pageSize, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.PaginatedWorkoutResponse>> $completion) {
        return null;
    }
}