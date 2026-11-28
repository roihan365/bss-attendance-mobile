import 'work_location.dart';

class DivisionInfo {
  final int id;
  final String name;
  final String? code;

  const DivisionInfo({
    required this.id,
    required this.name,
    this.code,
  });
}

class PositionInfo {
  final int id;
  final String? code;
  final String name;
  final int level;
  final bool isHr;

  const PositionInfo({
    required this.id,
    this.code,
    required this.name,
    this.level = 1,
    this.isHr = false,
  });
}

class SupervisorInfo {
  final int id;
  final String name;
  final String? positionTitle;

  const SupervisorInfo({
    required this.id,
    required this.name,
    this.positionTitle,
  });
}

class User {
  final String id;
  final String email;
  final String? name;
  final String? token;
  final DateTime? emailVerifiedAt;
  final String? employeeCode;
  final String? phone;
  final String? positionTitle;
  final PositionInfo? position;
  final bool isFlexibleLocation;
  final bool isApprover;
  final DivisionInfo? division;
  final SupervisorInfo? supervisor;
  final SupervisorInfo? supervisor2;
  final List<WorkLocation> workLocations;
  final List<String> roles;
  final List<String> permissions;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.token,
    this.emailVerifiedAt,
    this.employeeCode,
    this.phone,
    this.positionTitle,
    this.position,
    this.isFlexibleLocation = false,
    this.isApprover = false,
    this.division,
    this.supervisor,
    this.supervisor2,
    this.workLocations = const [],
    this.roles = const [],
    this.permissions = const [],
  });

  bool get isHr => (position?.isHr ?? false) || roles.contains('hr');
  bool get isSuperadmin => roles.contains('superadmin');
  bool get canApproveLeave =>
      isApprover || permissions.contains('approve-leave') || isHr || isSuperadmin;
  String? get effectivePositionTitle => position?.name ?? positionTitle;

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
    DateTime? emailVerifiedAt,
    String? employeeCode,
    String? phone,
    String? positionTitle,
    PositionInfo? position,
    bool? isFlexibleLocation,
    bool? isApprover,
    DivisionInfo? division,
    SupervisorInfo? supervisor,
    SupervisorInfo? supervisor2,
    List<WorkLocation>? workLocations,
    List<String>? roles,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      employeeCode: employeeCode ?? this.employeeCode,
      phone: phone ?? this.phone,
      positionTitle: positionTitle ?? this.positionTitle,
      position: position ?? this.position,
      isFlexibleLocation: isFlexibleLocation ?? this.isFlexibleLocation,
      isApprover: isApprover ?? this.isApprover,
      division: division ?? this.division,
      supervisor: supervisor ?? this.supervisor,
      supervisor2: supervisor2 ?? this.supervisor2,
      workLocations: workLocations ?? this.workLocations,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }
}
