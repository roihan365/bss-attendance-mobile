import '../../domain/entities/attendance_record.dart';

abstract class IAttendanceLocalDataSource {
  Future<List<AttendanceRecord>> loadRecords();
  Future<void> saveRecords(List<AttendanceRecord> records);
}