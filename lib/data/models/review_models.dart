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
    return ReviewItem(
      reviewNo: (json['REVIEW_ID'] as num? ?? json['reviewNo'] as num? ?? 0).toInt(),
      rating: (json['RATING'] as num? ?? json['rating'] as num? ?? 0.0).toDouble(),
      contents: (json['CONTENTS'] ?? json['contents'] ?? '').toString(),
      filePaths: (json['FILE_PATHS'] ?? json['imageUrl'])?.toString(),
      writerId: (json['WRITER_ID'] ?? json['writerId'] ?? '').toString(),
      writeDt: (json['WRITE_DT'] ?? json['writeDt'] ?? '').toString(),
      writerNo: (json['WRITER_NO'] as num? ?? json['writerNo'] as num? ?? 0).toInt(),
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
