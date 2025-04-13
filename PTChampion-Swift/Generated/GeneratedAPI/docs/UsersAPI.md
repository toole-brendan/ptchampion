# UsersAPI

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**usersMePatch**](UsersAPI.md#usersmepatch) | **PATCH** /users/me | Update current user profile


# **usersMePatch**
```swift
    open class func usersMePatch(updateUserRequest: UpdateUserRequest? = nil, completion: @escaping (_ data: User?, _ error: Error?) -> Void)
```

Update current user profile

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let updateUserRequest = UpdateUserRequest(username: "username_example", displayName: "displayName_example", profilePictureUrl: "profilePictureUrl_example", location: "location_example", latitude: 123, longitude: 123) // UpdateUserRequest |  (optional)

// Update current user profile
UsersAPI.usersMePatch(updateUserRequest: updateUserRequest) { (response, error) in
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
 **updateUserRequest** | [**UpdateUserRequest**](UpdateUserRequest.md) |  | [optional] 

### Return type

[**User**](User.md)

### Authorization

[BearerAuth](../README.md#BearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

