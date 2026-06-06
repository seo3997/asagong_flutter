/// Model mapping the dashboard metrics statistics.
/// Represents product status counts for total, processing, completed, and rejected.
/// Handles the backend typo key 'reguestCount' representing rejected/returned items.
class ProductDashboardStats {
  final int totalCount;
  final int rejectedCount; // Maps to 'reguestCount' from backend
  final int processingCount;
  final int completedCount;

  ProductDashboardStats({
    required this.totalCount,
    required this.rejectedCount,
    required this.processingCount,
    required this.completedCount,
  });

  factory ProductDashboardStats.fromJson(Map<String, dynamic> json) {
    return ProductDashboardStats(
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      rejectedCount: (json['reguestCount'] as num?)?.toInt() ?? 0, // Backend typo key handled here
      processingCount: (json['processingCount'] as num?)?.toInt() ?? 0,
      completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCount': totalCount,
      'reguestCount': rejectedCount, // Map back to original backend typo key
      'processingCount': processingCount,
      'completedCount': completedCount,
    };
  }
}
