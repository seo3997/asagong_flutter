class StringResponse {
  final String resultString;

  StringResponse({required this.resultString});

  factory StringResponse.fromJson(Map<String, dynamic> json) {
    return StringResponse(
      resultString: json['resultString'] as String? ?? '',
    );
  }
}
