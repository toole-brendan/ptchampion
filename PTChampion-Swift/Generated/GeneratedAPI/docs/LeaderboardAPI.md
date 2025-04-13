# LeaderboardAPI

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**leaderboardExerciseTypeGet**](LeaderboardAPI.md#leaderboardexercisetypeget) | **GET** /leaderboard/{exerciseType} | Get leaderboard for a specific exercise type


# **leaderboardExerciseTypeGet**
```swift
    open class func leaderboardExerciseTypeGet(exerciseType: ExerciseType_leaderboardExerciseTypeGet, limit: Int? = nil, completion: @escaping (_ data: [LeaderboardResponseInner]?, _ error: Error?) -> Void)
```

Get leaderboard for a specific exercise type

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let exerciseType = "exerciseType_example" // String | Type of exercise for the leaderboard
let limit = 987 // Int | Maximum number of leaderboard entries to return (optional) (default to 20)

// Get leaderboard for a specific exercise type
LeaderboardAPI.leaderboardExerciseTypeGet(exerciseType: exerciseType, limit: limit) { (response, error) in
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
 **exerciseType** | **String** | Type of exercise for the leaderboard | 
 **limit** | **Int** | Maximum number of leaderboard entries to return | [optional] [default to 20]

### Return type

[**[LeaderboardResponseInner]**](LeaderboardResponseInner.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

