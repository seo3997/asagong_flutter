import 'approval_status.dart';

/// Request body for updating the approval status of a product.
/// Migrated from Kotlin's `ProductItem`.
class ProductApprovalRequest {
  final String productId;
  final ApprovalStatus approvalStatus;
  final int updusrNo;
  final String? rejectReason;
  final String systemType;

  ProductApprovalRequest({
    required this.productId,
    required this.approvalStatus,
    required this.updusrNo,
    this.rejectReason,
    required this.systemType,
  });

  factory ProductApprovalRequest.fromJson(Map<String, dynamic> json) {
    return ProductApprovalRequest(
      productId: json['productId'] as String? ?? '',
      approvalStatus: ApprovalStatus.fromCode(json['saleStatus'] as String?),
      updusrNo: json['updusrNo'] as int? ?? 0,
      rejectReason: json['rejectReason'] as String?,
      systemType: json['systemType'] as String? ?? '1',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'saleStatus': approvalStatus.code,
      'updusrNo': updusrNo,
      'rejectReason': rejectReason,
      'systemType': systemType,
    };
  }
}
