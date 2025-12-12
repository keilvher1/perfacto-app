import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String placeId;
  final String placeName;
  final String userId;
  final String reviewText;
  final List<String> imageUrls;
  final bool isLocationVerified;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.placeId,
    required this.placeName,
    required this.userId,
    required this.reviewText,
    required this.imageUrls,
    required this.isLocationVerified,
    required this.createdAt,
  });

  // Firestore에서 데이터 가져오기
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ReviewModel(
      id: doc.id,
      placeId: data['placeId'] ?? '',
      placeName: data['placeName'] ?? '',
      userId: data['userId'] ?? '',
      reviewText: data['reviewText'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      isLocationVerified: data['isLocationVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Firestore에 저장할 데이터
  Map<String, dynamic> toFirestore() {
    return {
      'placeId': placeId,
      'placeName': placeName,
      'userId': userId,
      'reviewText': reviewText,
      'imageUrls': imageUrls,
      'isLocationVerified': isLocationVerified,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
