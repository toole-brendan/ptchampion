package org.openapitools.client.apis;

import retrofit2.http.*;
import retrofit2.Call;
import okhttp3.RequestBody;
import com.squareup.moshi.Json;
import org.openapitools.client.models.SyncRequest;
import org.openapitools.client.models.SyncResponse;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\bf\u0018\u00002\u00020\u0001J\u001a\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\n\b\u0003\u0010\u0005\u001a\u0004\u0018\u00010\u0006H\'\u00a8\u0006\u0007"}, d2 = {"Lorg/openapitools/client/apis/SyncApi;", "", "syncPost", "Lretrofit2/Call;", "Lorg/openapitools/client/models/SyncResponse;", "syncRequest", "Lorg/openapitools/client/models/SyncRequest;", "app_release"})
public abstract interface SyncApi {
    
    /**
     * POST sync
     * Synchronize client data with the server
     *
     * Responses:
     * - 200: Sync successful
     * - 400: Invalid sync request
     * - 401: Unauthorized - missing or invalid token
     * - 500: Internal Server Error during sync
     *
     * @param syncRequest  (optional)
     * @return [Call]<[SyncResponse]>
     */
    @retrofit2.http.POST(value = "sync")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<org.openapitools.client.models.SyncResponse> syncPost(@retrofit2.http.Body
    @org.jetbrains.annotations.Nullable
    org.openapitools.client.models.SyncRequest syncRequest);
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 3, xi = 48)
    public static final class DefaultImpls {
    }
}