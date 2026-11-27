import '../../domain/entities/today_status.dart';
import 'attendance_model.dart';
import 'work_location_model.dart';

class TodayStatusModel extends TodayStatus {
  const TodayStatusModel({
    required super.checkedIn,
    required super.checkedOut,
    super.onLeave = false,
    super.leave,
    required super.canCheckIn,
    required super.canCheckOut,
    super.isFlexibleLocation = false,
    super.workLocations = const [],
    super.checkIn,
    super.checkOut,
  });

  factory TodayStatusModel.fromJson(Map<String, dynamic> json) {
    TodayLeaveSummary? leaveSummary;
    if (json['leave'] is Map) {
      final leaveMap = Map<String, dynamic>.from(json['leave'] as Map);
      final leaveTypeMap = leaveMap['leave_type'] is Map
          ? Map<String, dynamic>.from(leaveMap['leave_type'] as Map)
          : null;
      leaveSummary = TodayLeaveSummary(
        id: int.tryParse(leaveMap['id']?.toString() ?? ''),
        leaveTypeName: leaveTypeMap?['name']?.toString() ?? leaveMap['leave_type_name']?.toString(),
        leaveTypeCode: leaveTypeMap?['code']?.toString() ?? leaveMap['leave_type_code']?.toString(),
        startDate: leaveMap['start_date']?.toString(),
        endDate: leaveMap['end_date']?.toString(),
        reason: leaveMap['reason']?.toString(),
        status: leaveMap['status']?.toString(),
      );
    }

    final workLocations = <WorkLocationModel>[];
    if (json['work_locations'] is List) {
      for (final item in (json['work_locations'] as List)) {
        if (item is Map) {
          workLocations.add(WorkLocationModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return TodayStatusModel(
      checkedIn: json['checked_in'] == true,
      checkedOut: json['checked_out'] == true,
      onLeave: json['on_leave'] == true,
      leave: leaveSummary,
      canCheckIn: json['can_checkin'] == true,
      canCheckOut: json['can_checkout'] == true,
      isFlexibleLocation: json['is_flexible_location'] == true,
      workLocations: workLocations,
      checkIn: json['checkin'] is Map<String, dynamic>
          ? AttendanceModel.fromServerJson(json['checkin'] as Map<String, dynamic>)
          : null,
      checkOut: json['checkout'] is Map<String, dynamic>
          ? AttendanceModel.fromServerJson(json['checkout'] as Map<String, dynamic>)
          : null,
    );
  }
}
