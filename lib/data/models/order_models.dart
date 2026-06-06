class OrderItemRequest {
  final int productId;
  final int quantity;
  final String optionName;

  OrderItemRequest({
    required this.productId,
    required this.quantity,
    required this.optionName,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'optionName': optionName,
    };
  }
}

class OrderCreateRequest {
  final int userNo;
  final int totalItemAmount;
  final int deliveryFee;
  final int discountAmount;
  final int totalPayAmount;
  final String receiverName;
  final String receiverPhone;
  final String zipCode;
  final String address1;
  final String address2;
  final String orderMemo;
  final int? branchId;
  final List<OrderItemRequest> items;

  OrderCreateRequest({
    required this.userNo,
    required this.totalItemAmount,
    required this.deliveryFee,
    required this.discountAmount,
    required this.totalPayAmount,
    required this.receiverName,
    required this.receiverPhone,
    required this.zipCode,
    required this.address1,
    required this.address2,
    required this.orderMemo,
    this.branchId,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'userNo': userNo,
      'totalItemAmount': totalItemAmount,
      'deliveryFee': deliveryFee,
      'discountAmount': discountAmount,
      'totalPayAmount': totalPayAmount,
      'receiverName': receiverName,
      'receiverPhone': receiverPhone,
      'zipCode': zipCode,
      'address1': address1,
      'address2': address2,
      'orderMemo': orderMemo,
      if (branchId != null) 'branchId': branchId,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
}

class OrderCreateResponse {
  final bool success;
  final String? message;
  final int? orderId;
  final String orderNo;
  final String orderName;
  final int amount;

  OrderCreateResponse({
    required this.success,
    this.message,
    this.orderId,
    required this.orderNo,
    required this.orderName,
    required this.amount,
  });

  factory OrderCreateResponse.fromJson(Map<String, dynamic> json) {
    return OrderCreateResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      orderId: json['orderId'] as int?,
      orderNo: (json['orderNo'] ?? json['order_no'] ?? json['ORDER_NO'] ?? '').toString(),
      orderName: (json['orderName'] ?? json['order_name'] ?? json['ORDER_NAME'] ?? '').toString(),
      amount: (json['amount'] as num? ?? json['AMOUNT'] as num? ?? 0).toInt(),
    );
  }
}

class PaymentConfirmRequest {
  final String paymentKey;
  final String orderNo;
  final int amount;
  final int? userNo;

  PaymentConfirmRequest({
    required this.paymentKey,
    required this.orderNo,
    required this.amount,
    this.userNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'paymentKey': paymentKey,
      'orderNo': orderNo,
      'amount': amount,
      if (userNo != null) 'userNo': userNo,
    };
  }
}

class PaymentConfirmResponse {
  final bool success;
  final String? message;
  final String? orderNo;
  final int? amount;

  PaymentConfirmResponse({
    required this.success,
    this.message,
    this.orderNo,
    this.amount,
  });

  factory PaymentConfirmResponse.fromJson(Map<String, dynamic> json) {
    return PaymentConfirmResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      orderNo: json['orderNo']?.toString(),
      amount: json['amount'] != null ? (json['amount'] as num).toInt() : null,
    );
  }
}
