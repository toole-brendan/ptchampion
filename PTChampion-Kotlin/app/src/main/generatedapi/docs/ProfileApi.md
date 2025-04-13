# ProfileApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**handleUpdateUserLocation**](ProfileApi.md#handleUpdateUserLocation) | **PUT** profile/location | Update current user&#39;s last known location |



Update current user&#39;s last known location

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(ProfileApi::class.java)
val handleUpdateUserLocationRequest : HandleUpdateUserLocationRequest =  // HandleUpdateUserLocationRequest | 

webService.handleUpdateUserLocation(handleUpdateUserLocationRequest)
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **handleUpdateUserLocationRequest** | [**HandleUpdateUserLocationRequest**](HandleUpdateUserLocationRequest.md)|  | |

### Return type

null (empty response body)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined

