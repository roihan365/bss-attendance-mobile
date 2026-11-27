class LeaveType {
  final int id;
  final String name;
  final String code;
  final bool requiresAttachment;
  final int approvalLevels;
  final bool requiresHrApproval;
  final bool isActive;

  const LeaveType({
    required this.id,
    required this.name,
    required this.code,
    this.requiresAttachment = false,
    this.approvalLevels = 1,
    this.requiresHrApproval = false,
    this.isActive = true,
  });
}
