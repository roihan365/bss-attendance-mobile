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
  final String? positionTitle;
  final bool isFlexibleLocation;
  final bool isApprover;
  final DivisionInfo? division;
  final SupervisorInfo? supervisor;
  final List<WorkLocation> workLocations;
  final List<String> roles;
  final List<String> permissions;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.token,
    this.emailVerifiedAt,
    this.positionTitle,
    this.isFlexibleLocation = false,
    this.isApprover = false,
    this.division,
    this.supervisor,
    this.workLocations = const [],
    this.roles = const [],
    this.permissions = const [],
  });

  bool get canApproveLeave => isApprover || permissions.contains('approve-leave');

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
    DateTime? emailVerifiedAt,
    String? positionTitle,
    bool? isFlexibleLocation,
    bool? isApprover,
    DivisionInfo? division,
    SupervisorInfo? supervisor,
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
      positionTitle: positionTitle ?? this.positionTitle,
      isFlexibleLocation: isFlexibleLocation ?? this.isFlexibleLocation,
      isApprover: isApprover ?? this.isApprover,
      division: division ?? this.division,
      supervisor: supervisor ?? this.supervisor,
      workLocations: workLocations ?? this.workLocations,
      roles: roles ?? this.roles,
      permissions: permissions ?? this.permissions,
    );
  }
}
