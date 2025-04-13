package org.openapitools.client.models;

import org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner;
import com.squareup.moshi.Json;
import com.squareup.moshi.JsonClass;

/**
 * Paginated exercise history for user
 *
 * @param items 
 * @param totalCount 
 * @param page 
 * @param pageSize
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000*\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0002\b\u000f\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010\u000e\n\u0000\b\u0086\b\u0018\u00002\u00020\u0001B3\u0012\u000e\b\u0001\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u0012\b\b\u0001\u0010\u0005\u001a\u00020\u0006\u0012\b\b\u0001\u0010\u0007\u001a\u00020\u0006\u0012\b\b\u0001\u0010\b\u001a\u00020\u0006\u00a2\u0006\u0002\u0010\tJ\u000f\u0010\u0010\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003H\u00c6\u0003J\t\u0010\u0011\u001a\u00020\u0006H\u00c6\u0003J\t\u0010\u0012\u001a\u00020\u0006H\u00c6\u0003J\t\u0010\u0013\u001a\u00020\u0006H\u00c6\u0003J7\u0010\u0014\u001a\u00020\u00002\u000e\b\u0003\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\b\b\u0003\u0010\u0005\u001a\u00020\u00062\b\b\u0003\u0010\u0007\u001a\u00020\u00062\b\b\u0003\u0010\b\u001a\u00020\u0006H\u00c6\u0001J\u0013\u0010\u0015\u001a\u00020\u00162\b\u0010\u0017\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010\u0018\u001a\u00020\u0006H\u00d6\u0001J\t\u0010\u0019\u001a\u00020\u001aH\u00d6\u0001R\u0017\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000bR\u0011\u0010\u0007\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u0011\u0010\b\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\rR\u0011\u0010\u0005\u001a\u00020\u0006\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000f\u0010\r\u00a8\u0006\u001b"}, d2 = {"Lorg/openapitools/client/models/PaginatedExerciseHistoryResponse;", "", "items", "", "Lorg/openapitools/client/models/PaginatedExerciseHistoryResponseItemsInner;", "totalCount", "", "page", "pageSize", "(Ljava/util/List;III)V", "getItems", "()Ljava/util/List;", "getPage", "()I", "getPageSize", "getTotalCount", "component1", "component2", "component3", "component4", "copy", "equals", "", "other", "hashCode", "toString", "", "app_release"})
public final class PaginatedExerciseHistoryResponse {
    @org.jetbrains.annotations.NotNull
    private final java.util.List<org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner> items = null;
    private final int totalCount = 0;
    private final int page = 0;
    private final int pageSize = 0;
    
    public PaginatedExerciseHistoryResponse(@com.squareup.moshi.Json(name = "items")
    @org.jetbrains.annotations.NotNull
    java.util.List<org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner> items, @com.squareup.moshi.Json(name = "total_count")
    int totalCount, @com.squareup.moshi.Json(name = "page")
    int page, @com.squareup.moshi.Json(name = "page_size")
    int pageSize) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner> getItems() {
        return null;
    }
    
    public final int getTotalCount() {
        return 0;
    }
    
    public final int getPage() {
        return 0;
    }
    
    public final int getPageSize() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final java.util.List<org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner> component1() {
        return null;
    }
    
    public final int component2() {
        return 0;
    }
    
    public final int component3() {
        return 0;
    }
    
    public final int component4() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull
    public final org.openapitools.client.models.PaginatedExerciseHistoryResponse copy(@com.squareup.moshi.Json(name = "items")
    @org.jetbrains.annotations.NotNull
    java.util.List<org.openapitools.client.models.PaginatedExerciseHistoryResponseItemsInner> items, @com.squareup.moshi.Json(name = "total_count")
    int totalCount, @com.squareup.moshi.Json(name = "page")
    int page, @com.squareup.moshi.Json(name = "page_size")
    int pageSize) {
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