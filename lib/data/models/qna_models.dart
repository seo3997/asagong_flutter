class QnaItem {
  final int qnaNo;
  final String title;
  final String contents;
  final String secretYn;
  final String writerId;
  final String writeDt;
  final int writerNo;
  final String? answerContents;
  final String? answerDt;

  QnaItem({
    required this.qnaNo,
    required this.title,
    required this.contents,
    required this.secretYn,
    required this.writerId,
    required this.writeDt,
    required this.writerNo,
    this.answerContents,
    this.answerDt,
  });

  factory QnaItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        return double.tryParse(value)?.toInt() ?? int.tryParse(value) ?? 0;
      }
      return 0;
    }

    return QnaItem(
      qnaNo: parseInt(json['QNA_ID'] ?? json['qnaNo']),
      title: (json['TITLE'] ?? json['title'] ?? '').toString(),
      contents: (json['CONTENTS'] ?? json['contents'] ?? '').toString(),
      secretYn: (json['SECRET_YN'] ?? json['secretYn'] ?? 'N').toString(),
      writerId: (json['USER_NM'] ?? json['userNm'] ?? json['WRITER_ID'] ?? json['writerId'] ?? '').toString(),
      writeDt: (json['REGIST_DT'] ?? json['createDt'] ?? json['WRITE_DT'] ?? json['writeDt'] ?? '').toString(),
      writerNo: parseInt(json['USER_NO'] ?? json['userNo'] ?? json['userId'] ?? json['WRITER_NO'] ?? json['writerNo']),
      answerContents: (json['ANSWER_CONTENTS'] ?? json['answerContents'])?.toString(),
      answerDt: (json['ANSWERED_AT'] ?? json['answerDt'] ?? json['ANSWER_DT'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qnaNo': qnaNo,
      'title': title,
      'contents': contents,
      'secretYn': secretYn,
      'writerId': writerId,
      'writeDt': writeDt,
      'writerNo': writerNo,
      if (answerContents != null) 'answerContents': answerContents,
      if (answerDt != null) 'answerDt': answerDt,
    };
  }
}
