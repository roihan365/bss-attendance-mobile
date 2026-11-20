import '../entities/attendance_record.dart';

abstract class IAttendanceRepository {
  Future<List<AttendanceRecord>> getAllRecords();
  Future<void> saveRecord(AttendanceRecord record);
  Future<AttendanceRecord?> getCurrentCheckIn();
  Future<bool> isCheckedIn();
  Future<void> clearAll();

  // Additional methods for use cases
  Future<AttendanceRecord> checkIn(String userId);
  Future<AttendanceRecord> checkOut(String userId);
  Future<LocationData> getCurrentLocation();
  Future<void> syncAllPending();
}

// Data class for location (used in repository)
class LocationData {
  final String latitude;
  final String longitude;
  final String locationName;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });
}