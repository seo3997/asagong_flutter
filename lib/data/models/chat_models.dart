class ChatRoomResponse {
  final String roomId;
  final String buyerId;
  final String branchId;
  final String productId;
  final String? lastMessage;
  final String? lastMessageTime;

  ChatRoomResponse({
    required this.roomId,
    required this.buyerId,
    required this.branchId,
    required this.productId,
    this.lastMessage,
    this.lastMessageTime,
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) {
    return ChatRoomResponse(
      roomId: (json['roomId'] ?? json['ROOM_ID'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? json['BUYER_ID'] ?? '').toString(),
      branchId: (json['branchId'] ?? json['BRANCH_ID'] ?? '').toString(),
      productId: (json['productId'] ?? json['PRODUCT_ID'] ?? '').toString(),
      lastMessage: (json['lastMessage'] ?? json['LAST_MESSAGE'])?.toString(),
      lastMessageTime: (json['lastMessageTime'] ?? json['LAST_MESSAGE_TIME'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'buyerId': buyerId,
      'branchId': branchId,
      'productId': productId,
      if (lastMessage != null) 'lastMessage': lastMessage,
      if (lastMessageTime != null) 'lastMessageTime': lastMessageTime,
    };
  }
}

class ChatBuyerDto {
  final String roomId;
  final int productId;
  final String branchId;
  final String buyerId;
  final int buyerNo;
  final String buyerNm;
  final int sellerNo;
  final String sellerNm;

  ChatBuyerDto({
    required this.roomId,
    required this.productId,
    required this.branchId,
    required this.buyerId,
    required this.buyerNo,
    required this.buyerNm,
    required this.sellerNo,
    required this.sellerNm,
  });

  factory ChatBuyerDto.fromJson(Map<String, dynamic> json) {
    return ChatBuyerDto(
      roomId: (json['roomId'] ?? json['ROOM_ID'] ?? '').toString(),
      productId: (json['productId'] as num? ?? json['PRODUCT_ID'] as num? ?? 0).toInt(),
      branchId: (json['branchId'] ?? json['BRANCH_ID'] ?? '').toString(),
      buyerId: (json['buyerId'] ?? json['BUYER_ID'] ?? '').toString(),
      buyerNo: (json['buyerNo'] as num? ?? json['BUYER_NO'] as num? ?? 0).toInt(),
      buyerNm: (json['buyerNm'] ?? json['BUYER_NM'] ?? '').toString(),
      sellerNo: (json['sellerNo'] as num? ?? json['SELLER_NO'] as num? ?? 0).toInt(),
      sellerNm: (json['sellerNm'] ?? json['SELLER_NM'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'productId': productId,
      'branchId': branchId,
      'buyerId': buyerId,
      'buyerNo': buyerNo,
      'buyerNm': buyerNm,
      'sellerNo': sellerNo,
      'sellerNm': sellerNm,
    };
  }
}

class ChatMessage {
  final String roomId;
  final String senderId;
  final String senderGroup;
  final String message;
  final String type;
  final String time;
  final String? receiveGroup;
  bool isMe;

  ChatMessage({
    required this.roomId,
    required this.senderId,
    required this.senderGroup,
    required this.message,
    required this.type,
    required this.time,
    this.receiveGroup,
    this.isMe = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      roomId: (json['roomId'] ?? json['ROOM_ID'] ?? '').toString(),
      senderId: (json['senderId'] ?? json['SENDER_ID'] ?? '').toString(),
      senderGroup: (json['senderGroup'] ?? json['SENDER_GROUP'] ?? '').toString(),
      message: (json['message'] ?? json['MESSAGE'] ?? '').toString(),
      type: (json['type'] ?? json['TYPE'] ?? 'text').toString(),
      time: (json['time'] ?? json['TIME'] ?? '').toString(),
      receiveGroup: (json['receiveGroup'] ?? json['RECEIVE_GROUP'])?.toString(),
      isMe: json['isMe'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'senderId': senderId,
      'senderGroup': senderGroup,
      'message': message,
      'type': type,
      'time': time,
      if (receiveGroup != null) 'receiveGroup': receiveGroup,
      'isMe': isMe,
    };
  }
}
