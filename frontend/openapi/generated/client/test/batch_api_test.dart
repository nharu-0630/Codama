import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for BatchApi
void main() {
  final instance = Openapi().getBatchApi();

  group(BatchApi, () {
    // Update Prompt
    //
    // 全エリアのプロンプトをバッチ更新
    //
    //Future<UpdatePromptResponse> updatePromptBatchPromptsUpdatePost() async
    test('test updatePromptBatchPromptsUpdatePost', () async {
      // TODO
    });

  });
}
