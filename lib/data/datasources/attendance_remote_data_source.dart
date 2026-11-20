import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../../domain/entities/attendance_record.dart';
import '../models/attendance_model.dart';
import '../models/sync_batch_result_model.dart';
import '../models/today_status_model.dart';

abstract class IAttendanceRemoteDataSourceNew {
  Future<TodayStatusModel> fetchTodayStatus();
  Future<AttendanceModel> sendAttendance(AttendanceRecord record);
  Future<List<AttendanceModel>> fetchAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? month,
    int? year,
    String? type,
    int? page,
    int? perPage,
  });
  Future<SyncBatchResultModel> syncBatchOffline(List<AttendanceRecord> records);
}

class AttendanceRemoteDataSource implements IAttendanceRemoteDataSourceNew {
  final DioClient dioClient;

  AttendanceRemoteDataSource({required this.dioClient});

  @override
  Future<TodayStatusModel> fetchTodayStatus() async {
    final response = await dioClient.get('/attendance/today');
    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => TodayStatusModel.fromJson(data as Map<String, dynamic>),
    );

    if (apiResponse.data == null) {
      throw Exception(apiResponse.formattedErrorMessage);
    }

    return apiResponse.data!;
  }

  @override
  Future<AttendanceModel> sendAttendance(AttendanceRecord record) async {
    final model = AttendanceModel.fromEntity(record);
    final response = await dioClient.post(
      '/attendance/save',
      data: model.toApiSaveJson(),
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => AttendanceModel.fromServerJson(data as Map<String, dynamic>),
    );

    if (apiResponse.data == null) {
      throw Exception(apiResponse.formattedErrorMessage);
    }

    return apiResponse.data!;
  }

  @override
  Future<List<AttendanceModel>> fetchAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? month,
    int? year,
    String? type,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String().split('T').first;
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String().split('T').first;
    if (month != null) queryParams['month'] = month;
    if (year != null) queryParams['year'] = year;
    if (type != null) queryParams['type'] = type;
    if (page != null) queryParams['page'] = page;
    if (perPage != null) queryParams['per_page'] = perPage;

    final response = await dioClient.get(
      '/attendance/history',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final json = response.data as Map<String, dynamic>;
    final dynamic data = json['data'];

    final records = <AttendanceModel>[];

    // Jika Laravel mengembalikan paginasi: data berupa objek { data: [...], current_page: ... }
    if (data is Map<String, dynamic> && data['data'] is List) {
      for (final item in (data['data'] as List)) {
        if (item is Map<String, dynamic>) {
          records.add(AttendanceModel.fromServerJson(item));
        }
      }
      return records;
    }

    // Jika Laravel mengembalikan array list biasa: data berupa list [...]
    if (data is List) {
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          records.add(AttendanceModel.fromServerJson(item));
        }
      }
      return records;
    }

    return records;
  }

  @override
  Future<SyncBatchResultModel> syncBatchOffline(List<AttendanceRecord> records) async {
    final payload = {
      'attendances': records.map((r) => AttendanceModel.fromEntity(r).toApiSyncJson()).toList(),
    };

    final response = await dioClient.post(
      '/attendance/sync-offline',
      data: payload,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => SyncBatchResultModel.fromJson(data as Map<String, dynamic>),
    );

    if (apiResponse.data == null) {
      throw Exception(apiResponse.formattedErrorMessage);
    }

    return apiResponse.data!;
  }
}
