class LeaveApprovalStep {
  final int stepLevel;
  final String approverName;
  final String? approverPosition;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? notes;
  final DateTime? actedAt;

  const LeaveApprovalStep({
    required this.stepLevel,
    required this.approverName,
    this.approverPosition,
    required this.status,
    this.notes,
    this.actedAt,
  });
}

class LeaveRequest {
  final int id;
  final int leaveTypeId;
  final String leaveTypeName;
  final String leaveTypeCode;
  final String startDate;
  final String endDate;
  final int totalDays;
  final String reason;
  final String status; // 'pending' | 'approved' | 'rejected' | 'cancelled'
  final int currentStep;
  final String? attachmentUrl;
  final String? attachmentName;
  final List<LeaveApprovalStep> approvals;
  final String? requesterId;
  final String? requesterName;
  final String? requesterEmail;
  final String? requesterPosition;
  final String? requesterDivision;
  final DateTime? createdAt;

  const LeaveRequest({
    required this.id,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.leaveTypeCode,
    required this.startDate,
    required this.endDate,
    required this.totalDays,
    required this.reason,
    required this.status,
    this.currentStep = 1,
    this.attachmentUrl,
    this.attachmentName,
    this.approvals = const [],
    this.requesterId,
    this.requesterName,
    this.requesterEmail,
    this.requesterPosition,
    this.requesterDivision,
    this.createdAt,
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
}
