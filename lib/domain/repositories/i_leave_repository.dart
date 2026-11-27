import '../entities/leave_request.dart';
import '../entities/leave_type.dart';

abstract class ILeaveRepository {
  Future<List<LeaveType>> getLeaveTypes();
  Future<List<LeaveRequest>> getMyLeaveRequests();
  Future<LeaveRequest> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  });
  Future<LeaveRequest?> cancelLeaveRequest(int leaveRequestId);
  Future<List<LeaveRequest>> getPendingApprovals();
  Future<LeaveRequest> processApproval({
    required int leaveRequestId,
    required String action,
    String? notes,
  });
}
