# AuthApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**authLoginPost**](AuthApi.md#authLoginPost) | **POST** auth/login | Authenticate a user and get JWT token |
| [**authRegisterPost**](AuthApi.md#authRegisterPost) | **POST** auth/register | Register a new user |



Authenticate a user and get JWT token

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(AuthApi::class.java)
val loginRequest : LoginRequest =  // LoginRequest | 

launch(Dispatchers.IO) {
    val result : LoginResponse = webService.authLoginPost(loginRequest)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **loginRequest** | [**LoginRequest**](LoginRequest.md)|  | [optional] |

### Return type

[**LoginResponse**](LoginResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


Register a new user

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
val webService = apiClient.createWebservice(AuthApi::class.java)
val insertUser : InsertUser =  // InsertUser | 

launch(Dispatchers.IO) {
    val result : User = webService.authRegisterPost(insertUser)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **insertUser** | [**InsertUser**](InsertUser.md)|  | [optional] |

### Return type

[**User**](User.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

