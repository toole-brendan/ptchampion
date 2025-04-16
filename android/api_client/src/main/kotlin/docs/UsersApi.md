# UsersApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**usersMePatch**](UsersApi.md#usersMePatch) | **PATCH** users/me | Update current user profile |



Update current user profile

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(UsersApi::class.java)
val updateUserRequest : UpdateUserRequest =  // UpdateUserRequest | 

launch(Dispatchers.IO) {
    val result : User = webService.usersMePatch(updateUserRequest)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **updateUserRequest** | [**UpdateUserRequest**](UpdateUserRequest.md)|  | [optional] |

### Return type

[**User**](User.md)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

