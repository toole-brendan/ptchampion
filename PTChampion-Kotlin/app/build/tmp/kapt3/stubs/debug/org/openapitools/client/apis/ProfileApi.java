package org.openapitools.client.apis;

import retrofit2.http.*;
import retrofit2.Call;
import okhttp3.RequestBody;
import com.squareup.moshi.Json;
import org.openapitools.client.models.HandleUpdateUserLocationRequest;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u001a\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\bf\u0018\u00002\u00020\u0001J\u0018\u0010\u0002\u001a\b\u0012\u0004\u0012\u00020\u00040\u00032\b\b\u0001\u0010\u0005\u001a\u00020\u0006H\'\u00a8\u0006\u0007"}, d2 = {"Lorg/openapitools/client/apis/ProfileApi;", "", "handleUpdateUserLocation", "Lretrofit2/Call;", "", "handleUpdateUserLocationRequest", "Lorg/openapitools/client/models/HandleUpdateUserLocationRequest;", "app_debug"})
public abstract interface ProfileApi {
    
    /**
     * PUT profile/location
     * Update current user&#39;s last known location
     *
     * Responses:
     * - 200: Location updated successfully
     * - 400: Invalid input (latitude/longitude format incorrect)
     * - 401: Unauthorized - missing or invalid token
     * - 500: Internal Server Error updating location
     *
     * @param handleUpdateUserLocationRequest 
     * @return [Call]<[Unit]>
     */
    @retrofit2.http.PUT(value = "profile/location")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<kotlin.Unit> handleUpdateUserLocation(@retrofit2.http.Body
    @org.jetbrains.annotations.NotNull
    org.openapitools.client.models.HandleUpdateUserLocationRequest handleUpdateUserLocationRequest);
}