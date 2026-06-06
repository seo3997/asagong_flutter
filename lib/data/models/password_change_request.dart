class PasswordChangeRequest {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const PasswordChangeRequest({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
    };
  }

  factory PasswordChangeRequest.fromJson(Map<String, dynamic> json) {
    return PasswordChangeRequest(
      currentPassword: json['currentPassword'] as String? ?? '',
      newPassword: json['newPassword'] as String? ?? '',
      confirmPassword: json['confirmPassword'] as String? ?? '',
    );
  }
}
