class User {
  final String id;
  final String email;
  final String? name;
  final String? token;

  User({required this.id, required this.email, this.name, this.token});

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'name': name,
    'token': token,
  };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    // Format dari API login:
    // {
    //   "token": "...",
    //   "user": {
    //     "id": 1,
    //     "name": "...",
    //     "email": "..."
    //   }
    // }

    if (user is Map) {
      return User(
        id: user['id']?.toString() ?? '',
        email: user['email']?.toString() ?? '',
        name: user['name']?.toString() ?? user['full_name']?.toString(),
        token: json['token']?.toString(),
      );
    }

    // Format dari SharedPreferences:
    // {
    //   "id": "1",
    //   "email": "...",
    //   "name": "...",
    //   "token": "..."
    // }

    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? json['full_name']?.toString(),
      token: json['token']?.toString(),
    );
  }
}
