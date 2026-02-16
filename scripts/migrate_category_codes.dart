import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Firestore places 컬렉션의 category 필드를 categoryCode로 마이그레이션
///
/// 실행: dart run scripts/migrate_category_codes.dart
void main() async {
  print('🚀 Firestore 카테고리 마이그레이션 시작...\n');

  try {
    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase 초기화 완료\n');

    final firestore = FirebaseFirestore.instance;
    final placesCollection = firestore.collection('places');

    // 모든 places 문서 조회
    print('📊 places 컬렉션 조회 중...');
    final snapshot = await placesCollection.get();
    print('✅ 총 ${snapshot.docs.length}개의 장소 문서 발견\n');

    if (snapshot.docs.isEmpty) {
      print('⚠️  장소 문서가 없습니다. 종료합니다.');
      return;
    }

    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    // 카테고리 ID → 코드 매핑
    Map<int, String> categoryMap = {
      1: 'restaurant',
      2: 'accommodation',
      3: 'cafe',
      4: 'attraction',
    };

    print('🔄 마이그레이션 시작...\n');
    print('=' * 80);

    for (var doc in snapshot.docs) {
      try {
        final data = doc.data();
        final docId = doc.id;
        final name = data['name'] ?? 'Unknown';

        // 이미 categoryCode가 있는지 확인
        if (data['categoryCode'] != null) {
          print('⏭️  건너뜀: $name (ID: $docId)');
          print('   이미 categoryCode가 있음: ${data['categoryCode']}\n');
          skippedCount++;
          continue;
        }

        // category 필드에서 ID 추출
        int? categoryId;
        if (data['category'] is int) {
          categoryId = data['category'];
        } else if (data['category'] is Map) {
          final categoryMap = data['category'] as Map<String, dynamic>;
          categoryId = categoryMap['id'];
        }

        if (categoryId == null) {
          print('⚠️  경고: $name (ID: $docId)');
          print('   category 필드가 없거나 유효하지 않음');
          print('   데이터: ${data['category']}\n');
          errorCount++;
          continue;
        }

        // categoryCode 생성
        final categoryCode = categoryMap[categoryId] ?? 'attraction';

        // Firestore 문서 업데이트
        await placesCollection.doc(docId).update({
          'categoryCode': categoryCode,
        });

        print('✅ 업데이트: $name (ID: $docId)');
        print('   category: $categoryId → categoryCode: $categoryCode\n');
        updatedCount++;

        // API 호출 제한 방지를 위한 약간의 딜레이
        await Future.delayed(Duration(milliseconds: 100));

      } catch (e) {
        print('❌ 에러: ${doc.id}');
        print('   에러 내용: $e\n');
        errorCount++;
      }
    }

    print('=' * 80);
    print('\n📊 마이그레이션 완료!\n');
    print('총 문서 수: ${snapshot.docs.length}');
    print('✅ 업데이트됨: $updatedCount개');
    print('⏭️  건너뜀: $skippedCount개 (이미 categoryCode 있음)');
    print('❌ 에러: $errorCount개');
    print('\n🎉 마이그레이션 성공!');

  } catch (e) {
    print('❌ 치명적 에러 발생: $e');
  }
}
