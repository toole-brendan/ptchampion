package com.example.ptchampion.data.network;

import com.example.ptchampion.domain.model.SaveWorkoutRequest;
import com.example.ptchampion.domain.model.WorkoutResponse;
import retrofit2.Response;
import retrofit2.http.Body;
import retrofit2.http.POST;
import retrofit2.http.GET;
import retrofit2.http.Query;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse;
import com.example.ptchampion.domain.model.UpdateLocationRequest;
import com.example.ptchampion.domain.model.LocalLeaderboardEntry;
import retrofit2.http.PUT;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000R\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\bf\u0018\u00002\u00020\u0001J\u001d\u0010\u0002\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\u00040\u0003H\u00a7@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0006JG\u0010\u0007\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\b0\u00040\u00032\b\b\u0001\u0010\t\u001a\u00020\n2\b\b\u0001\u0010\u000b\u001a\u00020\f2\b\b\u0001\u0010\r\u001a\u00020\f2\n\b\u0001\u0010\u000e\u001a\u0004\u0018\u00010\fH\u00a7@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u000fJ+\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00110\u00032\b\b\u0001\u0010\u0012\u001a\u00020\n2\b\b\u0001\u0010\u0013\u001a\u00020\nH\u00a7@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0014J!\u0010\u0015\u001a\b\u0012\u0004\u0012\u00020\u00160\u00032\b\b\u0001\u0010\u0017\u001a\u00020\u0018H\u00a7@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0019J!\u0010\u001a\u001a\b\u0012\u0004\u0012\u00020\u001b0\u00032\b\b\u0001\u0010\u001c\u001a\u00020\u001dH\u00a7@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u001e\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u001f"}, d2 = {"Lcom/example/ptchampion/data/network/WorkoutApiService;", "", "getExercises", "Lretrofit2/Response;", "", "Lcom/example/ptchampion/domain/model/ExerciseResponse;", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getLocalLeaderboard", "Lcom/example/ptchampion/domain/model/LocalLeaderboardEntry;", "exerciseId", "", "latitude", "", "longitude", "radiusMeters", "(IDDLjava/lang/Double;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getWorkoutHistory", "Lcom/example/ptchampion/domain/model/PaginatedWorkoutResponse;", "page", "pageSize", "(IILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "saveWorkout", "Lcom/example/ptchampion/domain/model/WorkoutResponse;", "workoutRequest", "Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;", "(Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "updateUserLocation", "", "locationRequest", "Lcom/example/ptchampion/domain/model/UpdateLocationRequest;", "(Lcom/example/ptchampion/domain/model/UpdateLocationRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_release"})
public abstract interface WorkoutApiService {
    
    @retrofit2.http.POST(value = "api/v1/workouts")
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object saveWorkout(@retrofit2.http.Body
    @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.SaveWorkoutRequest workoutRequest, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super retrofit2.Response<com.example.ptchampion.domain.model.WorkoutResponse>> $completion);
    
    @retrofit2.http.GET(value = "api/v1/exercises")
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object getExercises(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super retrofit2.Response<java.util.List<com.example.ptchampion.domain.model.ExerciseResponse>>> $completion);
    
    @retrofit2.http.GET(value = "api/v1/workouts")
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object getWorkoutHistory(@retrofit2.http.Query(value = "page")
    int page, @retrofit2.http.Query(value = "pageSize")
    int pageSize, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super retrofit2.Response<com.example.ptchampion.domain.model.PaginatedWorkoutResponse>> $completion);
    
    @retrofit2.http.PUT(value = "api/v1/profile/location")
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object updateUserLocation(@retrofit2.http.Body
    @org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.UpdateLocationRequest locationRequest, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super retrofit2.Response<kotlin.Unit>> $completion);
    
    @retrofit2.http.GET(value = "api/v1/leaderboards/local")
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object getLocalLeaderboard(@retrofit2.http.Query(value = "exercise_id")
    int exerciseId, @retrofit2.http.Query(value = "latitude")
    double latitude, @retrofit2.http.Query(value = "longitude")
    double longitude, @retrofit2.http.Query(value = "radius_meters")
    @org.jetbrains.annotations.Nullable
    java.lang.Double radiusMeters, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super retrofit2.Response<java.util.List<com.example.ptchampion.domain.model.LocalLeaderboardEntry>>> $completion);
}