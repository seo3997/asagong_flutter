import 'product_vo.dart';
import 'product_image_vo.dart';

/// Dart representation of Kotlin's `ProductDetailResponse`.
/// Combined wrapper model representing product details and associated image list.
class ProductDetailResponse {
  final ProductVo product;
  final List<ProductImageVo> imageMetas;

  ProductDetailResponse({
    required this.product,
    required this.imageMetas,
  });

  factory ProductDetailResponse.fromJson(Map<String, dynamic> json) {
    var imagesJson = json['imageMetas'] as List? ?? [];
    List<ProductImageVo> images = imagesJson
        .map((img) => ProductImageVo.fromJson(img as Map<String, dynamic>))
        .toList();

    return ProductDetailResponse(
      product: ProductVo.fromJson(json['product'] as Map<String, dynamic>? ?? {}),
      imageMetas: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'imageMetas': imageMetas.map((img) => img.toJson()).toList(),
    };
  }
}
