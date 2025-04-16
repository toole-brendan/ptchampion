# SyncApi

All URIs are relative to */api/v1*

| Method | HTTP request | Description |
| ------------- | ------------- | ------------- |
| [**syncPost**](SyncApi.md#syncPost) | **POST** sync | Synchronize client data with the server |



Synchronize client data with the server

### Example
```kotlin
// Import classes:
//import org.openapitools.client.*
//import org.openapitools.client.infrastructure.*
//import org.openapitools.client.models.*

val apiClient = ApiClient()
apiClient.setBearerToken("TOKEN")
val webService = apiClient.createWebservice(SyncApi::class.java)
val syncRequest : SyncRequest =  // SyncRequest | 

launch(Dispatchers.IO) {
    val result : SyncResponse = webService.syncPost(syncRequest)
}
```

### Parameters
| Name | Type | Description  | Notes |
| ------------- | ------------- | ------------- | ------------- |
| **syncRequest** | [**SyncRequest**](SyncRequest.md)|  | [optional] |

### Return type

[**SyncResponse**](SyncResponse.md)

### Authorization


Configure BearerAuth:
    ApiClient().setBearerToken("TOKEN")

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

