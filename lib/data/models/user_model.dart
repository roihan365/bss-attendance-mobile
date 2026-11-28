import '../../domain/entities/user.dart';
import 'work_location_model.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.token,
    super.emailVerifiedAt,
    super.employeeCode,
    super.phone,
    super.positionTitle,
    super.position,
    super.isFlexibleLocation = false,
    super.isApprover = false,
    super.division,
    super.supervisor,
    super.supervisor2,
    super.workLocations = const [],
    super.roles = const [],
    super.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user') && json['user'] is Map) {
      final userData = Map<String, dynamic>.from(json['user'] as Map);
      return _fromUserMap(userData, token: json['token']?.toString());
    }

    return _fromUserMap(json, token: json['token']?.toString());
  }

  static UserModel _fromUserMap(Map<String, dynamic> map, {String? token}) {
    // Dukungan struktur terbaru: data karyawan berada di dalam map['employee']
    // Fallback ke root map jika masih menggunakan format lama / cache lokal.
    final empMap = map['employee'] is Map
        ? Map<String, dynamic>.from(map['employee'] as Map)
        : map;

    DivisionInfo? division;
    final rawDiv = empMap['division'] ?? map['division'];
    if (rawDiv is Map) {
      final divMap = Map<String, dynamic>.from(rawDiv);
      division = DivisionInfo(
        id: _toInt(divMap['id']),
        name: divMap['name']?.toString() ?? '',
        code: divMap['code']?.toString(),
      );
    }

    PositionInfo? position;
    final rawPos = empMap['position'] ?? map['position'];
    if (rawPos is Map) {
      final posMap = Map<String, dynamic>.from(rawPos);
      position = PositionInfo(
        id: _toInt(posMap['id']),
        code: posMap['code']?.toString(),
        name: posMap['name']?.toString() ?? '',
        level: _toInt(posMap['level'], fallback: 1),
        isHr: posMap['is_hr'] == true || posMap['is_hr'] == 1,
      );
    }

    SupervisorInfo? parseSupervisor(dynamic raw) {
      if (raw is! Map) return null;
      final supMap = Map<String, dynamic>.from(raw);
      return SupervisorInfo(
        id: _toInt(supMap['id']),
        name: supMap['name']?.toString() ?? '',
        positionTitle: supMap['position']?.toString() ?? supMap['position_title']?.toString(),
      );
    }

    final supervisor1 = parseSupervisor(
      empMap['supervisor_1'] ?? empMap['supervisor'] ?? map['supervisor_1'] ?? map['supervisor'],
    );
    final supervisor2 = parseSupervisor(empMap['supervisor_2'] ?? map['supervisor_2']);

    final workLocations = <WorkLocationModel>[];
    final rawLocs = empMap['work_locations'] ?? map['work_locations'];
    if (rawLocs is List) {
      for (final item in rawLocs) {
        if (item is Map) {
          workLocations.add(WorkLocationModel.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    final roles = <String>[];
    if (map['roles'] is List) {
      for (final r in (map['roles'] as List)) {
        if (r != null) roles.add(r.toString());
      }
    }

    final permissions = <String>[];
    if (map['permissions'] is List) {
      for (final p in (map['permissions'] as List)) {
        if (p != null) permissions.add(p.toString());
      }
    }

    final rawFlex = empMap['is_flexible_location'] ?? map['is_flexible_location'];
    final posTitle = position?.name ?? map['position_title']?.toString();

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ??
          empMap['full_name']?.toString() ??
          map['full_name']?.toString(),
      token: token,
      emailVerifiedAt: map['email_verified_at'] != null
          ? DateTime.tryParse(map['email_verified_at'].toString())
          : null,
      employeeCode: empMap['employee_code']?.toString() ?? map['employee_code']?.toString(),
      phone: empMap['phone']?.toString() ?? map['phone']?.toString(),
      positionTitle: posTitle,
      position: position,
      isFlexibleLocation: rawFlex == true || rawFlex == 1,
      isApprover: map['is_approver'] == true || map['is_approver'] == 1,
      division: division,
      supervisor: supervisor1,
      supervisor2: supervisor2,
      workLocations: workLocations,
      roles: roles,
      permissions: permissions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'token': token,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
        'employee_code': employeeCode,
        'phone': phone,
        'position_title': positionTitle,
        if (position != null)
          'position': {
            'id': position!.id,
            'code': position!.code,
            'name': position!.name,
            'level': position!.level,
            'is_hr': position!.isHr,
          },
        'is_flexible_location': isFlexibleLocation,
        'is_approver': isApprover,
        if (division != null)
          'division': {
            'id': division!.id,
            'name': division!.name,
            'code': division!.code,
          },
        if (supervisor != null)
          'supervisor_1': {
            'id': supervisor!.id,
            'name': supervisor!.name,
            'position': supervisor!.positionTitle,
          },
        if (supervisor2 != null)
          'supervisor_2': {
            'id': supervisor2!.id,
            'name': supervisor2!.name,
            'position': supervisor2!.positionTitle,
          },
        'work_locations': workLocations
            .map((w) => w is WorkLocationModel
                ? w.toJson()
                : {
                    'id': w.id,
                    'name': w.name,
                    'code': w.code,
                    'address': w.address,
                    'latitude': w.latitude,
                    'longitude': w.longitude,
                    'radius_meters': w.radiusMeters,
                  })
            .toList(),
        'roles': roles,
        'permissions': permissions,
      };

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
