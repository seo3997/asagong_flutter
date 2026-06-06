class AdItem {
  final String productId;
  final String title;
  final String description;
  final String price;
  final String imageUrl;
  final String userId;
  final String? orderNo;
  final String? orderId;
  final String? paymentStatus;
  final String? orderStatusNm;
  final String? deliveredAt;
  final String? saleStatusNm;
  final String? deliveryCompanyNm;
  final String? trackingNo;
  final String? orderedAt;

  AdItem({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.userId,
    this.orderNo,
    this.orderId,
    this.paymentStatus,
    this.orderStatusNm,
    this.deliveredAt,
    this.saleStatusNm,
    this.deliveryCompanyNm,
    this.trackingNo,
    this.orderedAt,
  });

  factory AdItem.fromJson(Map<String, dynamic> json) {
    return AdItem(
      productId: (json['productId'] ?? json['PRODUCT_ID'] ?? '').toString(),
      title: (json['title'] ?? json['TITLE'] ?? '').toString(),
      description: (json['description'] ?? json['DESCRIPTION'] ?? '').toString(),
      price: (json['price'] ?? json['PRICE'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['IMAGE_URL'] ?? '').toString(),
      userId: (json['userId'] ?? json['USER_NO'] ?? '').toString(),
      orderNo: json['orderNo'] ?? json['ORDER_NO'],
      orderId: json['orderId'] ?? json['ORDER_ID'],
      paymentStatus: json['paymentStatus'] ?? json['ORDER_STATUS'] ?? json['PAYMENT_STATUS'],
      orderStatusNm: json['orderStatusNm'] ?? json['ORDER_STATUS_NM'],
      deliveredAt: json['deliveredAt'] ?? json['DELIVERED_AT'],
      saleStatusNm: json['saleStatusNm'] ?? json['SALE_STATUS_NM'],
      deliveryCompanyNm: json['deliveryCompanyNm'] ?? json['DELIVERY_COMPANY_NM'],
      trackingNo: json['trackingNo'] ?? json['TRACKING_NO'],
      orderedAt: json['orderedAt'] ?? json['ORDERED_AT'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'userId': userId,
      'orderNo': orderNo,
      'orderId': orderId,
      'paymentStatus': paymentStatus,
      'orderStatusNm': orderStatusNm,
      'deliveredAt': deliveredAt,
      'saleStatusNm': saleStatusNm,
      'deliveryCompanyNm': deliveryCompanyNm,
      'trackingNo': trackingNo,
      'orderedAt': orderedAt,
    };
  }
}
