import 'package:codama/core/constants/config.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:openapi/openapi.dart';

class OpenApiFactory {
  OpenApiFactory();

  Openapi build({required String baseUrl, String? accessToken}) {
    final BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Config.timeout,
      receiveTimeout: Config.timeout,
      headers: <String, String>{
        // 'Content-Type': 'application/json',
        'User-Agent': Config.userAgent,
      },
    );

    final dio = Dio(options);
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
    if (accessToken != null) {
      dio.interceptors.add(_AuthInterceptor(accessToken));
    }
    return Openapi(dio: dio);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this.token);

  String token;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Authorization'] = 'Bearer $token';
    return super.onRequest(options, handler);
  }
}
