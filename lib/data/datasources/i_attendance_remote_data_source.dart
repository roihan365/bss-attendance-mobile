import 'package:bss_attendance_new/domain/entities/attendance_today.dart';

import '../../domain/entities/attendance_record.dart';

abstract class IAttendanceRemoteDataSource {
  Future<AttendanceRecord> sendCheckIn(AttendanceRecord record);
  Future<AttendanceRecord> sendCheckOut(AttendanceRecord record);
  Future<List<AttendanceRecord>> fetchAllRecords();
  Future<TodayAttendance> fetchTodayAttendance();
}