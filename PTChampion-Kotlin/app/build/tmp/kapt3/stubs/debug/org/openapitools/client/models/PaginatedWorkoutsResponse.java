package org.openapitools.client.models;

import org.openapitools.client.models.WorkoutResponse;
import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Paginated list of workout sessions
 *
 * @param workouts 
 * @param totalCount 
 * @param page 
 * @param pageSize 
 * @param totalPages
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00000\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\t\n\u0000\n\u0002\u0010\b\n\u0002\b\u0012\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B=\u0012\u000e\b\u0001\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0006\u0012\b\b\u0001\u0010\u0007\u001a\u00020\b\u0012\b\b\u0001\u0010\t\u001a\u00020\b\u0012\b\b\u0001\u0010\n\u001a\u00020\b\u00a2\u0006\u0002\u0010\u000bJ\u000f\u0010\u0014\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\t\u0010\u0015\u001a\u00020\u0006H\u00c6\u0003J\t\u0010\u0016\u001a\u00020\bH\u00c6\u0003J\t\u0010\u0017\u001a\u00020\bH\u00c6\u0003J\t\u0010\u0018\u001a\u00020\bH\u00c6\u0003JA\u0010\u0019\u001a\u00020\u00002\u000e\b\u0003\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\b\b\u0003\u0010\u0005\u001a\u00020\u00062\b\b\u0003\u0010\u0007\u001a\u00020\b2\b\b\u0003\u0010\t\u001a\u00020\b2\b\b\u0003\u0010\n\u001a\u00020\bH\u00c6\u0001J\u0013\u0010\u001a\u001a\u00020\u001b2\b\u0010\u001c\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u001d\u001a\u00020\bH\u00d6\u0001J\t\u0010\u001e\u001a\u00020\u001fH\u00d6\u0001R\u0011\u0010\u0007\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0011\u0010\t\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\rR\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\u0010R\u0011\u0010\n\u001a\u00020\b\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0011\u0010\rR\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0013\u00a8\u0006 "}, d2 = {"Lorg/openapitools/client/models/PaginatedWorkoutsResponse;", "", "workouts", "", "Lorg/openapitools/client/models/WorkoutResponse;", "totalCount", "", "page", "", "pageSize", "totalPages", "(Ljava/util/List;JIII)V", "getPage", "()I", "getPageSize", "getTotalCount", "()J", "getTotalPages", "getWorkouts", "()Ljava/util/List;", "component1", "component2", "component3", "component4", "component5", "copy", "equals", "", "other", "hashCode", "toString", "", "app_debug"})
public final class PaginatedWorkoutsResponse {
    @org.jetbrains.annotations.NotNull
    private final java.util.List<org.openapitools.client.models.WorkoutResponse> workouts = null;
    private final long totalCount = 0L;
    private final int page = 0;
    private final int pageSize = 0;
    private final int totalPages = 0;
    
    public PaginatedWorkoutsResponse(@com.squareup.moshi.Json(name = "workouts")
    @org.jetbrains.annotations.NotNull
    java.util.List<org.openapitools.client.models.WorkoutResponse> workouts, @com.squareup.moshi.Json(name = "totalCount")
    long totalCount, @com.squareup.moshi.Json(name = "page")
    int page, @com.squareup.moshi.Json(name = "pageSize")
    int pageSize, @com.squareup.moshi.Json(name = "totalPages")
    int totalPages) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<org.openapitools.client.models.WorkoutResponse> getWorkouts() {
        return null;
    }
    
    public final long getTotalCount() {
        return 0L;
    }
    
    public final int getPage() {
        return 0;
    }
    
    public final int getPageSize() {
        return 0;
    }
    
    public final int getTotalPages() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<org.openapitools.client.models.WorkoutResponse> component1() {
        return null;
    }
    
    public final long component2() {
        return 0L;
    }
    
    public final int component3() {
        return 0;
    }
    
    public final int component4() {
        return 0;
    }
    
    public final int component5() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.PaginatedWorkoutsResponse copy(@com.squareup.moshi.Json(name = "workouts")
    @org.jetbrains.annotations.NotNull
    java.util.List<org.openapitools.client.models.WorkoutResponse> workouts, @com.squareup.moshi.Json(name = "totalCount")
    long totalCount, @com.squareup.moshi.Json(name = "page")
    int page, @com.squareup.moshi.Json(name = "pageSize")
    int pageSize, @com.squareup.moshi.Json(name = "totalPages")
    int totalPages) {
        return null;
    }
    
    @java.lang.Override
    public boolean equals(@org.jetbrains.annotations.Nullable
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override
    @org.jetbrains.annotations.NotNull
    public java.lang.String toString() {
        return null;
    }
}