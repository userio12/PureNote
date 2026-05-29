import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/services/backup_service.dart';
import 'package:purenote/core/providers/database_provider.dart';

part 'backup_provider.g.dart';

@riverpod
Future<List<BackupLogData>> backupHistory(BackupHistoryRef ref) async {
  final db = ref.watch(databaseProvider);
  final service = BackupService(db);
  return service.getHistory();
}
