import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/database/daos/note_dao.dart';
import 'package:purenote/core/database/daos/label_dao.dart';
import 'package:purenote/core/database/daos/task_dao.dart';
import 'package:purenote/core/database/daos/attachment_dao.dart';
import 'package:purenote/core/database/daos/settings_dao.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
AppDatabase database(DatabaseRef ref) {
  return AppDatabase.noDb();
}

@Riverpod(keepAlive: true)
NoteDao noteDao(NoteDaoRef ref) {
  return NoteDao(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
LabelDao labelDao(LabelDaoRef ref) {
  return LabelDao(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
TaskDao taskDao(TaskDaoRef ref) {
  return TaskDao(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
AttachmentDao attachmentDao(AttachmentDaoRef ref) {
  return AttachmentDao(ref.watch(databaseProvider));
}

@Riverpod(keepAlive: true)
SettingsDao settingsDao(SettingsDaoRef ref) {
  return SettingsDao(ref.watch(databaseProvider));
}
