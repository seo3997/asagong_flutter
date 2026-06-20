class PushNotificationEntity {
  final int id;
  final String userId; // 수신자(내 계정 ID)
  final String type; // "chat", "product", "order", "sys" ...
  final String title;
  final String? body;
  final String? targetId; // 대상 ID (productId, roomId, orderId 등 통합)
  final String? deeplink; // app://product/123, app://chat/room/abc ...
  final bool isRead; // 읽음 여부
  final int createdAt; // 생성 일시 (밀리초)

  PushNotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.targetId,
    this.deeplink,
    this.isRead = false,
    required this.createdAt,
  });

  PushNotificationEntity copyWith({
    int? id,
    String? userId,
    String? type,
    String? title,
    String? body,
    String? targetId,
    String? deeplink,
    bool? isRead,
    int? createdAt,
  }) {
    return PushNotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      targetId: targetId ?? this.targetId,
      deeplink: deeplink ?? this.deeplink,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'body': body,
      'targetId': targetId,
      'deeplink': deeplink,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory PushNotificationEntity.fromJson(Map<String, dynamic> json) {
    return PushNotificationEntity(
      id: json['id'] as int,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      targetId: json['targetId'] as String?,
      deeplink: json['deeplink'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as int,
    );
  }
}
