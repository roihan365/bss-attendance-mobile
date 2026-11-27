import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/data/models/leave_request_model.dart';
import 'package:bss_attendance_new/data/models/leave_type_model.dart';
import 'package:bss_attendance_new/data/models/today_status_model.dart';
import 'package:bss_attendance_new/data/models/user_model.dart';

void main() {
  group('New API Models Tests', () {
    test('UserModel parses division, supervisor, work_locations, roles, permissions', () {
      final json = {
        'token': '1|laravel_sanctum_token',
        'user': {
          'id': 4,
          'name': 'Roy Karyawan IT',
          'email': 'karyawan.it@bss.com',
          'position_title': 'Staff IT Support',
          'is_flexible_location': false,
          'is_approver': true,
          'division': {
            'id': 1,
            'name': 'Teknologi Informasi & Sistem',
            'code': 'IT',
          },
          'supervisor': {
            'id': 2,
            'name': 'Admin Divisi IT',
            'position_title': 'Kepala Divisi IT',
          },
          'work_locations': [
            {
              'id': 1,
              'name': 'Kantor Pusat BSS',
              'code': 'HO-JKT',
              'address': 'Jl. Jend. Sudirman',
              'latitude': -6.224694,
              'longitude': 106.807785,
              'radius_meters': 150,
            },
          ],
          'roles': ['admin'],
          'permissions': ['attendance-mobile', 'submit-leave', 'approve-leave'],
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '4');
      expect(user.positionTitle, 'Staff IT Support');
      expect(user.isApprover, isTrue);
      expect(user.canApproveLeave, isTrue);
      expect(user.division?.name, 'Teknologi Informasi & Sistem');
      expect(user.supervisor?.name, 'Admin Divisi IT');
      expect(user.workLocations.length, 1);
      expect(user.workLocations.first.radiusMeters, 150);
      expect(user.permissions, contains('approve-leave'));
    });

    test('TodayStatusModel parses on_leave, leave summary, and work_locations', () {
      final json = {
        'checked_in': false,
        'checked_out': false,
        'on_leave': true,
        'leave': {
          'id': 5,
          'leave_type': {'id': 2, 'name': 'Sakit', 'code': 'SAKIT'},
          'start_date': '2026-11-27',
          'end_date': '2026-11-28',
          'reason': 'Demam',
          'status': 'approved',
        },
        'can_checkin': false,
        'can_checkout': false,
        'is_flexible_location': false,
        'work_locations': [
          {
            'id': 1,
            'name': 'Kantor Pusat BSS',
            'latitude': -6.224694,
            'longitude': 106.807785,
            'radius_meters': 150,
          }
        ],
        'checkin': null,
        'checkout': null,
      };

      final status = TodayStatusModel.fromJson(json);
      expect(status.onLeave, isTrue);
      expect(status.leave?.leaveTypeName, 'Sakit');
      expect(status.canCheckIn, isFalse);
      expect(status.workLocations.length, 1);
      expect(status.workLocations.first.name, 'Kantor Pusat BSS');
    });

    test('LeaveTypeModel parses leave type fields', () {
      final type = LeaveTypeModel.fromJson({
        'id': 1,
        'name': 'Cuti Tahunan',
        'code': 'CUTI',
        'requires_attachment': false,
        'approval_levels': 2,
        'requires_hr_approval': true,
        'is_active': true,
      });

      expect(type.id, 1);
      expect(type.name, 'Cuti Tahunan');
      expect(type.requiresAttachment, isFalse);
      expect(type.approvalLevels, 2);
      expect(type.requiresHrApproval, isTrue);
    });

    test('LeaveRequestModel parses request with approvals and attachment', () {
      final req = LeaveRequestModel.fromJson({
        'id': 1,
        'leave_type': {'id': 2, 'name': 'Sakit', 'code': 'SAKIT'},
        'start_date': '2026-11-28',
        'end_date': '2026-11-29',
        'total_days': 2,
        'reason': 'Demam tinggi',
        'status': 'pending',
        'current_step': 1,
        'attachment_url': 'http://localhost/storage/1/surat-dokter.jpg',
        'attachment_name': 'surat-dokter.jpg',
        'approvals': [
          {
            'step_level': 1,
            'approver_name': 'Admin Divisi IT',
            'approver_position': 'Kepala Divisi IT',
            'status': 'pending',
            'notes': null,
            'acted_at': null,
          }
        ],
      });

      expect(req.id, 1);
      expect(req.leaveTypeName, 'Sakit');
      expect(req.totalDays, 2);
      expect(req.isPending, isTrue);
      expect(req.attachmentName, 'surat-dokter.jpg');
      expect(req.approvals.length, 1);
      expect(req.approvals.first.approverName, 'Admin Divisi IT');
    });
  });
}
