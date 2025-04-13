# ExercisesAPI

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**exercisesGet**](ExercisesAPI.md#exercisesget) | **GET** /exercises | Get exercise history for the current user
[**exercisesPost**](ExercisesAPI.md#exercisespost) | **POST** /exercises | Log a completed exercise


# **exercisesGet**
```swift
    open class func exercisesGet(page: Int? = nil, pageSize: Int? = nil, completion: @escaping (_ data: PaginatedExerciseHistoryResponse?, _ error: Error?) -> Void)
```

Get exercise history for the current user

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let page = 987 // Int | Page number for pagination (optional) (default to 1)
let pageSize = 987 // Int | Number of items per page (optional) (default to 20)

// Get exercise history for the current user
ExercisesAPI.exercisesGet(page: page, pageSize: pageSize) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **page** | **Int** | Page number for pagination | [optional] [default to 1]
 **pageSize** | **Int** | Number of items per page | [optional] [default to 20]

### Return type

[**PaginatedExerciseHistoryResponse**](PaginatedExerciseHistoryResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **exercisesPost**
```swift
    open class func exercisesPost(logExerciseRequest: LogExerciseRequest? = nil, completion: @escaping (_ data: LogExerciseResponse?, _ error: Error?) -> Void)
```

Log a completed exercise

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let logExerciseRequest = LogExerciseRequest(exerciseId: 123, reps: 123, duration: 123, distance: 123, notes: "notes_example") // LogExerciseRequest |  (optional)

// Log a completed exercise
ExercisesAPI.exercisesPost(logExerciseRequest: logExerciseRequest) { (response, error) in
    guard error == nil else {
        print(error)
        return
    }

    if (response) {
        dump(response)
    }
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **logExerciseRequest** | [**LogExerciseRequest**](LogExerciseRequest.md) |  | [optional] 

### Return type

[**LogExerciseResponse**](LogExerciseResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

