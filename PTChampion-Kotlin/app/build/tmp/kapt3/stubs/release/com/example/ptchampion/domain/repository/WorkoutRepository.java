package com.example.ptchampion.domain.repository;

import com.example.ptchampion.domain.model.SaveWorkoutRequest;
import com.example.ptchampion.domain.model.WorkoutResponse;
import com.example.ptchampion.util.Resource;
import com.example.ptchampion.domain.model.ExerciseResponse;
import com.example.ptchampion.domain.model.PaginatedWorkoutResponse;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00006\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\bf\u0018\u00002\u00020\u0001J\u001d\u0010\u0002\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\u00040\u0003H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0006J\'\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\b0\u00032\u0006\u0010\t\u001a\u00020\n2\u0006\u0010\u000b\u001a\u00020\nH\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\fJ\u001f\u0010\r\u001a\b\u0012\u0004\u0012\u00020\u000e0\u00032\u0006\u0010\u000f\u001a\u00020\u0010H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\u0011\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\u0012"}, d2 = {"Lcom/example/ptchampion/domain/repository/WorkoutRepository;", "", "getExercises", "Lcom/example/ptchampion/util/Resource;", "", "Lcom/example/ptchampion/domain/model/ExerciseResponse;", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getWorkoutHistory", "Lcom/example/ptchampion/domain/model/PaginatedWorkoutResponse;", "page", "", "pageSize", "(IILkotlin/coroutines/Continuation;)Ljava/lang/Object;", "saveWorkout", "Lcom/example/ptchampion/domain/model/WorkoutResponse;", "request", "Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;", "(Lcom/example/ptchampion/domain/model/SaveWorkoutRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_release"})
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
}