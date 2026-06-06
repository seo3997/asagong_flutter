import 'package:equatable/equatable.dart';

/// Dart representation of Kotlin's `OpUserVO`.
/// Contains user account details.
class OpUserVo extends Equatable {
  final int userNo;
  final String userId;
  final String password;
  final String userNm;
  final String cttpcSeCode;
  final String cttpc;
  final String email;
  final String areaCode;
  final String areaCodeNm;
  final String areaSeCodeS;
  final String areaSeCodeSNm;
  final String areaSeCodeD;
  final String userSttusCode;
  final String loginDt;
  final String userAge;
  final String birthDate;
  final String uniqueIdentifier;
  final String deviceId;
  final String duplicateIdentifier;
  final int gender;
  final String memberCode;
  final int citizenshipType;
  final String passwordHash;
  final String referrerId;
  final int registerNo;
  final String registDt;
  final int updusrNo;
  final String updtDt;
  final String provider;
  final String providerUserId;

  const OpUserVo({
    this.userNo = 0,
    this.userId = '',
    this.password = '',
    this.userNm = '',
    this.cttpcSeCode = '',
    this.cttpc = '',
    this.email = '',
    this.areaCode = '',
    this.areaCodeNm = '',
    this.areaSeCodeS = '',
    this.areaSeCodeSNm = '',
    this.areaSeCodeD = '',
    this.userSttusCode = '',
    this.loginDt = '',
    this.userAge = '',
    this.birthDate = '',
    this.uniqueIdentifier = '',
    this.deviceId = '',
    this.duplicateIdentifier = '',
    this.gender = 0,
    this.memberCode = '',
    this.citizenshipType = 0,
    this.passwordHash = '',
    this.referrerId = '',
    this.registerNo = 0,
    this.registDt = '',
    this.updusrNo = 0,
    this.updtDt = '',
    this.provider = '',
    this.providerUserId = '',
  });

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  factory OpUserVo.fromJson(Map<String, dynamic> json) {
    return OpUserVo(
      userNo: _parseInt(json['userNo']),
      userId: json['userId'] as String? ?? '',
      password: json['password'] as String? ?? '',
      userNm: json['userNm'] as String? ?? '',
      cttpcSeCode: json['cttpcSeCode'] as String? ?? '',
      cttpc: json['cttpc'] as String? ?? '',
      email: json['email'] as String? ?? '',
      areaCode: json['areaCode'] as String? ?? '',
      areaCodeNm: json['areaCodeNm'] as String? ?? '',
      areaSeCodeS: json['areaSeCodeS'] as String? ?? '',
      areaSeCodeSNm: json['areaSeCodeSNm'] as String? ?? '',
      areaSeCodeD: json['areaSeCodeD'] as String? ?? '',
      userSttusCode: json['userSttusCode'] as String? ?? '',
      loginDt: json['loginDt'] as String? ?? '',
      userAge: json['userAge'] as String? ?? '',
      birthDate: json['birthDate'] as String? ?? '',
      uniqueIdentifier: json['uniqueIdentifier'] as String? ?? '',
      deviceId: json['deviceId'] as String? ?? '',
      duplicateIdentifier: json['duplicateIdentifier'] as String? ?? '',
      gender: _parseInt(json['gender']),
      memberCode: json['memberCode'] as String? ?? '',
      citizenshipType: _parseInt(json['citizenshipType']),
      passwordHash: json['passwordHash'] as String? ?? '',
      referrerId: json['referrerId'] as String? ?? '',
      registerNo: _parseInt(json['registerNo']),
      registDt: json['registDt'] as String? ?? '',
      updusrNo: _parseInt(json['updusrNo']),
      updtDt: json['updtDt'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      providerUserId: json['providerUserId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userNo': userNo,
      'userId': userId,
      'password': password,
      'userNm': userNm,
      'cttpcSeCode': cttpcSeCode,
      'cttpc': cttpc,
      'email': email,
      'areaCode': areaCode,
      'areaCodeNm': areaCodeNm,
      'areaSeCodeS': areaSeCodeS,
      'areaSeCodeSNm': areaSeCodeSNm,
      'areaSeCodeD': areaSeCodeD,
      'userSttusCode': userSttusCode,
      'loginDt': loginDt,
      'userAge': userAge,
      'birthDate': birthDate,
      'uniqueIdentifier': uniqueIdentifier,
      'deviceId': deviceId,
      'duplicateIdentifier': duplicateIdentifier,
      'gender': gender,
      'memberCode': memberCode,
      'citizenshipType': citizenshipType,
      'passwordHash': passwordHash,
      'referrerId': referrerId,
      'registerNo': registerNo,
      'registDt': registDt,
      'updusrNo': updusrNo,
      'updtDt': updtDt,
      'provider': provider,
      'providerUserId': providerUserId,
    };
  }

  @override
  List<Object?> get props => [
        userNo,
        userId,
        password,
        userNm,
        cttpcSeCode,
        cttpc,
        email,
        areaCode,
        areaCodeNm,
        areaSeCodeS,
        areaSeCodeSNm,
        areaSeCodeD,
        userSttusCode,
        loginDt,
        userAge,
        birthDate,
        uniqueIdentifier,
        deviceId,
        duplicateIdentifier,
        gender,
        memberCode,
        citizenshipType,
        passwordHash,
        referrerId,
        registerNo,
        registDt,
        updusrNo,
        updtDt,
        provider,
        providerUserId,
      ];
}
