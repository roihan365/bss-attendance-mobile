import '../../domain/entities/today_status.dart';
import 'attendance_model.dart';

class TodayStatusModel extends TodayStatus {
  const TodayStatusModel({
    required super.checkedIn,
    required super.checkedOut,
    required super.canCheckIn,
    required super.canCheckOut,
    super.checkIn,
    super.checkOut,
  });

  factory TodayStatusModel.fromJson(Map<String, dynamic> json) {
    return TodayStatusModel(
      checkedIn: json['checked_in'] == true,
      checkedOut: json['checked_out'] == true,
      canCheckIn: json['can_checkin'] == true,
      canCheckOut: json['can_checkout'] == true,
      checkIn: json['checkin'] is Map<String, dynamic>
          ? AttendanceModel.fromServerJson(json['checkin'] as Map<String, dynamic>)
          : null,
      checkOut: json['checkout'] is Map<String, dynamic>
          ? AttendanceModel.fromServerJson(json['checkout'] as Map<String, dynamic>)
          : null,
    );
  }
}
