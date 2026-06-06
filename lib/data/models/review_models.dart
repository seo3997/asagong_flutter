class ReviewItem {
  final int reviewNo;
  final double rating;
  final String contents;
  final String? filePaths;
  final String writerId;
  final String writeDt;
  final int writerNo;

  ReviewItem({
    required this.reviewNo,
    required this.rating,
    required this.contents,
    this.filePaths,
    required this.writerId,
    required this.writeDt,
    required this.writerNo,
  });

  factory ReviewItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        return double.tryParse(value)?.toInt() ?? int.tryParse(value) ?? 0;
      }
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }
      return 0.0;
    }

    return ReviewItem(
      reviewNo: parseInt(json['REVIEW_ID'] ?? json['reviewNo']),
      rating: parseDouble(json['RATING'] ?? json['rating']),
      contents: (json['CONTENTS'] ?? json['contents'] ?? '').toString(),
      filePaths: (json['FILE_PATHS'] ?? json['imageUrl'])?.toString(),
      writerId: (json['USER_NM'] ?? json['userNm'] ?? json['WRITER_ID'] ?? json['writerId'] ?? '').toString(),
      writeDt: (json['REGIST_DT'] ?? json['createDt'] ?? json['WRITE_DT'] ?? json['writeDt'] ?? '').toString(),
      writerNo: parseInt(json['USER_NO'] ?? json['userNo'] ?? json['userId'] ?? json['WRITER_NO'] ?? json['writerNo']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewNo': reviewNo,
      'rating': rating,
      'contents': contents,
      if (filePaths != null) 'filePaths': filePaths,
      'writerId': writerId,
      'writeDt': writeDt,
      'writerNo': writerNo,
    };
  }
}
