class LeaveTypeApprovalStep {
  final int stepLevel;
  final String approverType; // 'direct_supervisor' | 'indirect_supervisor' | 'hr' | 'position' | 'employee'
  final int? positionId;
  final int? employeeId;

  const LeaveTypeApprovalStep({
    required this.stepLevel,
    required this.approverType,
    this.positionId,
    this.employeeId,
  });

  String get approverTypeLabel {
    switch (approverType) {
      case 'direct_supervisor':
        return 'Atasan Langsung';
      case 'indirect_supervisor':
        return 'Atasan Tingkat 2';
      case 'hr':
        return 'HRD';
      case 'position':
        return 'Pejabat Jabatan';
      case 'employee':
        return 'Approver Khusus';
      default:
        return approverType;
    }
  }
}

class LeaveType {
  final int id;
  final String name;
  final String code;
  final bool requiresAttachment;
  final int approvalLevels;
  final bool requiresHrApproval;
  final bool isActive;
  final List<LeaveTypeApprovalStep> approvalSteps;

  const LeaveType({
    required this.id,
    required this.name,
    required this.code,
    this.requiresAttachment = false,
    this.approvalLevels = 1,
    this.requiresHrApproval = false,
    this.isActive = true,
    this.approvalSteps = const [],
  });
}
