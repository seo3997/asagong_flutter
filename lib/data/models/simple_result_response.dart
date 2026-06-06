/// Dart representation of Kotlin's `SimpleResultResponse`.
/// Used for standard API response wrapping simple boolean result and info message.
class SimpleResultResponse {
  final bool result;
  final String message;

  SimpleResultResponse({
    required this.result,
    required this.message,
  });

  factory SimpleResultResponse.fromJson(Map<String, dynamic> json) {
    return SimpleResultResponse(
      result: json['result'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result,
      'message': message,
    };
  }
}
