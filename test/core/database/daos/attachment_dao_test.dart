import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/database/daos/attachment_dao.dart';
import 'package:purenote/core/error/result.dart';

void main() {
  late AppDatabase db;
  late AttachmentDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = AttachmentDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AttachmentDao', () {
    test('insert and retrieve attachments', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      final result = await dao.insert(AttachmentsCompanion.insert(
        id: 'a1',
        noteId: 'n1',
        filePath: 'attachments/test.txt',
        mimeType: 'text/plain',
        fileName: 'test.txt',
        fileSize: 100,
      ));
      expect(result, isA<Ok>());

      final attachments = await dao.getByNoteId('n1');
      expect(attachments.length, 1);
      expect(attachments.first.fileName, 'test.txt');
    });

    test('delete attachment', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      await dao.insert(AttachmentsCompanion.insert(
        id: 'a1', noteId: 'n1',
        filePath: 'attachments/test.txt', mimeType: 'text/plain',
        fileName: 'test.txt', fileSize: 100,
      ));
      await dao.delete('a1');

      final attachments = await dao.getByNoteId('n1');
      expect(attachments, isEmpty);
    });

    test('watchByNoteId returns stream', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      final stream = dao.watchByNoteId('n1');
      await dao.insert(AttachmentsCompanion.insert(
        id: 'a1', noteId: 'n1',
        filePath: 'attachments/test.txt', mimeType: 'text/plain',
        fileName: 'test.txt', fileSize: 100,
      ));
      expect(stream, emits(isA<List<Attachment>>()));
    });
  });
}
