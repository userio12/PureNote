import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/database/daos/task_dao.dart';
import 'package:purenote/core/error/result.dart';

void main() {
  late AppDatabase db;
  late TaskDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = TaskDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskDao', () {
    test('insert and retrieve task items', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      final result = await dao.insert(TaskItemsCompanion.insert(id: 't1', noteId: 'n1', content: const Value('Buy milk')));
      expect(result, isA<Ok>());

      final items = await dao.watchByNoteId('n1').first;
      expect(items.length, 1);
      expect(items.first.content, 'Buy milk');
    });

    test('update task item', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      await dao.insert(TaskItemsCompanion.insert(id: 't1', noteId: 'n1', content: const Value('Buy milk')));
      await dao.update(TaskItemsCompanion(id: Value('t1'), content: Value('Buy oat milk')));

      final items = await dao.watchByNoteId('n1').first;
      expect(items.first.content, 'Buy oat milk');
    });

    test('toggle checked', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      await dao.insert(TaskItemsCompanion.insert(id: 't1', noteId: 'n1', content: const Value('Buy milk')));
      final result = await dao.toggleChecked('t1');
      expect(result, isA<Ok>());

      final items = await dao.watchByNoteId('n1').first;
      expect(items.first.isChecked, isTrue);
    });

    test('delete task item', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      await dao.insert(TaskItemsCompanion.insert(id: 't1', noteId: 'n1', content: const Value('Buy milk')));
      await dao.delete('t1');

      final items = await dao.watchByNoteId('n1').first;
      expect(items, isEmpty);
    });

    test('delete by note id', () async {
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));
      await dao.insert(TaskItemsCompanion.insert(id: 't1', noteId: 'n1', content: const Value('Buy milk')));
        await dao.insert(TaskItemsCompanion.insert(id: 't2', noteId: 'n1', content: const Value('Buy eggs')));
      await dao.deleteByNoteId('n1');

      final items = await dao.watchByNoteId('n1').first;
      expect(items, isEmpty);
    });
  });
}
