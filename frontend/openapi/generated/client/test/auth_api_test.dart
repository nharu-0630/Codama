import 'package:test/test.dart';
import 'package:openapi/openapi.dart';


/// tests for AuthApi
void main() {
  final instance = Openapi().getAuthApi();

  group(AuthApi, () {
    // Signup
    //
    // 匿名ユーザーとしてサインアップ
    //
    //Future<SignupResponse> signupSignupPost() async
    test('test signupSignupPost', () async {
      // TODO
    });

  });
}
