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

  factory TbAddressBookVo.fromJson(Map<String, dynamic> json) {
    return TbAddressBookVo(
      addressNo: json['ADDRESS_NO'] as int? ?? json['addressNo'] as int?,
      recipientName: (json['RECIPIENT_NAME'] ?? json['recipientName'] ?? '').toString(),
      recipientPhone: (json['RECIPIENT_PHONE'] ?? json['recipientPhone'] ?? '').toString(),
      zipCode: (json['ZIP_CODE'] ?? json['zipCode'] ?? '').toString(),
      addressMain: (json['ADDRESS_MAIN'] ?? json['addressMain'] ?? '').toString(),
      addressDetail: (json['ADDRESS_DETAIL'] ?? json['addressDetail'] ?? '').toString(),
      isDefault: (json['IS_DEFAULT'] as num? ?? json['isDefault'] as num? ?? 0).toInt(),
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
