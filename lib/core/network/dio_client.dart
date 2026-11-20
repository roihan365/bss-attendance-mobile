import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_exceptions.dart';

class DioClient {
  late final Dio dio;
  final Future<String?> Function()? getToken;
  final void Function()? onUnauthorized;

  DioClient({this.getToken, this.onUnauthorized}) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (getToken != null) {
            final token = await getToken!();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final statusCode = error.response?.statusCode;

          if (statusCode == 401) {
            onUnauthorized?.call();
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: UnauthorizedException(),
              ),
            );
          }

          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.connectionError) {
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                error: NetworkException(),
              ),
            );
          }

          return handler.next(error);
        },
      ),
    );
  }

  /// Menjalankan request GET
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Menjalankan request POST
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  ApiException _handleError(DioException error) {
    if (error.error is ApiException) {
      return error.error as ApiException;
    }

    final response = error.response;
    if (response != null && response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      final message = data['message']?.toString() ?? 'Terjadi kesalahan';
      final errors = data['errors'];

      if (response.statusCode == 422) {
        return ValidationException(message: message, errors: errors);
      }
      return ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: errors,
      );
    }

    return NetworkException(
      message: error.message ?? 'Tidak dapat terhubung ke server',
    );
  }
}
