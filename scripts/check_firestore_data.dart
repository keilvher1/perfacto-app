import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Firestore 데이터 구조 확인 스크립트
///
/// 실행: dart run scripts/check_firestore_data.dart
void main() async {
  print('🔍 Firestore 데이터 구조 확인 시작...\n');

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  try {
    // places 컬렉션에서 모든 문서 조회 (최대 100개)
    print('📊 places 컬렉션 조회 중...\n');
    final snapshot = await firestore.collection('places').limit(100).get();

    print('✅ 총 ${snapshot.docs.length}개의 장소 발견\n');
    print('=' * 80);

    // 카테고리별 카운트
    final Map<String, int> categoryCodeCount = {};
    final Map<dynamic, int> categoryCount = {};
    final List<Map<String, dynamic>> sampleData = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();

      // categoryCode 필드 카운트
      final categoryCode = data['categoryCode'];
      if (categoryCode != null) {
        categoryCodeCount[categoryCode.toString()] =
          (categoryCodeCount[categoryCode.toString()] ?? 0) + 1;
      }

      // category 필드 카운트
      final category = data['category'];
      if (category != null) {
        final key = category.toString();
        categoryCount[key] = (categoryCount[key] ?? 0) + 1;
      }

      // 처음 3개 샘플 데이터 저장
      if (sampleData.length < 3) {
        sampleData.add({
          'id': doc.id,
          'name': data['name'],
          'categoryCode': data['categoryCode'],
          'category': data['category'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'address': data['address'],
        });
      }
    }

    // categoryCode 필드 분포
    print('\n📍 categoryCode 필드 분포:');
    if (categoryCodeCount.isEmpty) {
      print('  ❌ categoryCode 필드가 없는 문서들입니다!');
    } else {
      categoryCodeCount.forEach((code, count) {
        print('  - "$code": $count개');
      });
    }

    // category 필드 분포
    print('\n📍 category 필드 분포:');
    if (categoryCount.isEmpty) {
      print('  ❌ category 필드가 없는 문서들입니다!');
    } else {
      categoryCount.forEach((cat, count) {
        print('  - $cat: $count개');
      });
    }

    // 샘플 데이터 출력
    print('\n📋 샘플 데이터 (처음 3개):');
    print('=' * 80);
    for (var i = 0; i < sampleData.length; i++) {
      final sample = sampleData[i];
      print('\n${i + 1}. ${sample['name']}');
      print('   ID: ${sample['id']}');
      print('   categoryCode: ${sample['categoryCode'] ?? "❌ 없음"}');
      print('   category: ${sample['category'] ?? "❌ 없음"}');
      print('   위치: ${sample['latitude']}, ${sample['longitude']}');
      print('   주소: ${sample['address'] ?? "없음"}');
    }

    print('\n' + '=' * 80);

    // 문제 진단
    print('\n🔍 진단 결과:');
    if (categoryCodeCount.isEmpty) {
      print('  ❌ 문제: 모든 문서에 categoryCode 필드가 없습니다!');
      print('  💡 해결책: category 필드를 categoryCode로 매핑하는 마이그레이션 필요');
    } else if (categoryCodeCount.length < 4) {
      print('  ⚠️  경고: 일부 카테고리만 데이터가 있습니다.');
      print('  💡 확인: ${['restaurant', 'cafe', 'attraction', 'accommodation']} 카테고리 모두 확인 필요');
    } else {
      print('  ✅ categoryCode 필드가 정상적으로 존재합니다.');
    }

    // 영일대해수욕장 찾기
    print('\n🔍 "영일대해수욕장" 검색 중...');
    final beachQuery = await firestore
        .collection('places')
        .where('name', isGreaterThanOrEqualTo: '영일대')
        .where('name', isLessThanOrEqualTo: '영일대\uf8ff')
        .get();

    if (beachQuery.docs.isNotEmpty) {
      final beachDoc = beachQuery.docs.first;
      final beachData = beachDoc.data();
      print('  ✅ 발견: ${beachData['name']}');
      print('  - categoryCode: ${beachData['categoryCode']}');
      print('  - category: ${beachData['category']}');
      print('  - 위치: ${beachData['latitude']}, ${beachData['longitude']}');
    } else {
      print('  ❌ 영일대해수욕장을 찾을 수 없습니다.');
    }

  } catch (e) {
    print('❌ 오류 발생: $e');
  }

  print('\n✅ 스크립트 완료');
}
