package org.openapitools.client.apis;

import retrofit2.http.*;
import retrofit2.Call;
import okhttp3.RequestBody;
import com.squareup.moshi.Json;
import org.openapitools.client.models.HandleGetLocalLeaderboard200ResponseInner;
import org.openapitools.client.models.LeaderboardResponseInner;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00004\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\b\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0004\bf\u0018\u00002\u00020\u0001:\u0001\u0013JC\u0010\u0002\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00050\u00040\u00032\b\b\u0001\u0010\u0006\u001a\u00020\u00072\b\b\u0001\u0010\b\u001a\u00020\t2\b\b\u0001\u0010\n\u001a\u00020\t2\n\b\u0003\u0010\u000b\u001a\u0004\u0018\u00010\tH\'\u00a2\u0006\u0002\u0010\fJ/\u0010\r\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u000e0\u00040\u00032\b\b\u0001\u0010\u000f\u001a\u00020\u00102\n\b\u0003\u0010\u0011\u001a\u0004\u0018\u00010\u0007H\'\u00a2\u0006\u0002\u0010\u0012\u00a8\u0006\u0014"}, d2 = {"Lorg/openapitools/client/apis/LeaderboardApi;", "", "handleGetLocalLeaderboard", "Lretrofit2/Call;", "", "Lorg/openapitools/client/models/HandleGetLocalLeaderboard200ResponseInner;", "exerciseId", "", "latitude", "", "longitude", "radiusMeters", "(IDDLjava/lang/Double;)Lretrofit2/Call;", "leaderboardExerciseTypeGet", "Lorg/openapitools/client/models/LeaderboardResponseInner;", "exerciseType", "", "limit", "(Ljava/lang/String;Ljava/lang/Integer;)Lretrofit2/Call;", "ExerciseTypeLeaderboardExerciseTypeGet", "app_release"})
public abstract interface LeaderboardApi {
    
    /**
     * GET leaderboards/local
     * Get leaderboard filtered by proximity to user location
     *
     * Responses:
     * - 200: Local leaderboard retrieved successfully
     * - 400: Missing or invalid required query parameters
     * - 500: Internal Server Error retrieving local leaderboard
     *
     * @param exerciseId ID of the exercise to filter leaderboard by
     * @param latitude User&#39;s current latitude
     * @param longitude User&#39;s current longitude
     * @param radiusMeters Search radius in meters (optional, default to 8047.0)
     * @return [Call]<[kotlin.collections.List<HandleGetLocalLeaderboard200ResponseInner>]>
     */
    @retrofit2.http.GET(value = "leaderboards/local")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<java.util.List<org.openapitools.client.models.HandleGetLocalLeaderboard200ResponseInner>> handleGetLocalLeaderboard(@retrofit2.http.Query(value = "exercise_id")
    int exerciseId, @retrofit2.http.Query(value = "latitude")
    double latitude, @retrofit2.http.Query(value = "longitude")
    double longitude, @retrofit2.http.Query(value = "radius_meters")
    @org.jetbrains.annotations.Nullable
    java.lang.Double radiusMeters);
    
    /**
     * GET leaderboard/{exerciseType}
     * Get leaderboard for a specific exercise type
     *
     * Responses:
     * - 200: Leaderboard retrieved successfully
     * - 400: Invalid exercise type
     * - 500: Internal Server Error
     *
     * @param exerciseType Type of exercise for the leaderboard
     * @param limit Maximum number of leaderboard entries to return (optional, default to 20)
     * @return [Call]<[kotlin.collections.List<LeaderboardResponseInner>]>
     */
    @retrofit2.http.GET(value = "leaderboard/{exerciseType}")
    @org.jetbrains.annotations.NotNull
    public abstract retrofit2.Call<java.util.List<org.openapitools.client.models.LeaderboardResponseInner>> leaderboardExerciseTypeGet(@retrofit2.http.Path(value = "exerciseType")
    @org.jetbrains.annotations.NotNull
    java.lang.String exerciseType, @retrofit2.http.Query(value = "limit")
    @org.jetbrains.annotations.Nullable
    java.lang.Integer limit);
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 3, xi = 48)
    public static final class DefaultImpls {
    }
    
    /**
     * enum for parameter exerciseType
     */
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0000\n\u0002\u0010\u000e\n\u0002\b\b\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u000f\b\u0002\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006j\u0002\b\u0007j\u0002\b\bj\u0002\b\tj\u0002\b\n\u00a8\u0006\u000b"}, d2 = {"Lorg/openapitools/client/apis/LeaderboardApi$ExerciseTypeLeaderboardExerciseTypeGet;", "", "value", "", "(Ljava/lang/String;ILjava/lang/String;)V", "getValue", "()Ljava/lang/String;", "pushup", "pullup", "situp", "run", "app_release"})
    public static enum ExerciseTypeLeaderboardExerciseTypeGet {
        @com.squareup.moshi.Json(name = "pushup")
        /*public static final*/ pushup /* = new pushup(null) */,
        @com.squareup.moshi.Json(name = "pullup")
        /*public static final*/ pullup /* = new pullup(null) */,
        @com.squareup.moshi.Json(name = "situp")
        /*public static final*/ situp /* = new situp(null) */,
        @com.squareup.moshi.Json(name = "run")
        /*public static final*/ run /* = new run(null) */;
        @org.jetbrains.annotations.NotNull
        private final java.lang.String value = null;
        
        ExerciseTypeLeaderboardExerciseTypeGet(java.lang.String value) {
        }
        
        @org.jetbrains.annotations.NotNull
        public final java.lang.String getValue() {
            return null;
        }
        
        @org.jetbrains.annotations.NotNull
        public static kotlin.enums.EnumEntries<org.openapitools.client.apis.LeaderboardApi.ExerciseTypeLeaderboardExerciseTypeGet> getEntries() {
            return null;
        }
    }
}