import 'attendance_record.dart';

class TodayStatus {
  final bool checkedIn;
  final bool checkedOut;
  final bool canCheckIn;
  final bool canCheckOut;
  final AttendanceRecord? checkIn;
  final AttendanceRecord? checkOut;

  const TodayStatus({
    required this.checkedIn,
    required this.checkedOut,
    required this.canCheckIn,
    required this.canCheckOut,
    this.checkIn,
    this.checkOut,
  });

  factory TodayStatus.empty() {
    return const TodayStatus(
      checkedIn: false,
      checkedOut: false,
      canCheckIn: true,
      canCheckOut: false,
      checkIn: null,
      checkOut: null,
    );
  }
}
