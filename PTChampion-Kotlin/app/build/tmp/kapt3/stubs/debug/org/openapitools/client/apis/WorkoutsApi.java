package org.openapitools.client.apis;

import retrofit2.http.*;
import retrofit2.Call;
import okhttp3.RequestBody;
import com.squareup.moshi.Json;
import org.openapitools.client.models.PaginatedWorkoutsResponse;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001c\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\bf\u0018\u00002\u00020\u0001J+\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u00062\n\b\u0003\u0010\u0007\u001a\u0004\u0018\u00010\u0006H\'\u00a2\u0006\u0002\u0010\b\u00a8\u0006\t"}, d2 = {"Lorg/openapitools/client/apis/WorkoutsApi;", "", "handleGetWorkouts", "Lretrofit2/Call;", "Lorg/openapitools/client/models/PaginatedWorkoutsResponse;", "page", "", "pageSize", "(Ljava/lang/Integer;Ljava/lang/Integer;)Lretrofit2/Call;", "app_debug"})
public abstract interface WorkoutsApi {
    
    /**
     * GET workouts
     * Get workout history for the current user (tracked sessions)
     *
     * Responses:
     * - 200: Workout history retrieved successfully
     * - 401: Unauthorized - missing or invalid token
     * - 500: Internal Server Error
     *
     * @param page Page number for pagination (optional, default to 1)
     * @param pageSize Number of items per page (optional, default to 20)
     * @return [Call]<[PaginatedWorkoutsResponse]>
     */
    @retrofit2.http.GET(value = "workouts")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<org.openapitools.client.models.PaginatedWorkoutsResponse> handleGetWorkouts(@retrofit2.http.Query(value = "page")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer page, @retrofit2.http.Query(value = "pageSize")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer pageSize);
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 3, xi = 48)
    public static final class DefaultImpls {
    }
}