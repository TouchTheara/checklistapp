class Profile {
  const Profile({
    this.name = 'Site Safety Lead',
    this.email = 'safety@sitehq.com',
    this.notificationsEnabled = true,
    this.avatarPath,
  });

  final String name;
  final String email;
  final bool notificationsEnabled;
  final String? avatarPath;

  Profile copyWith({
    String? name,
    String? email,
    bool? notificationsEnabled,
    String? avatarPath,
  }) {
    return Profile(
      name: name ?? this.name,
      email: email ?? this.email,
      notificationsEnabled:
          notificationsEnabled ?? this.notificationsEnabled,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'notificationsEnabled': notificationsEnabled,
      'avatarPath': avatarPath,
    };
  }

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      name: json['name'] as String? ?? 'Site Safety Lead',
      email: json['email'] as String? ?? 'safety@sitehq.com',
      notificationsEnabled:
          json['notificationsEnabled'] as bool? ?? true,
      avatarPath: json['avatarPath'] as String?,
    );
  }
}
