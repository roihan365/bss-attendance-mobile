import 'attendance_record.dart';
import 'work_location.dart';

class TodayLeaveSummary {
  final int? id;
  final String? leaveTypeName;
  final String? leaveTypeCode;
  final String? startDate;
  final String? endDate;
  final String? reason;
  final String? status;

  const TodayLeaveSummary({
    this.id,
    this.leaveTypeName,
    this.leaveTypeCode,
    this.startDate,
    this.endDate,
    this.reason,
    this.status,
  });
}

class TodayStatus {
  final bool checkedIn;
  final bool checkedOut;
  final bool onLeave;
  final TodayLeaveSummary? leave;
  final bool canCheckIn;
  final bool canCheckOut;
  final bool isFlexibleLocation;
  final List<WorkLocation> workLocations;
  final AttendanceRecord? checkIn;
  final AttendanceRecord? checkOut;

  const TodayStatus({
    required this.checkedIn,
    required this.checkedOut,
    this.onLeave = false,
    this.leave,
    required this.canCheckIn,
    required this.canCheckOut,
    this.isFlexibleLocation = false,
    this.workLocations = const [],
    this.checkIn,
    this.checkOut,
  });

  factory TodayStatus.empty() {
    return const TodayStatus(
      checkedIn: false,
      checkedOut: false,
      onLeave: false,
      leave: null,
      canCheckIn: true,
      canCheckOut: false,
      isFlexibleLocation: false,
      workLocations: [],
      checkIn: null,
      checkOut: null,
    );
  }
}
