import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for HealthApi
void main() {
  final instance = Openapi().getHealthApi();

  group(HealthApi, () {
    // Health
    //
    // ヘルスチェック
    //
    //Future<JsonObject> healthGet() async
    test('test healthGet', () async {
      // TODO
    });

  });
}
