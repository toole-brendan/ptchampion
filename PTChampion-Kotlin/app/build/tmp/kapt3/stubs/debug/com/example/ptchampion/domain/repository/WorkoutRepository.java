package com.example.ptchampion.domain.repository;

import com.example.ptchampion.domain.model.SaveWorkoutRequest;
import com.example.ptchampion.domain.model.WorkoutResponse;
import com.example.ptchampion.util.Resource;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse;
import com.example.ptchampion.domain.model.WorkoutSession;
import kotlinx.coroutines.flow.Flow;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000>\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0002\bf\u0018\u00002\u00020\u0001J\u001d\u0010\u0002\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\u00040\u0003H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0006J\u001f\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\b0\u00032\u0006\u0010\t\u001a\u00020\nH\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u000bJ\'\u0010\f\u001a\b\u0012\u0004\u0012\u00020\r0\u00032\u0006\u0010\u000e\u001a\u00020\u000f2\u0006\u0010\u0010\u001a\u00020\u000fH\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0011J\u001f\u0010\u0012\u001a\b\u0012\u0004\u0012\u00020\b0\u00032\u0006\u0010\u0013\u001a\u00020\u0014H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0015\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0016"}, d2 = {"Lcom/example/ptchampion/domain/repository/WorkoutRepository;", "", "getExercises", "Lcom/example/ptchampion/util/Resource;", "", "Lcom/example/ptchampion/domain/model/ExerciseResponse;", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getWorkoutById", "Lcom/example/ptchampion/domain/model/WorkoutResponse;", "workoutId", "", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getWorkoutHistory", "Lcom/example/ptchampion/domain/model/PaginatedWorkoutResponse;", "page", "", "pageSize", "(IILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "saveWorkout", "request", "Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;", "(Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public abstract interface WorkoutRepository {
    
    /**
     * Saves a completed workout session to the backend.
     *
     * @param request The workout data to save.
     * @return A Resource indicating success (with the created WorkoutResponse) or failure.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object saveWorkout(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.SaveWorkoutRequest request, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.WorkoutResponse>> $completion);
    
    /**
     * Fetches the list of available exercises from the backend.
     *
     * @return A Resource containing the list of exercises or an error.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object getExercises(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<java.util.List<com.example.ptchampion.domain.model.ExerciseResponse>>> $completion);
    
    /**
     * Fetches the workout history for the current user, paginated.
     *
     * @param page The page number to fetch.
     * @param pageSize The number of items per page.
     * @return A Resource containing the paginated workout history or an error.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object getWorkoutHistory(int page, int pageSize, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.PaginatedWorkoutResponse>> $completion);
    
    /**
     * Fetches a specific workout by its ID.
     *
     * @param workoutId The ID of the workout to fetch.
     * @return A Resource containing the workout details or an error.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object getWorkoutById(@org.jetbrains.annotations.NotNull
    java.lang.String workoutId, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.WorkoutResponse>> $completion);
}