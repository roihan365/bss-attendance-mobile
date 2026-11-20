import 'package:bss_attendance_new/domain/entities/attendance_record.dart';

class TodayAttendance {
  final bool checkedIn;
  final bool checkedOut;
  final bool canCheckIn;
  final bool canCheckOut;
  final AttendanceRecord? checkIn;
  final AttendanceRecord? checkOut;

  const TodayAttendance({
    required this.checkedIn,
    required this.checkedOut,
    required this.canCheckIn,
    required this.canCheckOut,
    this.checkIn,
    this.checkOut,
  });
}