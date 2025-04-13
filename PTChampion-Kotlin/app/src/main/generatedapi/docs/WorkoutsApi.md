# WorkoutsApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**handleGetWorkouts**](WorkoutsApi.md#handleGetWorkouts) | **GET** workouts | Get workout history for the current user (tracked sessions) |



Get workout history for the current user (tracked sessions)

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(WorkoutsApi::class.java)
val page : kotlin.Int = 56 // kotlin.Int | Page number for pagination
val pageSize : kotlin.Int = 56 // kotlin.Int | Number of items per page

val result : PaginatedWorkoutsResponse = webService.handleGetWorkouts(page, pageSize)
```

### Parameters
| **page** | **kotlin.Int**| Page number for pagination | [optional] [default to 1] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **pageSize** | **kotlin.Int**| Number of items per page | [optional] [default to 20] |

### Return type

[**PaginatedWorkoutsResponse**](PaginatedWorkoutsResponse.md)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

