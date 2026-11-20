class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final dynamic errors;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, [
    T Function(dynamic data)? fromJsonT,
  ]) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      errors: json['errors'],
    );
  }

  /// Mengekstrak seluruh pesan error dari field Laravel validation
  String get formattedErrorMessage {
    if (errors != null) {
      if (errors is Map && (errors as Map).isNotEmpty) {
        final messages = <String>[];
        (errors as Map).forEach((key, value) {
          if (value is List) {
            messages.addAll(value.map((e) => e.toString()));
          } else if (value != null) {
            messages.add(value.toString());
          }
        });
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      } else if (errors is List && (errors as List).isNotEmpty) {
        return (errors as List).map((e) => e.toString()).join('\n');
      } else if (errors is String && (errors as String).isNotEmpty) {
        return errors as String;
      }
    }
    return message.isNotEmpty ? message : 'Terjadi kesalahan pada server';
  }
}
