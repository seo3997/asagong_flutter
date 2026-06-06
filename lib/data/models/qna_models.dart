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
    return QnaItem(
      qnaNo: (json['QNA_ID'] as num? ?? json['qnaNo'] as num? ?? 0).toInt(),
      title: (json['TITLE'] ?? json['title'] ?? '').toString(),
      contents: (json['CONTENTS'] ?? json['contents'] ?? '').toString(),
      secretYn: (json['SECRET_YN'] ?? json['secretYn'] ?? 'N').toString(),
      writerId: (json['WRITER_ID'] ?? json['writerId'] ?? '').toString(),
      writeDt: (json['WRITE_DT'] ?? json['writeDt'] ?? '').toString(),
      writerNo: (json['WRITER_NO'] as num? ?? json['writerNo'] as num? ?? 0).toInt(),
      answerContents: (json['ANSWER_CONTENTS'] ?? json['answerContents'])?.toString(),
      answerDt: (json['ANSWER_DT'] ?? json['answerDt'])?.toString(),
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
