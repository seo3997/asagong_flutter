import 'approval_status.dart';

/// Dart representation of Kotlin's `ProductVo`.
/// Contains product details and its current approval/sale status.
class ProductVo {
  final String? productId;
  final String userNo;
  final String title;
  final String description;
  final String price;
  final String categoryGroup;
  final String categoryMid;
  final String categoryScls;
  final String saleStatus;
  final String areaGroup;
  final String areaMid;
  final String areaScls;
  final String quantity;
  final String unitGroup;
  final String unitCode;
  final String desiredShippingDate;
  final String registerNo;
  final String? registDt;
  final String updusrNo;
  final String? updtDt;
  final String? imageUrl;

  // Extra name fields mapping
  final String categoryMidNm;
  final String categorySclsNm;
  final String areaMidNm;
  final String areaSclsNm;
  final String unitCodeNm;
  final String saleStatusNm;
  final String userId;
  final String wholesalerNo;
  final String wholesalerId;
  final String fav;
  final String systemType;
  final String rejectReason;
  final String branchId;
  final String editorMode;
  final String availableQuantity;

  ProductVo({
    this.productId,
    required this.userNo,
    required this.title,
    required this.description,
    required this.price,
    required this.categoryGroup,
    required this.categoryMid,
    required this.categoryScls,
    required this.saleStatus,
    required this.areaGroup,
    required this.areaMid,
    required this.areaScls,
    required this.quantity,
    required this.unitGroup,
    required this.unitCode,
    required this.desiredShippingDate,
    required this.registerNo,
    this.registDt,
    required this.updusrNo,
    this.updtDt,
    this.imageUrl,
    this.categoryMidNm = '',
    this.categorySclsNm = '',
    this.areaMidNm = '',
    this.areaSclsNm = '',
    this.unitCodeNm = '',
    this.saleStatusNm = '',
    this.userId = '',
    this.wholesalerNo = '',
    this.wholesalerId = '',
    this.fav = '',
    this.systemType = '1',
    this.rejectReason = '1',
    this.branchId = '',
    this.editorMode = '3',
    this.availableQuantity = '0',
  });

  /// Convenient getter to get the status as the Domain specific [ApprovalStatus] enum.
  ApprovalStatus get approvalStatus => ApprovalStatus.fromCode(saleStatus);

  /// Convenient getter to get the label matching the approval status.
  String get approvalStatusNm => approvalStatus.label;

  factory ProductVo.fromJson(Map<String, dynamic> json) {
    return ProductVo(
      productId: json['productId']?.toString(),
      userNo: (json['userNo'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      categoryGroup: (json['categoryGroup'] ?? '').toString(),
      categoryMid: (json['categoryMid'] ?? '').toString(),
      categoryScls: (json['categoryScls'] ?? '').toString(),
      saleStatus: (json['saleStatus'] ?? '0').toString(),
      areaGroup: (json['areaGroup'] ?? '').toString(),
      areaMid: (json['areaMid'] ?? '').toString(),
      areaScls: (json['areaScls'] ?? '').toString(),
      quantity: (json['quantity'] ?? '').toString(),
      unitGroup: (json['unitGroup'] ?? '').toString(),
      unitCode: (json['unitCode'] ?? '').toString(),
      desiredShippingDate: (json['desiredShippingDate'] ?? '').toString(),
      registerNo: (json['registerNo'] ?? '').toString(),
      registDt: json['registDt']?.toString(),
      updusrNo: (json['updusrNo'] ?? '').toString(),
      updtDt: json['updtDt']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      categoryMidNm: (json['categoryMidNm'] ?? '').toString(),
      categorySclsNm: (json['categorySclsNm'] ?? '').toString(),
      areaMidNm: (json['areaMidNm'] ?? '').toString(),
      areaSclsNm: (json['areaSclsNm'] ?? '').toString(),
      unitCodeNm: (json['unitCodeNm'] ?? '').toString(),
      saleStatusNm: json['saleStatusNm']?.toString() ?? '',
      userId: (json['userId'] ?? '').toString(),
      wholesalerNo: (json['wholesalerNo'] ?? '').toString(),
      wholesalerId: (json['wholesalerId'] ?? '').toString(),
      fav: (json['fav'] ?? '').toString(),
      systemType: json['systemType']?.toString() ?? '1',
      rejectReason: (json['rejectReason'] ?? '').toString(),
      branchId: (json['branchId'] ?? '').toString(),
      editorMode: json['editorMode']?.toString() ?? '3',
      availableQuantity: (json['availableQuantity'] ?? '0').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'userNo': userNo,
      'title': title,
      'description': description,
      'price': price,
      'categoryGroup': categoryGroup,
      'categoryMid': categoryMid,
      'categoryScls': categoryScls,
      'saleStatus': saleStatus,
      'areaGroup': areaGroup,
      'areaMid': areaMid,
      'areaScls': areaScls,
      'quantity': quantity,
      'unitGroup': unitGroup,
      'unitCode': unitCode,
      'desiredShippingDate': desiredShippingDate,
      'registerNo': registerNo,
      'registDt': registDt,
      'updusrNo': updusrNo,
      'updtDt': updtDt,
      'imageUrl': imageUrl,
      'categoryMidNm': categoryMidNm,
      'categorySclsNm': categorySclsNm,
      'areaMidNm': areaMidNm,
      'areaSclsNm': areaSclsNm,
      'unitCodeNm': unitCodeNm,
      'saleStatusNm': saleStatusNm,
      'userId': userId,
      'wholesalerNo': wholesalerNo,
      'wholesalerId': wholesalerId,
      'fav': fav,
      'systemType': systemType,
      'rejectReason': rejectReason,
      'branchId': branchId,
      'editorMode': editorMode,
      'availableQuantity': availableQuantity,
    };
  }
}
