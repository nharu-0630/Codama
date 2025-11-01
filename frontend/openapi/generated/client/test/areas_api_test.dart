import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for AreasApi
void main() {
  final instance = Openapi().getAreasApi();

  group(AreasApi, () {
    // Get Areas
    //
    // 全エリアの一覧を取得
    //
    //Future<BuiltList<APIArea>> getAreasAreasGet() async
    test('test getAreasAreasGet', () async {
      // TODO
    });

  });
}
