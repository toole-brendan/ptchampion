# SyncAPI

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**syncPost**](SyncAPI.md#syncpost) | **POST** /sync | Synchronize client data with the server


# **syncPost**
```swift
    open class func syncPost(syncRequest: SyncRequest? = nil, completion: @escaping (_ data: SyncResponse?, _ error: Error?) -> Void)
```

Synchronize client data with the server

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let syncRequest = SyncRequest(userId: 123, deviceId: "deviceId_example", lastSyncTimestamp: Date(), data: SyncRequest_data(userExercises: [SyncRequest_data_userExercises_inner(userId: 123, exerciseId: 123, repetitions: 123, formScore: 123, timeInSeconds: 123, grade: 123, completed: false, metadata: "metadata_example", deviceId: "deviceId_example", syncStatus: "syncStatus_example")], profile: SyncRequest_data_profile(displayName: "displayName_example", profilePictureUrl: "profilePictureUrl_example", location: "location_example"))) // SyncRequest |  (optional)

// Synchronize client data with the server
SyncAPI.syncPost(syncRequest: syncRequest) { (response, error) in
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
 **syncRequest** | [**SyncRequest**](SyncRequest.md) |  | [optional] 

### Return type

[**SyncResponse**](SyncResponse.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

