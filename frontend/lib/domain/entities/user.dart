// Domain layer user entity
class User {
  final String id;
  final String? email;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const User({
    required this.id,
    this.email,
    required this.createdAt,
    this.lastLoginAt,
  });

  factory User.empty() => User(
    id: '',
    createdAt: DateTime.now(),
  );

  bool get isAuthenticated => id.isNotEmpty;

  User copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}