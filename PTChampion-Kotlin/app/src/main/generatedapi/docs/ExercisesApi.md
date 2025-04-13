# ExercisesApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**exercisesGet**](ExercisesApi.md#exercisesGet) | **GET** exercises | Get exercise history for the current user |
| [**exercisesPost**](ExercisesApi.md#exercisesPost) | **POST** exercises | Log a completed exercise |



Get exercise history for the current user

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(ExercisesApi::class.java)
val page : kotlin.Int = 56 // kotlin.Int | Page number for pagination
val pageSize : kotlin.Int = 56 // kotlin.Int | Number of items per page

val result : PaginatedExerciseHistoryResponse = webService.exercisesGet(page, pageSize)
```

### Parameters
| **page** | **kotlin.Int**| Page number for pagination | [optional] [default to 1] |
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **pageSize** | **kotlin.Int**| Number of items per page | [optional] [default to 20] |

### Return type

[**PaginatedExerciseHistoryResponse**](PaginatedExerciseHistoryResponse.md)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


Log a completed exercise

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(ExercisesApi::class.java)
val logExerciseRequest : LogExerciseRequest =  // LogExerciseRequest | 

val result : LogExerciseResponse = webService.exercisesPost(logExerciseRequest)
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **logExerciseRequest** | [**LogExerciseRequest**](LogExerciseRequest.md)|  | [optional] |

### Return type

[**LogExerciseResponse**](LogExerciseResponse.md)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

