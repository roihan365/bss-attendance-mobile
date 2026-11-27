import '../../domain/entities/leave_type.dart';

class LeaveTypeModel extends LeaveType {
  const LeaveTypeModel({
    required super.id,
    required super.name,
    required super.code,
    super.requiresAttachment = false,
    super.approvalLevels = 1,
    super.requiresHrApproval = false,
    super.isActive = true,
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      requiresAttachment: json['requires_attachment'] == true || json['requires_attachment'] == 1,
      approvalLevels: _toInt(json['approval_levels'], fallback: 1),
      requiresHrApproval: json['requires_hr_approval'] == true || json['requires_hr_approval'] == 1,
      isActive: json['is_active'] == null ? true : (json['is_active'] == true || json['is_active'] == 1),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
