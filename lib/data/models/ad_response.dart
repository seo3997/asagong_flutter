import 'ad_item.dart';

class AdResponse {
  final List<AdItem> items;

  AdResponse({required this.items});

  factory AdResponse.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] ?? json['content'] ?? []) as List;
    return AdResponse(
      items: itemsList.map((item) => AdItem.fromJson(item as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
