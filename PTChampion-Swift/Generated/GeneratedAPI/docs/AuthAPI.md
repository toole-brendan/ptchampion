# AuthAPI

All URIs are relative to */api/v1*

Method | HTTP request | Description
------------- | ------------- | -------------
[**authLoginPost**](AuthAPI.md#authloginpost) | **POST** /auth/login | Authenticate a user and get JWT token
[**authRegisterPost**](AuthAPI.md#authregisterpost) | **POST** /auth/register | Register a new user


# **authLoginPost**
```swift
    open class func authLoginPost(loginRequest: LoginRequest? = nil, completion: @escaping (_ data: LoginResponse?, _ error: Error?) -> Void)
```

Authenticate a user and get JWT token

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let loginRequest = LoginRequest(username: "username_example", password: "password_example") // LoginRequest |  (optional)

// Authenticate a user and get JWT token
AuthAPI.authLoginPost(loginRequest: loginRequest) { (response, error) in
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
 **loginRequest** | [**LoginRequest**](LoginRequest.md) |  | [optional] 

### Return type

[**LoginResponse**](LoginResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **authRegisterPost**
```swift
    open class func authRegisterPost(insertUser: InsertUser? = nil, completion: @escaping (_ data: User?, _ error: Error?) -> Void)
```

Register a new user

### Example
```swift
// The following code samples are still beta. For any issue, please report via http://github.com/OpenAPITools/openapi-generator/issues/new
import OpenAPIClient

let insertUser = InsertUser(username: "username_example", password: "password_example", displayName: "displayName_example", profilePictureUrl: "profilePictureUrl_example", location: "location_example", latitude: "latitude_example", longitude: "longitude_example") // InsertUser |  (optional)

// Register a new user
AuthAPI.authRegisterPost(insertUser: insertUser) { (response, error) in
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
 **insertUser** | [**InsertUser**](InsertUser.md) |  | [optional] 

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

