# openapi.api.PostsApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**createPostPostsPost**](PostsApi.md#createpostpostspost) | **POST** /posts | Create Post
[**getMyPostsPostsMeGet**](PostsApi.md#getmypostspostsmeget) | **GET** /posts/me | Get My Posts
[**getPostsPostsGet**](PostsApi.md#getpostspostsget) | **GET** /posts | Get Posts


# **createPostPostsPost**
> CreatePostResponse createPostPostsPost(authorization, createPostRequest)

Create Post

新しい投稿を作成

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getPostsApi();
final String authorization = authorization_example; // String | 
final CreatePostRequest createPostRequest = ; // CreatePostRequest | 

try {
    final response = api.createPostPostsPost(authorization, createPostRequest);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PostsApi->createPostPostsPost: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authorization** | **String**|  | 
 **createPostRequest** | [**CreatePostRequest**](CreatePostRequest.md)|  | 

### Return type

[**CreatePostResponse**](CreatePostResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getMyPostsPostsMeGet**
> PostsResponse getMyPostsPostsMeGet(authorization)

Get My Posts

自分の投稿一覧を取得

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getPostsApi();
final String authorization = authorization_example; // String | 

try {
    final response = api.getMyPostsPostsMeGet(authorization);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PostsApi->getMyPostsPostsMeGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **authorization** | **String**|  | 

### Return type

[**PostsResponse**](PostsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **getPostsPostsGet**
> PostsResponse getPostsPostsGet(lat, lon, authorization)

Get Posts

現在位置の投稿一覧を取得

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getPostsApi();
final num lat = 8.14; // num | 
final num lon = 8.14; // num | 
final String authorization = authorization_example; // String | 

try {
    final response = api.getPostsPostsGet(lat, lon, authorization);
    print(response);
} catch on DioException (e) {
    print('Exception when calling PostsApi->getPostsPostsGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **lat** | **num**|  | 
 **lon** | **num**|  | 
 **authorization** | **String**|  | 

### Return type

[**PostsResponse**](PostsResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

