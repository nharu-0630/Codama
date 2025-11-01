import 'package:codama/core/constants/config.dart';
import 'package:codama/core/services/api_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:openapi/openapi.dart';

class OpenApiFactory {
  ApiService? apiService;
  
  OpenApiFactory({this.apiService});

  Openapi build({required String baseUrl, String? accessToken}) {
    final BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Config.timeout,
      receiveTimeout: Config.timeout,
      headers: <String, String>{
        'Content-Type': 'application/json',
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
    if (apiService != null) {
      dio.interceptors.add(_ErrorInterceptor(apiService!));
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

class _ErrorInterceptor extends Interceptor {
  _ErrorInterceptor(this.apiService);

  final ApiService apiService;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      apiService.signOut();
    }
    handler.next(err);
  }
}
