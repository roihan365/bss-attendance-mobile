class User {
  final String id;
  final String email;
  final String? name;
  final String? token;
  final DateTime? emailVerifiedAt;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.token,
    this.emailVerifiedAt,
  });

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? token,
    DateTime? emailVerifiedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      token: token ?? this.token,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
    );
  }
}
