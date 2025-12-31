import 'package:dio/dio.dart';

class DioClient {
  DioClient({required String baseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          contentType: 'application/json',
        ),
      ) {
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
      ),
    );
  }

  final Dio dio;
}
