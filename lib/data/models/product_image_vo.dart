/// Dart representation of Kotlin's `ProductImageVo`.
/// Represents product image metadata.
class ProductImageVo {
  final String? imageId;
  final String? productId;
  final String? imageCd;
  final String? imageUrl;
  final String? imageName;
  final String represent; // Representing flag ("0" or "1")
  final int? imageSize;
  final String? imageText;
  final String? imageType;
  final String registerNo;
  final String? registDt;
  final String updusrNo;
  final String? updtDt;

  ProductImageVo({
    this.imageId,
    this.productId,
    this.imageCd,
    this.imageUrl,
    this.imageName,
    required this.represent,
    this.imageSize,
    this.imageText,
    this.imageType,
    this.registerNo = '',
    this.registDt,
    this.updusrNo = '',
    this.updtDt,
  });

  /// Convenient helper to check if this image is the represent image of the product.
  bool get isRepresent => represent == '1';

  factory ProductImageVo.fromJson(Map<String, dynamic> json) {
    return ProductImageVo(
      imageId: json['imageId'] as String?,
      productId: json['productId'] as String?,
      imageCd: json['imageCd'] as String?,
      imageUrl: json['imageUrl'] as String?,
      imageName: json['imageName'] as String?,
      represent: json['represent'] as String? ?? '0',
      imageSize: json['imageSize'] as int?,
      imageText: json['imageText'] as String?,
      imageType: json['imageType'] as String?,
      registerNo: json['registerNo'] as String? ?? '',
      registDt: json['registDt'] as String?,
      updusrNo: json['updusrNo'] as String? ?? '',
      updtDt: json['updtDt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageId': imageId,
      'productId': productId,
      'imageCd': imageCd,
      'imageUrl': imageUrl,
      'imageName': imageName,
      'represent': represent,
      'imageSize': imageSize,
      'imageText': imageText,
      'imageType': imageType,
      'registerNo': registerNo,
      'registDt': registDt,
      'updusrNo': updusrNo,
      'updtDt': updtDt,
    };
  }
}
