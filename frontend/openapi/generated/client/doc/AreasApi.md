# openapi.api.AreasApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**getAreasAreasGet**](AreasApi.md#getareasareasget) | **GET** /areas | Get Areas


# **getAreasAreasGet**
> BuiltList<APIArea> getAreasAreasGet()

Get Areas

全エリアの一覧を取得

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAreasApi();

try {
    final response = api.getAreasAreasGet();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AreasApi->getAreasAreasGet: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;APIArea&gt;**](APIArea.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

