import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/planning/planning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('seeds local planning data on first load', () async {
    final repository = LocalPlanningRepository();

    final schedules = await repository.fetchSchedules();
    final tasks = await repository.fetchTasks();
    final memos = await repository.fetchMemos();

    expect(schedules, isNotEmpty);
    expect(tasks, isNotEmpty);
    expect(memos, isNotEmpty);
  });

  test('persists created memo across repository instances', () async {
    final repository = LocalPlanningRepository();

    await repository.createMemo(title: 'Prepare local storage QA');

    final anotherRepository = LocalPlanningRepository();
    final memos = await anotherRepository.fetchMemos();

    expect(
      memos.any((memo) => memo.title == 'Prepare local storage QA'),
      isTrue,
    );
  });

  test('persists memo archived state across repository instances', () async {
    final repository = LocalPlanningRepository();
    final memo = (await repository.fetchMemos()).first;

    await repository.setMemoArchived(memoId: memo.id, archived: true);

    final anotherRepository = LocalPlanningRepository();
    final archivedMemo = (await anotherRepository.fetchMemos())
        .firstWhere((item) => item.id == memo.id);

    expect(archivedMemo.isArchived, isTrue);
    expect(archivedMemo.archivedAt, isNotNull);
  });
}
