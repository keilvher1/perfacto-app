import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfacto/providers/firestore_provider.dart';

/// Firestore Provider 테스트
///
/// 테스트 실행: flutter test test/providers/firestore_provider_test.dart
void main() {
  group('Firestore Provider Tests', () {
    test('allPlacesProvider should return list of places', () async {
      // ProviderContainer 생성
      final container = ProviderContainer();

      // Provider가 데이터를 로드할 때까지 대기
      final places = await container.read(allPlacesProvider.future);

      // 검증
      expect(places, isA<List>());
      // Note: 실제 Firebase 연결이 필요하므로 mock을 사용하거나 통합 테스트로 진행

      // Container dispose
      container.dispose();
    });

    test('SavedPlacesNotifier should manage saved places', () {
      // ProviderContainer 생성
      final container = ProviderContainer();

      // 초기 상태 확인
      final initialState = container.read(savedPlacesProvider);
      expect(initialState, isEmpty);

      // 장소 저장
      container.read(savedPlacesProvider.notifier).savePlace(1);
      final stateAfterSave = container.read(savedPlacesProvider);
      expect(stateAfterSave, contains(1));

      // 장소 저장 취소
      container.read(savedPlacesProvider.notifier).unsavePlace(1);
      final stateAfterUnsave = container.read(savedPlacesProvider);
      expect(stateAfterUnsave, isEmpty);

      // Container dispose
      container.dispose();
    });

    test('SavedPlacesNotifier.isSaved should return correct status', () {
      // ProviderContainer 생성
      final container = ProviderContainer();

      // 장소 저장
      container.read(savedPlacesProvider.notifier).savePlace(1);

      // 저장 상태 확인
      final isSaved = container.read(savedPlacesProvider.notifier).isSaved(1);
      expect(isSaved, isTrue);

      // 저장되지 않은 장소 확인
      final isNotSaved = container.read(savedPlacesProvider.notifier).isSaved(999);
      expect(isNotSaved, isFalse);

      // Container dispose
      container.dispose();
    });
  });
}
