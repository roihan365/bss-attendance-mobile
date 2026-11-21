import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/app_logger.dart';
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
          AppLogger.i('DIO', '--> ${options.method} ${options.uri}');
          final isPublicAuth = options.path.contains('/auth/login');
          if (getToken != null && !isPublicAuth) {
            final token = await getToken!();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['X-Authorization'] = 'Bearer $token';
              final preview = token.length > 12 ? '${token.substring(0, 10)}...' : token;
              AppLogger.d('DIO', 'Header: Authorization Bearer $preview');
            } else {
              AppLogger.w('DIO', 'Header: Tidak ada token autentikasi (Bearer null) untuk request terproteksi: ${options.path}');
            }
          }
          if (options.data != null) {
            AppLogger.d('DIO', 'Request Payload: ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.i('DIO', '<-- [${response.statusCode}] ${response.requestOptions.method} ${response.requestOptions.uri}');
          AppLogger.d('DIO', 'Response Body: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          final statusCode = error.response?.statusCode;
          AppLogger.e(
            'DIO',
            '<-- ERROR [${statusCode ?? 'NO_STATUS'}] ${error.requestOptions.method} ${error.requestOptions.uri}: ${error.message}',
            error.response?.data ?? error.error,
          );

          if (statusCode == 401) {
            AppLogger.w('DIO', 'Sesi login telah berakhir atau token tidak valid (401 Unauthorized)');
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
            AppLogger.w('DIO', 'Koneksi jaringan gagal / batas waktu terlampaui (${error.type})');
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
