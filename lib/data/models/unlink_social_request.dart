class UnlinkSocialRequest {
  final String provider;
  final String providerUserId;

  UnlinkSocialRequest({
    required this.provider,
    required this.providerUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'providerUserId': providerUserId,
    };
  }
}
