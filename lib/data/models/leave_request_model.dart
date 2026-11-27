import '../../domain/entities/leave_request.dart';

class LeaveApprovalStepModel extends LeaveApprovalStep {
  const LeaveApprovalStepModel({
    required super.stepLevel,
    required super.approverName,
    super.approverPosition,
    required super.status,
    super.notes,
    super.actedAt,
  });

  factory LeaveApprovalStepModel.fromJson(Map<String, dynamic> json) {
    return LeaveApprovalStepModel(
      stepLevel: _toInt(json['step_level'], fallback: 1),
      approverName: json['approver_name']?.toString() ??
          (json['approver'] is Map ? json['approver']['name']?.toString() : null) ??
          'Atasan',
      approverPosition: json['approver_position']?.toString() ??
          (json['approver'] is Map ? json['approver']['position_title']?.toString() : null),
      status: json['status']?.toString() ?? 'pending',
      notes: json['notes']?.toString(),
      actedAt: json['acted_at'] != null ? DateTime.tryParse(json['acted_at'].toString()) : null,
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class LeaveRequestModel extends LeaveRequest {
  const LeaveRequestModel({
    required super.id,
    required super.leaveTypeId,
    required super.leaveTypeName,
    required super.leaveTypeCode,
    required super.startDate,
    required super.endDate,
    required super.totalDays,
    required super.reason,
    required super.status,
    super.currentStep = 1,
    super.attachmentUrl,
    super.attachmentName,
    super.approvals = const [],
    super.requesterName,
    super.requesterPosition,
    super.requesterDivision,
    super.createdAt,
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    final leaveTypeMap = json['leave_type'] is Map
        ? Map<String, dynamic>.from(json['leave_type'] as Map)
        : null;

    final userMap = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'] as Map)
        : null;

    final divisionMap = userMap != null && userMap['division'] is Map
        ? Map<String, dynamic>.from(userMap['division'] as Map)
        : null;

    final approvals = <LeaveApprovalStepModel>[];
    if (json['approvals'] is List) {
      for (final item in (json['approvals'] as List)) {
        if (item is Map) {
          approvals.add(LeaveApprovalStepModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return LeaveRequestModel(
      id: _toInt(json['id']),
      leaveTypeId: _toInt(leaveTypeMap?['id'] ?? json['leave_type_id']),
      leaveTypeName: leaveTypeMap?['name']?.toString() ?? json['leave_type_name']?.toString() ?? 'Izin',
      leaveTypeCode: leaveTypeMap?['code']?.toString() ?? json['leave_type_code']?.toString() ?? '',
      startDate: _normalizeDate(json['start_date']),
      endDate: _normalizeDate(json['end_date']),
      totalDays: _toInt(json['total_days'], fallback: 1),
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      currentStep: _toInt(json['current_step'], fallback: 1),
      attachmentUrl: json['attachment_url']?.toString(),
      attachmentName: json['attachment_name']?.toString(),
      approvals: approvals,
      requesterName: userMap?['name']?.toString() ?? json['requester_name']?.toString(),
      requesterPosition: userMap?['position_title']?.toString(),
      requesterDivision: divisionMap?['name']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  static String _normalizeDate(dynamic value) {
    if (value == null) return '';
    final str = value.toString();
    if (str.contains('T')) return str.split('T').first;
    if (str.contains(' ')) return str.split(' ').first;
    return str;
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
