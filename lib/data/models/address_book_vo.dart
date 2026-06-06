class TbAddressBookVo {
  final int? addressNo;
  final String recipientName;
  final String recipientPhone;
  final String zipCode;
  final String addressMain;
  final String addressDetail;
  final int isDefault;
  final String? memo;

  TbAddressBookVo({
    this.addressNo,
    required this.recipientName,
    required this.recipientPhone,
    required this.zipCode,
    required this.addressMain,
    required this.addressDetail,
    required this.isDefault,
    this.memo,
  });

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toInt();
    if (val is String) {
      return int.tryParse(val) ?? double.tryParse(val)?.toInt();
    }
    return null;
  }

  static int _parseIsDefault(dynamic val) {
    if (val == null) return 0;
    final s = val.toString().trim().toUpperCase();
    if (s == '1' || s == '1.0' || s == 'Y' || s == 'TRUE') {
      return 1;
    }
    return 0;
  }

  factory TbAddressBookVo.fromJson(Map<String, dynamic> json) {
    return TbAddressBookVo(
      addressNo: _parseInt(json['ADDRESS_NO'] ?? json['addressNo']),
      recipientName: (json['RECIPIENT_NAME'] ?? json['recipientName'] ?? '').toString(),
      recipientPhone: (json['RECIPIENT_PHONE'] ?? json['recipientPhone'] ?? '').toString(),
      zipCode: (json['ZIP_CODE'] ?? json['zipCode'] ?? '').toString(),
      addressMain: (json['ADDRESS_MAIN'] ?? json['addressMain'] ?? '').toString(),
      addressDetail: (json['ADDRESS_DETAIL'] ?? json['addressDetail'] ?? '').toString(),
      isDefault: _parseIsDefault(json['IS_DEFAULT'] ?? json['isDefault']),
      memo: (json['MEMO'] ?? json['memo'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (addressNo != null) 'addressNo': addressNo,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'zipCode': zipCode,
      'addressMain': addressMain,
      'addressDetail': addressDetail,
      'isDefault': isDefault,
      if (memo != null) 'memo': memo,
    };
  }
}
