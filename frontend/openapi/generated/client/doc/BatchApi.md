# openapi.api.BatchApi

## Load the API package
```dart
import 'package:openapi/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**updatePromptBatchPromptsUpdatePost**](BatchApi.md#updatepromptbatchpromptsupdatepost) | **POST** /batch/prompts/update | Update Prompt


# **updatePromptBatchPromptsUpdatePost**
> UpdatePromptResponse updatePromptBatchPromptsUpdatePost()

Update Prompt

全エリアのプロンプトをバッチ更新

### Example
```dart
import 'package:openapi/api.dart';

final api = Openapi().getBatchApi();

try {
    final response = api.updatePromptBatchPromptsUpdatePost();
    print(response);
} catch on DioException (e) {
    print('Exception when calling BatchApi->updatePromptBatchPromptsUpdatePost: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**UpdatePromptResponse**](UpdatePromptResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

