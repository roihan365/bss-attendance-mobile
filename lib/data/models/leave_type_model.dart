import '../../domain/entities/leave_type.dart';

class LeaveTypeApprovalStepModel extends LeaveTypeApprovalStep {
  const LeaveTypeApprovalStepModel({
    required super.stepLevel,
    required super.approverType,
    super.positionId,
    super.employeeId,
  });

  factory LeaveTypeApprovalStepModel.fromJson(Map<String, dynamic> json) {
    return LeaveTypeApprovalStepModel(
      stepLevel: _toInt(json['step_level'], fallback: 1),
      approverType: json['approver_type']?.toString() ?? 'direct_supervisor',
      positionId: _toNullableInt(json['position_id']),
      employeeId: _toNullableInt(json['employee_id']),
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _toNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

class LeaveTypeModel extends LeaveType {
  const LeaveTypeModel({
    required super.id,
    required super.name,
    required super.code,
    super.requiresAttachment = false,
    super.approvalLevels = 1,
    super.requiresHrApproval = false,
    super.isActive = true,
    super.approvalSteps = const [],
  });

  factory LeaveTypeModel.fromJson(Map<String, dynamic> json) {
    final steps = <LeaveTypeApprovalStepModel>[];
    if (json['approval_steps'] is List) {
      for (final item in (json['approval_steps'] as List)) {
        if (item is Map) {
          steps.add(LeaveTypeApprovalStepModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      steps.sort((a, b) => a.stepLevel.compareTo(b.stepLevel));
    }

    return LeaveTypeModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      requiresAttachment: json['requires_attachment'] == true || json['requires_attachment'] == 1,
      approvalLevels: _toInt(json['approval_levels'], fallback: 1),
      requiresHrApproval: json['requires_hr_approval'] == true || json['requires_hr_approval'] == 1,
      isActive: json['is_active'] == null ? true : (json['is_active'] == true || json['is_active'] == 1),
      approvalSteps: steps,
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
