# LeaderboardApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**handleGetLocalLeaderboard**](LeaderboardApi.md#handleGetLocalLeaderboard) | **GET** leaderboards/local | Get leaderboard filtered by proximity to user location |
| [**leaderboardExerciseTypeGet**](LeaderboardApi.md#leaderboardExerciseTypeGet) | **GET** leaderboard/{exerciseType} | Get leaderboard for a specific exercise type |



Get leaderboard filtered by proximity to user location

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(LeaderboardApi::class.java)
val exerciseId : kotlin.Int = 56 // kotlin.Int | ID of the exercise to filter leaderboard by
val latitude : kotlin.Double = 1.2 // kotlin.Double | User's current latitude
val longitude : kotlin.Double = 1.2 // kotlin.Double | User's current longitude
val radiusMeters : kotlin.Double = 1.2 // kotlin.Double | Search radius in meters

launch(Dispatchers.IO) {
    val result : kotlin.collections.List<HandleGetLocalLeaderboard200ResponseInner> = webService.handleGetLocalLeaderboard(exerciseId, latitude, longitude, radiusMeters)
}
```

### Parameters
| **exerciseId** | **kotlin.Int**| ID of the exercise to filter leaderboard by | |
| **latitude** | **kotlin.Double**| User&#39;s current latitude | |
| **longitude** | **kotlin.Double**| User&#39;s current longitude | |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **radiusMeters** | **kotlin.Double**| Search radius in meters | [optional] [default to 8047.0] |

### Return type

[**kotlin.collections.List&lt;HandleGetLocalLeaderboard200ResponseInner&gt;**](HandleGetLocalLeaderboard200ResponseInner.md)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


Get leaderboard for a specific exercise type

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(LeaderboardApi::class.java)
val exerciseType : kotlin.String = exerciseType_example // kotlin.String | Type of exercise for the leaderboard
val limit : kotlin.Int = 56 // kotlin.Int | Maximum number of leaderboard entries to return

launch(Dispatchers.IO) {
    val result : kotlin.collections.List<LeaderboardResponseInner> = webService.leaderboardExerciseTypeGet(exerciseType, limit)
}
```

### Parameters
| **exerciseType** | **kotlin.String**| Type of exercise for the leaderboard | [enum: pushup, pullup, situp, run] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **limit** | **kotlin.Int**| Maximum number of leaderboard entries to return | [optional] [default to 20] |

### Return type

[**kotlin.collections.List&lt;LeaderboardResponseInner&gt;**](LeaderboardResponseInner.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

