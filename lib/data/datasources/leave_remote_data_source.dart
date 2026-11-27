import 'package:dio/dio.dart';
import '../../core/network/api_response.dart';
import '../../core/network/dio_client.dart';
import '../models/leave_request_model.dart';
import '../models/leave_type_model.dart';

abstract class ILeaveRemoteDataSource {
  Future<List<LeaveTypeModel>> fetchLeaveTypes();
  Future<List<LeaveRequestModel>> fetchMyLeaveRequests();
  Future<LeaveRequestModel> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  });
  Future<LeaveRequestModel?> cancelLeaveRequest(int leaveRequestId);
  Future<List<LeaveRequestModel>> fetchPendingApprovals();
  Future<LeaveRequestModel> processApproval({
    required int leaveRequestId,
    required String action,
    String? notes,
  });
}

class LeaveRemoteDataSource implements ILeaveRemoteDataSource {
  final DioClient dioClient;

  LeaveRemoteDataSource({required this.dioClient});

  @override
  Future<List<LeaveTypeModel>> fetchLeaveTypes() async {
    final response = await dioClient.get('/leave/types');
    final json = response.data as Map<String, dynamic>;
    final data = json['data'];

    final types = <LeaveTypeModel>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          types.add(LeaveTypeModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return types;
  }

  @override
  Future<List<LeaveRequestModel>> fetchMyLeaveRequests() async {
    final response = await dioClient.get('/leave/requests');
    return _parseRequestList(response.data as Map<String, dynamic>);
  }

  @override
  Future<LeaveRequestModel> submitLeaveRequest({
    required int leaveTypeId,
    required String startDate,
    required String endDate,
    required String reason,
    String? attachmentPath,
  }) async {
    dynamic payload;
    Options? options;

    if (attachmentPath != null && attachmentPath.isNotEmpty) {
      final fileName = attachmentPath.split(RegExp(r'[/\\]')).last;
      payload = FormData.fromMap({
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
        'attachment': await MultipartFile.fromFile(attachmentPath, filename: fileName),
      });
      options = Options(contentType: Headers.multipartFormDataContentType);
    } else {
      payload = {
        'leave_type_id': leaveTypeId,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      };
    }

    final response = await dioClient.post(
      '/leave/requests',
      data: payload,
      options: options,
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LeaveRequestModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    if (apiResponse.data == null) {
      throw Exception(apiResponse.formattedErrorMessage);
    }

    return apiResponse.data!;
  }

  @override
  Future<LeaveRequestModel?> cancelLeaveRequest(int leaveRequestId) async {
    final response = await dioClient.post('/leave/requests/$leaveRequestId/cancel');
    final json = response.data as Map<String, dynamic>;
    if (json['data'] is Map) {
      return LeaveRequestModel.fromJson(Map<String, dynamic>.from(json['data'] as Map));
    }
    return null;
  }

  @override
  Future<List<LeaveRequestModel>> fetchPendingApprovals() async {
    final response = await dioClient.get('/leave/approvals/pending');
    return _parseRequestList(response.data as Map<String, dynamic>);
  }

  @override
  Future<LeaveRequestModel> processApproval({
    required int leaveRequestId,
    required String action,
    String? notes,
  }) async {
    final response = await dioClient.post(
      '/leave/approvals/$leaveRequestId/process',
      data: {
        'action': action,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );

    final apiResponse = ApiResponse.fromJson(
      response.data as Map<String, dynamic>,
      (data) => LeaveRequestModel.fromJson(Map<String, dynamic>.from(data as Map)),
    );

    if (apiResponse.data == null) {
      throw Exception(apiResponse.formattedErrorMessage);
    }

    return apiResponse.data!;
  }

  List<LeaveRequestModel> _parseRequestList(Map<String, dynamic> json) {
    final data = json['data'];
    final list = <LeaveRequestModel>[];

    if (data is Map && data['data'] is List) {
      for (final item in (data['data'] as List)) {
        if (item is Map) {
          list.add(LeaveRequestModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      return list;
    }

    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          list.add(LeaveRequestModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return list;
  }
}
