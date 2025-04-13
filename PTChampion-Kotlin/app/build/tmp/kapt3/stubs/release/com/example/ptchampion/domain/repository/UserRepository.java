package com.example.ptchampion.domain.repository;

import com.example.ptchampion.domain.model.User;
import com.example.ptchampion.domain.model.UserProfile;
import com.example.ptchampion.util.Resource;
import kotlinx.coroutines.flow.Flow;
import com.example.ptchampion.domain.model.UpdateLocationRequest;

/**
 * Repository interface for user-related data operations.
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000(\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0002\bf\u0018\u00002\u00020\u0001J\u0014\u0010\u0002\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\u00040\u0003H&J\u0017\u0010\u0006\u001a\b\u0012\u0004\u0012\u00020\u00070\u0004H\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\bJ\u001f\u0010\t\u001a\b\u0012\u0004\u0012\u00020\u00070\u00042\u0006\u0010\n\u001a\u00020\u000bH\u00a6@\u00f8\u0001\u0000\u00a2\u0006\u0002\u0010\f\u0082\u0002\u0004\n\u0002\b\u0019\u00a8\u0006\r"}, d2 = {"Lcom/example/ptchampion/domain/repository/UserRepository;", "", "getUserProfileFlow", "Lkotlinx/coroutines/flow/Flow;", "Lcom/example/ptchampion/util/Resource;", "Lcom/example/ptchampion/domain/model/UserProfile;", "refreshUserProfile", "", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "updateUserLocation", "request", "Lcom/example/ptchampion/domain/model/UpdateLocationRequest;", "(Lcom/example/ptchampion/domain/model/UpdateLocationRequest;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_release"})
public abstract interface UserRepository {
    
    @org.jetbrains.annotations.NotNull
    public abstract kotlinx.coroutines.flow.Flow<com.example.ptchampion.util.Resource<com.example.ptchampion.domain.model.UserProfile>> getUserProfileFlow();
    
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object refreshUserProfile(@org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<kotlin.Unit>> $completion);
    
    /**
     * Updates the user's last known location on the backend.
     *
     * @param request The location data to update.
     * @return A Resource indicating success or failure.
     */
    @org.jetbrains.annotations.Nullable
    public abstract java.lang.Object updateUserLocation(@org.jetbrains.annotations.NotNull
    com.example.ptchampion.domain.model.UpdateLocationRequest request, @org.jetbrains.annotations.NotNull
    kotlin.coroutines.Continuation<? super com.example.ptchampion.util.Resource<kotlin.Unit>> $completion);
}