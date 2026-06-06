enum ApprovalStatus {
  /// 결재요청 (승인요청)
  request('0', '결재요청'),

  /// 결재완료 (판매중 / 승인됨)
  approved('1', '결재완료'),

  /// 반려 (결재반려)
  rejected('98', '반려'),

  /// 완료 (판매완료)
  done('99', '완료');

  final String code;
  final String label;

  const ApprovalStatus(this.code, this.label);

  factory ApprovalStatus.fromCode(String? code) {
    if (code == null) return ApprovalStatus.request;
    return ApprovalStatus.values.firstWhere(
      (e) => e.code == code,
      orElse: () => ApprovalStatus.request,
    );
  }
}
