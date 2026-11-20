import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.token,
    super.emailVerifiedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Format dari login API:
    // {
    //   "token": "...",
    //   "user": { "id": 1, "name": "...", "email": "...", "email_verified_at": "..." }
    // }
    if (json.containsKey('user') && json['user'] is Map) {
      final userData = json['user'] as Map<String, dynamic>;
      return UserModel(
        id: userData['id']?.toString() ?? '',
        email: userData['email']?.toString() ?? '',
        name: userData['name']?.toString() ?? userData['full_name']?.toString(),
        token: json['token']?.toString(),
        emailVerifiedAt: userData['email_verified_at'] != null
            ? DateTime.tryParse(userData['email_verified_at'].toString())
            : null,
      );
    }

    // Format langsung dari /user endpoint atau SharedPreferences
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString(),
      token: json['token']?.toString(),
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        'token': token,
        'email_verified_at': emailVerifiedAt?.toIso8601String(),
      };
}
