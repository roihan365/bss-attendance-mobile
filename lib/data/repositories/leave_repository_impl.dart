import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/repositories/i_leave_repository.dart';
import '../datasources/leave_remote_data_source.dart';

class LeaveRepositoryImpl implements ILeaveRepository {
  final ILeaveRemoteDataSource remoteDataSource;

  LeaveRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<LeaveType>> getLeaveTypes() {
    return remoteDataSource.fetchLeaveTypes();
  }

  @override
  Future<List<LeaveRequest>> getMyLeaveRequests() {
    return remoteDataSource.fetchMyLeaveRequests();
  }

  @override
  Future<LeaveRequest> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  }) {
    return remoteDataSource.submitLeaveRequest(
      leaveTypeId: leaveTypeId,
      startDate: startDate,
      endDate: endDate,
      reason: reason,
      attachmentPath: attachmentPath,
    );
  }

  @override
  Future<LeaveRequest?> cancelLeaveRequest(int leaveRequestId) {
    return remoteDataSource.cancelLeaveRequest(leaveRequestId);
  }

  @override
  Future<List<LeaveRequest>> getPendingApprovals() {
    return remoteDataSource.fetchPendingApprovals();
  }

  @override
  Future<LeaveRequest> processApproval({
    required int leaveRequestId,
    required String action,
    String? notes,
  }) {
    return remoteDataSource.processApproval(
      leaveRequestId: leaveRequestId,
      action: action,
      notes: notes,
    );
  }
}
