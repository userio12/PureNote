import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/providers/database_provider.dart';

part 'task_items_provider.g.dart';

@Riverpod(keepAlive: true)
Stream<List<TaskItem>> taskItemsByNote(TaskItemsByNoteRef ref, String noteId) {
  final dao = ref.watch(taskDaoProvider);
  return dao.watchByNoteId(noteId);
}
