class SocialAuthRequest {
  final String provider;
  final String providerUserId;
  final String? accessToken;
  final String? idToken;
  final String? deviceId;
  final String? appVersion;

  SocialAuthRequest({
    required this.provider,
    required this.providerUserId,
    this.accessToken,
    this.idToken,
    this.deviceId,
    this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'providerUserId': providerUserId,
      'accessToken': accessToken,
      'idToken': idToken,
      'deviceId': deviceId,
      'appVersion': appVersion,
    };
  }
}
