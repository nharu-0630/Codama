# openapi.api.CurrentApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getCurrentCurrentGet**](CurrentApi.md#getcurrentcurrentget) | **GET** /current | Get Current


# **getCurrentCurrentGet**
> CurrentResponse getCurrentCurrentGet(lat, lon)

Get Current

現在位置のエリアとセル情報を取得

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getCurrentApi();
final num lat = 8.14; // num | 
final num lon = 8.14; // num | 

try {
    final response = api.getCurrentCurrentGet(lat, lon);
    print(response);
} catch on DioException (e) {
    print('Exception when calling CurrentApi->getCurrentCurrentGet: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **lat** | **num**|  | 
 **lon** | **num**|  | 

### Return type

[**CurrentResponse**](CurrentResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

