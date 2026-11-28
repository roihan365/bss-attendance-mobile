import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/data/models/leave_request_model.dart';
import 'package:bss_attendance_new/data/models/leave_type_model.dart';
import 'package:bss_attendance_new/data/models/today_status_model.dart';
import 'package:bss_attendance_new/data/models/user_model.dart';

void main() {
  group('New API Models Tests', () {
    test('UserModel parses nested employee, position, supervisors, work_locations, roles, permissions', () {
      final json = {
        'token': '1|laravel_sanctum_token',
        'user': {
          'id': 5,
          'name': 'Roy Karyawan IT',
          'email': 'karyawan.it@bss.com',
          'is_approver': false,
          'roles': ['employee'],
          'permissions': ['attendance-mobile', 'submit-leave'],
          'employee': {
            'id': 5,
            'employee_code': 'BSS-005',
            'full_name': 'Roy Karyawan IT',
            'phone': '08123456789',
            'is_flexible_location': false,
            'division': {
              'id': 1,
              'name': 'Teknologi Informasi & Sistem',
              'code': 'IT',
            },
            'position': {
              'id': 5,
              'code': 'STAFF',
              'name': 'Staff',
              'level': 1,
              'is_hr': false,
            },
            'supervisor_1': {
              'id': 3,
              'name': 'Admin Divisi IT',
              'position': 'Manager',
            },
            'supervisor_2': {
              'id': 1,
              'name': 'Super Administrator BSS',
              'position': 'Direktur',
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
          },
        },
      };

      final user = UserModel.fromJson(json);
      expect(user.id, '5');
      expect(user.employeeCode, 'BSS-005');
      expect(user.effectivePositionTitle, 'Staff');
      expect(user.isApprover, isFalse);
      expect(user.canApproveLeave, isFalse);
      expect(user.division?.name, 'Teknologi Informasi & Sistem');
      expect(user.supervisor?.name, 'Admin Divisi IT');
      expect(user.supervisor?.positionTitle, 'Manager');
      expect(user.supervisor2?.name, 'Super Administrator BSS');
      expect(user.supervisor2?.positionTitle, 'Direktur');
      expect(user.workLocations.length, 1);
      expect(user.workLocations.first.radiusMeters, 150);
    });

    test('UserModel grants canApproveLeave for HR and multi-role leader', () {
      final hrUser = UserModel.fromJson({
        'id': 2,
        'name': 'HR Staff',
        'email': 'hr@bss.com',
        'is_approver': true,
        'roles': ['hr', 'employee'],
        'permissions': ['attendance-mobile', 'submit-leave', 'approve-leave'],
        'employee': {
          'employee_code': 'BSS-002',
          'position': {'id': 2, 'code': 'HR', 'name': 'HR Officer', 'level': 2, 'is_hr': true},
        },
      });

      expect(hrUser.isHr, isTrue);
      expect(hrUser.canApproveLeave, isTrue);
      expect(hrUser.employeeCode, 'BSS-002');
    });

    test('TodayStatusModel parses on_leave, leave summary (type/code), and work_locations', () {
      final json = {
        'checked_in': false,
        'checked_out': false,
        'on_leave': true,
        'leave': {
          'id': 5,
          'type': 'Sakit',
          'code': 'SAKIT',
          'start_date': '2026-11-27',
          'end_date': '2026-11-28',
          'reason': 'Demam',
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
      expect(status.leave?.leaveTypeCode, 'SAKIT');
      expect(status.canCheckIn, isFalse);
      expect(status.workLocations.length, 1);
      expect(status.workLocations.first.name, 'Kantor Pusat BSS');
    });

    test('LeaveTypeModel parses leave type fields and approval_steps', () {
      final type = LeaveTypeModel.fromJson({
        'id': 3,
        'name': 'Cuti Tahunan',
        'code': 'CUTI',
        'requires_attachment': false,
        'approval_levels': 2,
        'requires_hr_approval': true,
        'is_active': true,
        'approval_steps': [
          {'step_level': 1, 'approver_type': 'direct_supervisor', 'position_id': null, 'employee_id': null},
          {'step_level': 2, 'approver_type': 'hr', 'position_id': null, 'employee_id': null},
        ],
      });

      expect(type.id, 3);
      expect(type.name, 'Cuti Tahunan');
      expect(type.requiresAttachment, isFalse);
      expect(type.approvalLevels, 2);
      expect(type.requiresHrApproval, isTrue);
      expect(type.approvalSteps.length, 2);
      expect(type.approvalSteps.first.approverTypeLabel, 'Atasan Langsung');
      expect(type.approvalSteps.last.approverTypeLabel, 'HRD');
    });

    test('LeaveRequestModel parses request with string division, approvals, and attachment', () {
      final req = LeaveRequestModel.fromJson({
        'id': 1,
        'user': {
          'id': 5,
          'name': 'Roy Karyawan IT',
          'email': 'karyawan.it@bss.com',
          'position_title': 'Staff',
          'division': 'Teknologi Informasi & Sistem',
        },
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
            'approver_position': 'Manager',
            'status': 'pending',
            'notes': null,
            'acted_at': null,
          }
        ],
      });

      expect(req.id, 1);
      expect(req.requesterId, '5');
      expect(req.requesterDivision, 'Teknologi Informasi & Sistem');
      expect(req.leaveTypeName, 'Sakit');
      expect(req.totalDays, 2);
      expect(req.isPending, isTrue);
      expect(req.attachmentName, 'surat-dokter.jpg');
      expect(req.approvals.length, 1);
      expect(req.approvals.first.approverName, 'Admin Divisi IT');
    });
  });
}
