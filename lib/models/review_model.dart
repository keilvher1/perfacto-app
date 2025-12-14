class ReviewModel {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final List<String> imageUrls;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    this.imageUrls = const [],
    required this.createdAt,
  });

  // JSON에서 데이터 가져오기
  factory ReviewModel.fromJson(Map<String, dynamic> data) {
    return ReviewModel(
      id: data['id']?.toString() ?? '',
      userName: data['userName'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      imageUrls: data['imageUrls'] != null
          ? List<String>.from(data['imageUrls'])
          : [],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
