import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/providers/database_provider.dart';

part 'task_lists_provider.g.dart';

@Riverpod(keepAlive: true)
class TaskListNotes extends _$TaskListNotes {
  @override
  Stream<List<Note>> build() {
    final dao = ref.watch(noteDaoProvider);
    return dao.watchByType(1);
  }
}
