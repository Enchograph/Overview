import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:overview_client/app/planning/planning_models.dart';
import 'package:overview_client/app/planning/planning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const remoteEnabled = bool.fromEnvironment('OVERVIEW_E2E_REMOTE_ENABLED');
  const apiBaseUrl = String.fromEnvironment('OVERVIEW_API_BASE_URL');
  const email = String.fromEnvironment('OVERVIEW_E2E_EMAIL');
  const password = String.fromEnvironment('OVERVIEW_E2E_PASSWORD');
  const memoTitle = String.fromEnvironment('OVERVIEW_E2E_MEMO_TITLE');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'logs in and syncs a planning write through the real API',
    () async {
      expect(apiBaseUrl, isNotEmpty);
      expect(email, isNotEmpty);
      expect(password, isNotEmpty);
      expect(memoTitle, isNotEmpty);

      final authRepository = LocalAuthRepository(
        remoteRepository: HttpAuthRepository(baseUrl: apiBaseUrl),
      );
      final planningRepository = LocalPlanningRepository(
        remoteRepository: HttpPlanningRepository(
          baseUrl: apiBaseUrl,
          authSessionProvider: authRepository.fetchSession,
        ),
      );

      final session = await authRepository.login(
        email: email,
        password: password,
      );
      expect(session.email, email);

      await planningRepository.createMemo(title: memoTitle);

      final beforeSyncStatus = await planningRepository.fetchSyncStatus();
      expect(beforeSyncStatus.isRemoteEnabled, isTrue);
      expect(beforeSyncStatus.pendingOperationCount, 1);
      expect(beforeSyncStatus.phase, PlanningSyncPhase.idle);

      final syncStatus = await planningRepository.runSync();
      expect(syncStatus.phase, PlanningSyncPhase.success);
      expect(syncStatus.pendingOperationCount, 0);
      expect(syncStatus.pendingItemCount, 0);

      final memos = await planningRepository.fetchMemos();
      expect(memos.any((memo) => memo.title == memoTitle), isTrue);
      expect(
        memos.firstWhere((memo) => memo.title == memoTitle).syncState,
        SyncState.synced,
      );
    },
    skip: !remoteEnabled,
  );
}
