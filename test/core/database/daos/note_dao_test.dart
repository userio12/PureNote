import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/database/daos/note_dao.dart';
import 'package:purenote/core/error/result.dart';

void main() {
  late AppDatabase db;
  late NoteDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = NoteDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('NoteDao', () {
    test('insert and retrieve a note', () async {
      final result = await dao.insert(id: 'test1', createdAt: 1000, updatedAt: 1000);
      expect(result, isA<Ok>());

      final notes = await dao.getAll();
      expect(notes.length, 1);
      expect(notes.first.id, 'test1');
    });

    test('update note fields', () async {
      await dao.insert(id: 'test1', createdAt: 1000, updatedAt: 1000);
      await dao.updateFields(NotesCompanion(
        id: Value('test1'),
        title: Value('Updated Title'),
        content: Value('Updated content'),
      ));

      final notes = await dao.getAll();
      expect(notes.first.title, 'Updated Title');
      expect(notes.first.content, 'Updated content');
    });

    test('delete a note', () async {
      await dao.insert(id: 'test1', createdAt: 1000, updatedAt: 1000);
      final result = await dao.delete('test1');
      expect(result, isA<Ok>());

      final notes = await dao.getAll();
      expect(notes, isEmpty);
    });

    test('search returns matching notes', () async {
      await dao.insert(id: '1', createdAt: 1000, updatedAt: 1000);
      await dao.updateFields(NotesCompanion(id: Value('1'), title: Value('Apple')));
      await dao.insert(id: '2', createdAt: 1000, updatedAt: 1000);
      await dao.updateFields(NotesCompanion(id: Value('2'), title: Value('Banana')));
      await dao.insert(id: '3', createdAt: 1000, updatedAt: 1000);
      await dao.updateFields(NotesCompanion(id: Value('3'), title: Value('Cherry'), content: Value('Apple pie')));

      final results = await dao.search('apple').first;
      expect(results.length, 2);
      expect(results.any((n) => n.id == '1'), isTrue);
      expect(results.any((n) => n.id == '3'), isTrue);
    });
  });
}
