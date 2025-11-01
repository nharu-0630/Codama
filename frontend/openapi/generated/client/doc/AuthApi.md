# openapi.api.AuthApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**signupSignupPost**](AuthApi.md#signupsignuppost) | **POST** /signup | Signup


# **signupSignupPost**
> SignupResponse signupSignupPost()

Signup

匿名ユーザーとしてサインアップ

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getAuthApi();

try {
    final response = api.signupSignupPost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling AuthApi->signupSignupPost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**SignupResponse**](SignupResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

