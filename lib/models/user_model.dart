enum UserRole { user, member }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phone;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phone': phone,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.user,
      ),
      phone: map['phone'] as String?,
    );
  }
}
