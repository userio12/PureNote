import 'package:drift/drift.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/error/result.dart';
import 'package:purenote/core/error/app_error.dart';
import 'package:purenote/core/error/error_logger.dart';

class TaskDao {
  final AppDatabase _db;
  TaskDao(this._db);

  Stream<List<TaskItem>> watchByNoteId(String noteId) {
    return (_db.select(_db.taskItems)
          ..where((t) => t.noteId.equals(noteId))
          ..orderBy([(t) => OrderingTerm(expression: t.orderIndex, mode: OrderingMode.asc)]))
        .watch();
  }

  Future<Result<TaskItem>> insert(TaskItemsCompanion companion) async {
    try {
      final item = await _db.into(_db.taskItems).insertReturning(companion);
      return Ok(item);
    } catch (e, s) {
      ErrorLogger.logError('Failed to insert task item', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to create task item'));
    }
  }

  Future<Result<void>> update(TaskItemsCompanion companion) async {
    try {
      await (_db.update(_db.taskItems)..where((t) => t.id.equals(companion.id.value))).write(companion);
      return const Ok(null);
    } catch (e, s) {
      ErrorLogger.logError('Failed to update task item', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to update task item'));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await (_db.delete(_db.taskItems)..where((t) => t.id.equals(id))).go();
      return const Ok(null);
    } catch (e, s) {
      ErrorLogger.logError('Failed to delete task item', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to delete task item'));
    }
  }

  Future<Result<void>> deleteByNoteId(String noteId) async {
    try {
      await (_db.delete(_db.taskItems)..where((t) => t.noteId.equals(noteId))).go();
      return const Ok(null);
    } catch (e, s) {
      ErrorLogger.logError('Failed to delete task items for note', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to delete task items'));
    }
  }

  Future<Result<void>> toggleChecked(String id) async {
    try {
      final item = (_db.select(_db.taskItems)..where((t) => t.id.equals(id))).getSingleOrNull();
      final found = await item;
      if (found == null) return Err(DatabaseError('Task item not found'));
      await (_db.update(_db.taskItems)..where((t) => t.id.equals(id))).write(
        TaskItemsCompanion(isChecked: Value(!found.isChecked)),
      );
      return const Ok(null);
    } catch (e, s) {
      ErrorLogger.logError('Failed to toggle task item', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to toggle task item'));
    }
  }
}
