import 'package:equatable/equatable.dart';

class BranchInfoVo extends Equatable {
  final int branchId;
  final String? branchCode;
  final String? branchName;
  final String? logoImageUrl;
  final String? branchStatus;
  final String? tossClientKey;
  final String? bankCd;
  final String? accountNo;
  final String? accountHolder;
  final int baseShippingFee;
  final int freeShippingThreshold;

  const BranchInfoVo({
    required this.branchId,
    this.branchCode,
    this.branchName,
    this.logoImageUrl,
    this.branchStatus,
    this.tossClientKey,
    this.bankCd,
    this.accountNo,
    this.accountHolder,
    this.baseShippingFee = 0,
    this.freeShippingThreshold = 0,
  });

  factory BranchInfoVo.fromJson(Map<String, dynamic> json) {
    return BranchInfoVo(
      branchId: json['BRANCH_ID'] as int? ?? json['branchId'] as int? ?? 0,
      branchCode: json['BRANCH_CODE'] as String? ?? json['branchCode'] as String?,
      branchName: json['BRANCH_NAME'] as String? ?? json['branchName'] as String?,
      logoImageUrl: json['LOGO_IMAGE_URL'] as String? ?? json['logoImageUrl'] as String?,
      branchStatus: json['BRANCH_STATUS'] as String? ?? json['branchStatus'] as String?,
      tossClientKey: json['TOSS_CLIENT_KEY'] as String? ?? json['tossClientKey'] as String?,
      bankCd: json['BANK_CD'] as String? ?? json['bankCd'] as String?,
      accountNo: json['ACCOUNT_NO'] as String? ?? json['accountNo'] as String?,
      accountHolder: json['ACCOUNT_HOLDER'] as String? ?? json['accountHolder'] as String?,
      baseShippingFee: json['BASE_SHIPPING_FEE'] as int? ?? json['baseShippingFee'] as int? ?? 0,
      freeShippingThreshold: json['FREE_SHIPPING_THRESHOLD'] as int? ?? json['freeShippingThreshold'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BRANCH_ID': branchId,
      'BRANCH_CODE': branchCode,
      'BRANCH_NAME': branchName,
      'LOGO_IMAGE_URL': logoImageUrl,
      'BRANCH_STATUS': branchStatus,
      'TOSS_CLIENT_KEY': tossClientKey,
      'BANK_CD': bankCd,
      'ACCOUNT_NO': accountNo,
      'ACCOUNT_HOLDER': accountHolder,
      'BASE_SHIPPING_FEE': baseShippingFee,
      'FREE_SHIPPING_THRESHOLD': freeShippingThreshold,
    };
  }

  @override
  List<Object?> get props => [
        branchId,
        branchCode,
        branchName,
        logoImageUrl,
        branchStatus,
        tossClientKey,
        bankCd,
        accountNo,
        accountHolder,
        baseShippingFee,
        freeShippingThreshold,
      ];
}

/// Dart representation of Kotlin's `LoginResponse`.
/// Represents the authentication response from the backend.
class LoginResponse extends Equatable {
  final int resultCode;
  final String? token;
  final String? loginIdx;
  final String? loginSi;
  final String? loginGu;
  final String? loginSex;
  final String? loginAge;
  final String? loginNm;
  final String? memberCode;
  final String? loginId;
  final String loginCd;
  final String loginSocialId;
  final String loginPwd;
  final BranchInfoVo? branchInfo;

  const LoginResponse({
    this.resultCode = 0,
    this.token,
    this.loginIdx,
    this.loginSi,
    this.loginGu,
    this.loginSex,
    this.loginAge,
    this.loginNm,
    this.memberCode,
    this.loginId,
    this.loginCd = '',
    this.loginSocialId = '',
    this.loginPwd = '',
    this.branchInfo,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      resultCode: json['resultCode'] as int? ?? 0,
      token: json['token'] as String?,
      loginIdx: json['login_idx'] as String?,
      loginSi: json['login_si'] as String?,
      loginGu: json['login_gu'] as String?,
      loginSex: json['login_sex'] as String?,
      loginAge: json['login_age'] as String?,
      loginNm: json['login_nm'] as String?,
      memberCode: json['member_code'] as String?,
      loginId: json['login_id'] as String?,
      loginCd: json['login_cd'] as String? ?? '',
      loginSocialId: json['login_social_id'] as String? ?? '',
      loginPwd: json['login_pwd'] as String? ?? '',
      branchInfo: (json['branch_info'] ?? json['BRANCH_INFO']) != null
          ? BranchInfoVo.fromJson((json['branch_info'] ?? json['BRANCH_INFO']) as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resultCode': resultCode,
      'token': token,
      'login_idx': loginIdx,
      'login_si': loginSi,
      'login_gu': loginGu,
      'login_sex': loginSex,
      'login_age': loginAge,
      'login_nm': loginNm,
      'member_code': memberCode,
      'login_id': loginId,
      'login_cd': loginCd,
      'login_social_id': loginSocialId,
      'login_pwd': loginPwd,
      'branch_info': branchInfo?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        resultCode,
        token,
        loginIdx,
        loginSi,
        loginGu,
        loginSex,
        loginAge,
        loginNm,
        memberCode,
        loginId,
        loginCd,
        loginSocialId,
        loginPwd,
        branchInfo,
      ];
}
