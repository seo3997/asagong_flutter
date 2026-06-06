class OrderCancelRequest {
  final String orderId;
  final String cancelReason;
  final int userNo;

  OrderCancelRequest({
    required this.orderId,
    required this.cancelReason,
    required this.userNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'cancelReason': cancelReason,
      'userNo': userNo,
    };
  }
}

class PaymentCancelResponse {
  final bool success;
  final String? message;

  PaymentCancelResponse({
    required this.success,
    this.message,
  });

  factory PaymentCancelResponse.fromJson(Map<String, dynamic> json) {
    return PaymentCancelResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}
