class LinkSocialRequest {
  final String userId;
  final String userNo;
  final String? provider;
  final String? providerUserId;

  LinkSocialRequest({
    required this.userId,
    required this.userNo,
    this.provider,
    this.providerUserId,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userNo': userNo,
      'provider': provider,
      'providerUserId': providerUserId,
    };
  }
}
