class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  ApiException({required this.message, this.statusCode, this.errors});

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException({super.message = 'Koneksi internet bermasalah. Periksa jaringan Anda.'});
}

class UnauthorizedException extends ApiException {
  UnauthorizedException({super.message = 'Sesi telah berakhir. Silakan login kembali.'})
      : super(statusCode: 401);
}

class ValidationException extends ApiException {
  ValidationException({required super.message, super.errors}) : super(statusCode: 422);
}

class ServerException extends ApiException {
  ServerException({super.message = 'Terjadi kesalahan pada server backend.'})
      : super(statusCode: 500);
}
