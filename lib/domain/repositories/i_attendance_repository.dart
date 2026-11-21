import '../entities/attendance_record.dart';
import '../entities/today_status.dart';
import '../entities/sync_batch_result.dart';

class LocationData {
  final String latitude;
  final String longitude;
  final String locationName;
  final double? accuracy;
  final bool isMocked;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.accuracy,
    this.isMocked = false,
  });
}

abstract class IAttendanceRepository {
  Future<TodayStatus> getTodayStatus();
  Future<AttendanceRecord> checkIn(String userId);
  Future<AttendanceRecord> checkOut(String userId);
  Future<List<AttendanceRecord>> getAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int? month,
    int? year,
    String? type,
    int? page,
    int? perPage,
  });
  Future<List<AttendanceRecord>> getAllRecords();
  Future<SyncBatchResult> syncBatchOffline();
  Future<LocationData> getCurrentLocation();
  Future<AttendanceRecord?> getCurrentCheckIn();
  Future<bool> isCheckedIn();
  Future<void> saveRecord(AttendanceRecord record);
  Future<void> clearAll();
}
