class AdListRequest {
  final String token;
  final int adCode;
  final int pageno;
  final String? categoryGroup;
  final String? categoryMid;
  final String? categoryScls;
  final String? areaGroup;
  final String? areaMid;
  final String? areaScls;
  final int? minPrice;
  final int? maxPrice;
  final String? saleStatus;
  final String? memberCode;

  AdListRequest({
    required this.token,
    required this.adCode,
    required this.pageno,
    this.categoryGroup = 'R010610',
    this.categoryMid,
    this.categoryScls,
    this.areaGroup = 'R010070',
    this.areaMid,
    this.areaScls,
    this.minPrice,
    this.maxPrice,
    this.saleStatus = '1',
    this.memberCode = '',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'token': token,
      'adCode': adCode,
      'pageno': pageno,
      'categoryGroup': categoryGroup,
      'areaGroup': areaGroup,
      'saleStatus': saleStatus,
      'memberCode': memberCode,
    };
    if (categoryMid != null) data['categoryMid'] = categoryMid;
    if (categoryScls != null) data['categoryScls'] = categoryScls;
    if (areaMid != null) data['areaMid'] = areaMid;
    if (areaScls != null) data['areaScls'] = areaScls;
    if (minPrice != null) data['minPrice'] = minPrice;
    if (maxPrice != null) data['maxPrice'] = maxPrice;
    return data;
  }

  factory AdListRequest.fromJson(Map<String, dynamic> json) {
    return AdListRequest(
      token: (json['token'] ?? '').toString(),
      adCode: json['adCode'] as int? ?? 1,
      pageno: json['pageno'] as int? ?? 1,
      categoryGroup: json['categoryGroup'] as String? ?? 'R010610',
      categoryMid: json['categoryMid'] as String?,
      categoryScls: json['categoryScls'] as String?,
      areaGroup: json['areaGroup'] as String? ?? 'R010070',
      areaMid: json['areaMid'] as String?,
      areaScls: json['areaScls'] as String?,
      minPrice: json['minPrice'] as int?,
      maxPrice: json['maxPrice'] as int?,
      saleStatus: json['saleStatus'] as String? ?? '1',
      memberCode: json['memberCode'] as String? ?? '',
    );
  }
}
