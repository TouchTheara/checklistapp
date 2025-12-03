class Profile {
  const Profile({
    this.name = 'Checklist Pro',
    this.email = 'team@acme.inc',
    this.notificationsEnabled = true,
  });

  final String name;
  final String email;
  final bool notificationsEnabled;

  Profile copyWith({
    String? name,
    String? email,
    bool? notificationsEnabled,
  }) {
    return Profile(
      name: name ?? this.name,
      email: email ?? this.email,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'notificationsEnabled': notificationsEnabled,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String? ?? 'Checklist Pro',
      email: json['email'] as String? ?? 'team@acme.inc',
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ?? true,
    );
  }
}
