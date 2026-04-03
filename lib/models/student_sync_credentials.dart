class StudentSyncCredentials {
  const StudentSyncCredentials({
    required this.linkedStudentUsername,
    required this.username,
    required this.password,
    required this.updatedAt,
  });

  final String linkedStudentUsername;
  final String username;
  final String password;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'linkedStudentUsername': linkedStudentUsername,
      'username': username,
      'password': password,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudentSyncCredentials.fromJson(Map<String, dynamic> json) {
    return StudentSyncCredentials(
      linkedStudentUsername: (json['linkedStudentUsername'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      updatedAt:
          DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
    );
  }
}
