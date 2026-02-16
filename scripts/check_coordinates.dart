import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';

/// Firestore places 컬렉션의 좌표 데이터 확인
///
/// 실행: dart run scripts/check_coordinates.dart
void main() async {
  print('🔍 Firestore 좌표 데이터 확인 시작...\n');

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

    // 좌표별 그룹화
    Map<String, List<Map<String, dynamic>>> coordsMap = {};

    print('🗺️  좌표 데이터 분석 중...\n');
    print('=' * 100);

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final name = data['name'] ?? 'Unknown';
      final latitude = data['latitude'];
      final longitude = data['longitude'];
      final category = data['category'];
      final categoryCode = data['categoryCode'];

      print('📍 ${name}');
      print('   ID: ${doc.id}');
      print('   좌표: ($latitude, $longitude)');
      print('   카테고리: $categoryCode (legacy: $category)');
      print('');

      // 좌표를 키로 사용하여 그룹화
      final key = '$latitude,$longitude';
      if (!coordsMap.containsKey(key)) {
        coordsMap[key] = [];
      }

      coordsMap[key]!.add({
        'id': doc.id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'category': categoryCode ?? category,
      });
    }

    print('=' * 100);
    print('\n📊 좌표별 장소 분포 분석\n');
    print('=' * 100);

    int duplicateCount = 0;
    coordsMap.forEach((coords, places) {
      if (places.length > 1) {
        duplicateCount++;
        print('\n⚠️  좌표 $coords에 ${places.length}개 장소가 겹쳐있습니다!');
        for (var place in places) {
          print('   - ${place['name']} (${place['category']})');
        }
      }
    });

    print('\n' + '=' * 100);
    print('\n📊 최종 통계');
    print('총 장소 수: ${snapshot.docs.length}개');
    print('고유 좌표 수: ${coordsMap.length}개');
    print('겹치는 좌표 수: $duplicateCount개');

    if (duplicateCount > 0) {
      print('\n⚠️  경고: $duplicateCount개 좌표에 여러 장소가 겹쳐있어 마커가 하나로 보일 수 있습니다!');
    } else if (coordsMap.length == 1) {
      print('\n⚠️  경고: 모든 장소가 같은 좌표(${coordsMap.keys.first})에 있습니다!');
    } else {
      print('\n✅ 모든 장소가 서로 다른 좌표에 있습니다.');
    }

    print('\n🎉 분석 완료!');

  } catch (e) {
    print('❌ 에러 발생: $e');
  }
}
