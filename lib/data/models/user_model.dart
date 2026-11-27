import '../../domain/entities/user.dart';
import 'work_location_model.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.token,
    super.emailVerifiedAt,
    super.positionTitle,
    super.isFlexibleLocation = false,
    super.isApprover = false,
    super.division,
    super.supervisor,
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
    DivisionInfo? division;
    if (map['division'] is Map) {
      final divMap = Map<String, dynamic>.from(map['division'] as Map);
      division = DivisionInfo(
        id: int.tryParse(divMap['id']?.toString() ?? '') ?? 0,
        name: divMap['name']?.toString() ?? '',
        code: divMap['code']?.toString(),
      );
    }

    SupervisorInfo? supervisor;
    if (map['supervisor'] is Map) {
      final supMap = Map<String, dynamic>.from(map['supervisor'] as Map);
      supervisor = SupervisorInfo(
        id: int.tryParse(supMap['id']?.toString() ?? '') ?? 0,
        name: supMap['name']?.toString() ?? '',
        positionTitle: supMap['position_title']?.toString(),
      );
    }

    final workLocations = <WorkLocationModel>[];
    if (map['work_locations'] is List) {
      for (final item in (map['work_locations'] as List)) {
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

    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      name: map['name']?.toString() ?? map['full_name']?.toString(),
      token: token,
      emailVerifiedAt: map['email_verified_at'] != null
          ? DateTime.tryParse(map['email_verified_at'].toString())
          : null,
      positionTitle: map['position_title']?.toString(),
      isFlexibleLocation: map['is_flexible_location'] == true || map['is_flexible_location'] == 1,
      isApprover: map['is_approver'] == true || map['is_approver'] == 1,
      division: division,
      supervisor: supervisor,
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
        'position_title': positionTitle,
        'is_flexible_location': isFlexibleLocation,
        'is_approver': isApprover,
        if (division != null)
          'division': {
            'id': division!.id,
            'name': division!.name,
            'code': division!.code,
          },
        if (supervisor != null)
          'supervisor': {
            'id': supervisor!.id,
            'name': supervisor!.name,
            'position_title': supervisor!.positionTitle,
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
}
