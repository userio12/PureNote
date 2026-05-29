import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/error/result.dart';
import 'package:purenote/core/error/app_error.dart';
import 'package:purenote/core/error/error_logger.dart';

class AttachmentDao {
  final AppDatabase _db;
  AttachmentDao(this._db);

  Stream<List<Attachment>> watchByNoteId(String noteId) {
    return (_db.select(_db.attachments)..where((a) => a.noteId.equals(noteId))).watch();
  }

  Future<Result<Attachment>> insert(AttachmentsCompanion companion) async {
    try {
      final attachment = await _db.into(_db.attachments).insertReturning(companion);
      return Ok(attachment);
    } catch (e, s) {
      ErrorLogger.logError('Failed to insert attachment', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to add attachment'));
    }
  }

  Future<Result<void>> delete(String id) async {
    try {
      await (_db.delete(_db.attachments)..where((a) => a.id.equals(id))).go();
      return const Ok(null);
    } catch (e, s) {
      ErrorLogger.logError('Failed to delete attachment', error: e, stackTrace: s);
      return Err(DatabaseError('Failed to remove attachment'));
    }
  }

  Future<List<Attachment>> getByNoteId(String noteId) {
    return (_db.select(_db.attachments)..where((a) => a.noteId.equals(noteId))).get();
  }
}
