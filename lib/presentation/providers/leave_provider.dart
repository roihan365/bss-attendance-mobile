import 'package:flutter/material.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/leave_request.dart';
import '../../domain/entities/leave_type.dart';
import '../../domain/repositories/i_leave_repository.dart';
import 'auth_provider.dart';

class LeaveProvider extends ChangeNotifier {
  final ILeaveRepository leaveRepository;
  AuthProvider? authProvider;

  List<LeaveType> _leaveTypes = [];
  List<LeaveRequest> _myRequests = [];
  List<LeaveRequest> _pendingApprovals = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<LeaveType> get leaveTypes => _leaveTypes;
  List<LeaveRequest> get myRequests => _myRequests;
  List<LeaveRequest> get pendingApprovals => _pendingApprovals;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  bool get canApproveLeave => authProvider?.currentUser?.canApproveLeave ?? false;
  int get pendingApprovalCount => _pendingApprovals.length;

  LeaveProvider({
    required this.leaveRepository,
    this.authProvider,
  }) {
    if (authProvider != null && authProvider!.isLoggedIn) {
      loadInitialData();
    }
  }

  void updateAuth(AuthProvider? newAuthProvider) {
    final wasLoggedIn = authProvider?.isLoggedIn ?? false;
    authProvider = newAuthProvider;
    final isNowLoggedIn = authProvider?.isLoggedIn ?? false;

    if (isNowLoggedIn && !wasLoggedIn) {
      loadInitialData();
    } else if (!isNowLoggedIn) {
      _leaveTypes = [];
      _myRequests = [];
      _pendingApprovals = [];
      notifyListeners();
    }
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final futures = <Future<void>>[
        _fetchLeaveTypesSafe(),
        _fetchMyRequestsSafe(),
      ];
      if (canApproveLeave) {
        futures.add(_fetchPendingApprovalsSafe());
      }
      await Future.wait(futures);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchLeaveTypesSafe() async {
    try {
      _leaveTypes = await leaveRepository.getLeaveTypes();
    } catch (e) {
      AppLogger.w('LEAVE', 'Gagal memuat jenis izin: $e');
    }
  }

  Future<void> _fetchMyRequestsSafe() async {
    try {
      _myRequests = await leaveRepository.getMyLeaveRequests();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      AppLogger.w('LEAVE', 'Gagal memuat riwayat izin: $e');
    }
  }

  Future<void> _fetchPendingApprovalsSafe() async {
    try {
      _pendingApprovals = await leaveRepository.getPendingApprovals();
    } catch (e) {
      AppLogger.w('LEAVE', 'Gagal memuat antrean persetujuan: $e');
    }
  }

  Future<void> refreshAll() async {
    await loadInitialData();
  }

  Future<LeaveRequest> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await leaveRepository.submitLeaveRequest(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        reason: reason,
        attachmentPath: attachmentPath,
      );
      await _fetchMyRequestsSafe();
      return created;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> cancelLeaveRequest(int leaveRequestId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await leaveRepository.cancelLeaveRequest(leaveRequestId);
      await _fetchMyRequestsSafe();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<LeaveRequest> processApproval({
    required int leaveRequestId,
    required String action,
    String? notes,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await leaveRepository.processApproval(
        leaveRequestId: leaveRequestId,
        action: action,
        notes: notes,
      );
      await _fetchPendingApprovalsSafe();
      return updated;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
