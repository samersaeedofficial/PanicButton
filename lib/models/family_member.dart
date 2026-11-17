class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final String phone;
  final String email;
  final String password;
  final DateTime addedAt;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.phone,
    required this.email,
    required this.password,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'phone': phone,
      'email': email,
      'password': password,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory FamilyMember.fromMap(Map<String, dynamic> map) {
    return FamilyMember(
      id: map['id'] as String,
      name: map['name'] as String,
      relation: map['relation'] as String,
      phone: map['phone'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      addedAt: DateTime.parse(map['addedAt'] as String),
    );
  }
}
