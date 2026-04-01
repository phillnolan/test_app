class StudentProfile {
  const StudentProfile({
    required this.username,
    required this.displayName,
    this.studentCode,
    this.className,
  });

  final String username;
  final String displayName;
  final String? studentCode;
  final String? className;

  factory StudentProfile.fromApi(Map<String, dynamic>? json, String username) {
    final displayName = (json?['displayName'] ?? json?['name'] ?? username)
        .toString();
    return StudentProfile(
      username: username,
      displayName: displayName,
      studentCode: json?['studentCode']?.toString(),
      className: json?['className']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'studentCode': studentCode,
      'className': className,
    };
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      username: (json['username'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      studentCode: json['studentCode']?.toString(),
      className: json['className']?.toString(),
    );
  }
}
