import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for CurrentApi
void main() {
  final instance = Openapi().getCurrentApi();

  group(CurrentApi, () {
    // Get Current
    //
    // 現在位置のエリアとセル情報を取得
    //
    //Future<CurrentResponse> getCurrentCurrentGet(num lat, num lon) async
    test('test getCurrentCurrentGet', () async {
      // TODO
    });

  });
}
