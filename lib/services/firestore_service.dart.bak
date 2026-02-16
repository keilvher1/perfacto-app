import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/place_model.dart';
import '../models/review_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // places 컬렉션 참조
  CollectionReference get _placesCollection => _firestore.collection('places');

  // reviews 컬렉션 참조
  CollectionReference get _reviewsCollection => _firestore.collection('reviews');

  // 모든 장소 가져오기
  Stream<List<PlaceModel>> getPlaces() {
    return _placesCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList();
    });
  }

  // 카테고리별 장소 가져오기
  Stream<List<PlaceModel>> getPlacesByCategory(String category) {
    return _placesCollection
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PlaceModel.fromFirestore(doc))
          .toList();
    });
  }

  // 특정 장소 가져오기
  Future<PlaceModel?> getPlaceById(String id) async {
    try {
      final doc = await _placesCollection.doc(id).get();
      if (doc.exists) {
        return PlaceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting place: $e');
      return null;
    }
  }

  // 장소 추가
  Future<String?> addPlace(PlaceModel place) async {
    try {
      final docRef = await _placesCollection.add(place.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding place: $e');
      return null;
    }
  }

  // 장소 업데이트
  Future<bool> updatePlace(String id, Map<String, dynamic> data) async {
    try {
      await _placesCollection.doc(id).update(data);
      return true;
    } catch (e) {
      print('Error updating place: $e');
      return false;
    }
  }

  // 장소 삭제
  Future<bool> deletePlace(String id) async {
    try {
      await _placesCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting place: $e');
      return false;
    }
  }

  // 샘플 데이터 추가 (초기 데이터 세팅용)
  Future<void> addSampleData() async {
    final samples = [
      // 기존 places에서 옮겨온 데이터
      PlaceModel(
        id: '',
        name: '영일대해수욕장',
        category: 'attraction',
        tag: '야경이 멋진',
        distance: '5.4km',
        address: '경북 포항시 북구 두호동 685-1',
        latitude: 36.056304,
        longitude: 129.378166,
        imageUrls: [],
        rating: 4.5,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '한동대학교',
        category: 'attraction',
        tag: '아름다운 캠퍼스',
        distance: '10.2km',
        address: '경북 포항시 북구 흥해읍 한동로 558',
        latitude: 36.102457,
        longitude: 129.390372,
        imageUrls: [],
        rating: 4.0,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '포항 해상 스카이워크',
        category: 'attraction',
        tag: '인생샷 명소',
        distance: '7.8km',
        address: '경북 포항시 남구 호미로 100',
        latitude: 36.073240,
        longitude: 129.414890,
        imageUrls: [],
        rating: 4.8,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '칠포해수욕장',
        category: 'attraction',
        tag: '조용한 바다',
        distance: '13.5km',
        address: '경북 포항시 북구 흥해읍 칠포리',
        latitude: 36.133135,
        longitude: 129.398787,
        imageUrls: [],
        rating: 4.3,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '포항여객선터미널',
        category: 'attraction',
        tag: '울릉도 가는 곳',
        distance: '5.1km',
        address: '경북 포항시 북구 두호동 686',
        latitude: 36.052359,
        longitude: 129.378906,
        imageUrls: [],
        rating: 4.0,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '포항경주공항',
        category: 'attraction',
        tag: '편리한 접근',
        distance: '15.3km',
        address: '경북 포항시 남구 대송면 공항로 90',
        latitude: 35.984260,
        longitude: 129.434099,
        imageUrls: [],
        rating: 4.2,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: 'POSCO',
        category: 'attraction',
        tag: '제철소',
        distance: '6.7km',
        address: '경북 포항시 남구 동해안로 6261',
        latitude: 36.009311,
        longitude: 129.392166,
        imageUrls: [],
        rating: 4.0,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '포항역 KTX',
        category: 'attraction',
        tag: '고속철도',
        distance: '8.1km',
        address: '경북 포항시 북구 포항역로 100',
        latitude: 36.071764,
        longitude: 129.342066,
        imageUrls: [],
        rating: 4.0,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '헤이안',
        category: 'restaurant',
        tag: '맛집',
        distance: '6.2km',
        address: '경북 포항시 북구 중앙로 267',
        latitude: 36.064805,
        longitude: 129.387367,
        imageUrls: [],
        rating: 4.7,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '하나로마트 포항점',
        category: 'attraction',
        tag: '신선한 식재료',
        distance: '9.4km',
        address: '경북 포항시 북구 새천년대로 1073',
        latitude: 36.082228,
        longitude: 129.398445,
        imageUrls: [],
        rating: 4.0,
        reviewCount: 0,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '환호공원',
        category: 'attraction',
        tag: '산책하기 좋은',
        distance: '7.0km',
        address: '경북 포항시 북구 환호동',
        latitude: 36.067597,
        longitude: 129.392003,
        imageUrls: [],
        rating: 4.0,
        reviewCount: 0,
        isSaved: false,
      ),
      // 기존 샘플 데이터
      PlaceModel(
        id: '',
        name: '죽도시장 횟집',
        category: 'restaurant',
        tag: '해산물',
        distance: '500m',
        address: '경상북도 포항시 북구 죽도동',
        latitude: 36.0415,
        longitude: 129.3650,
        imageUrls: [],
        rating: 4.5,
        reviewCount: 180,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '포항 과메기 맛집',
        category: 'restaurant',
        tag: '과메기',
        distance: '1.5km',
        address: '경상북도 포항시 남구 구룡포읍',
        latitude: 36.0050,
        longitude: 129.5680,
        imageUrls: [],
        rating: 4.8,
        reviewCount: 320,
        isSaved: true, // 저장된 장소
      ),
      PlaceModel(
        id: '',
        name: '영일대 바다카페',
        category: 'cafe',
        tag: '오션뷰',
        distance: '3.0km',
        address: '경상북도 포항시 북구 두호동',
        latitude: 36.0800,
        longitude: 129.3800,
        imageUrls: [],
        rating: 4.6,
        reviewCount: 215,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '스타벅스 포항점',
        category: 'cafe',
        tag: '카페',
        distance: '800m',
        address: '경상북도 포항시 북구 중앙로',
        latitude: 36.0320,
        longitude: 129.3650,
        imageUrls: [],
        rating: 4.3,
        reviewCount: 142,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '포항 힐튼 호텔',
        category: 'accommodation',
        tag: '호텔',
        distance: '2.5km',
        address: '경상북도 포항시 남구 포스코대로',
        latitude: 36.0250,
        longitude: 129.3550,
        imageUrls: [],
        rating: 4.7,
        reviewCount: 89,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '영일대 펜션',
        category: 'accommodation',
        tag: '펜션',
        distance: '4.0km',
        address: '경상북도 포항시 북구 두호동',
        latitude: 36.0850,
        longitude: 129.3820,
        imageUrls: [],
        rating: 4.4,
        reviewCount: 65,
        isSaved: false,
      ),
      PlaceModel(
        id: '',
        name: '호미곶 해맞이광장',
        category: 'attraction',
        tag: '일출명소',
        distance: '20km',
        address: '경상북도 포항시 남구 호미곶면',
        latitude: 36.0766,
        longitude: 129.5652,
        imageUrls: [],
        rating: 4.9,
        reviewCount: 680,
        isSaved: false,
      ),
    ];

    for (var place in samples) {
      await addPlace(place);
    }
  }

  // ===== 리뷰 관련 메서드 =====

  // 이미지 업로드 (Firebase Storage)
  Future<List<String>> uploadReviewImages(List<File> imageFiles) async {
    List<String> downloadUrls = [];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'reviews/$timestamp-$i.jpg';

        final ref = _storage.ref().child(fileName);
        final uploadTask = await ref.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }

      return downloadUrls;
    } catch (e) {
      print('Error uploading images: $e');
      return [];
    }
  }

  // 리뷰 추가
  Future<String?> addReview(ReviewModel review) async {
    try {
      final docRef = await _reviewsCollection.add(review.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding review: $e');
      return null;
    }
  }

  // 특정 장소의 리뷰 가져오기
  Stream<List<ReviewModel>> getReviewsByPlaceId(String placeId) {
    return _reviewsCollection
        .where('placeId', isEqualTo: placeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    });
  }

  // 모든 리뷰 가져오기
  Stream<List<ReviewModel>> getAllReviews() {
    return _reviewsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc))
          .toList();
    });
  }

  // 리뷰 삭제
  Future<bool> deleteReview(String id) async {
    try {
      await _reviewsCollection.doc(id).delete();
      return true;
    } catch (e) {
      print('Error deleting review: $e');
      return false;
    }
  }
}
