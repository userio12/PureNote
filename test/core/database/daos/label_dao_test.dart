import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/database/daos/label_dao.dart';
import 'package:purenote/core/error/result.dart';

void main() {
  late AppDatabase db;
  late LabelDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = LabelDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LabelDao', () {
    test('insert and retrieve labels', () async {
      final result = await dao.insert(LabelsCompanion.insert(id: 'l1', name: 'Work'));
      expect(result, isA<Ok>());

      final labels = await dao.getAll();
      expect(labels.length, 1);
      expect(labels.first.name, 'Work');
    });

    test('update label name', () async {
      await dao.insert(LabelsCompanion.insert(id: 'l1', name: 'Work'));
      await dao.update(LabelsCompanion(id: Value('l1'), name: Value('Personal')));

      final labels = await dao.getAll();
      expect(labels.first.name, 'Personal');
    });

    test('delete label', () async {
      await dao.insert(LabelsCompanion.insert(id: 'l1', name: 'Work'));
      final result = await dao.delete('l1');
      expect(result, isA<Ok>());

      final labels = await dao.getAll();
      expect(labels, isEmpty);
    });

    test('assign and remove label from note', () async {
      await dao.insert(LabelsCompanion.insert(id: 'l1', name: 'Work'));
      await db.into(db.notes).insert(NotesCompanion.insert(id: 'n1', createdAt: 1000, updatedAt: 1000));

      final result = await dao.assignLabelToNote('n1', 'l1');
      expect(result, isA<Ok>());

      var noteLabels = await dao.getLabelsForNote('n1');
      expect(noteLabels.length, 1);
      expect(noteLabels.first.name, 'Work');

      await dao.removeLabelFromNote('n1', 'l1');
      noteLabels = await dao.getLabelsForNote('n1');
      expect(noteLabels, isEmpty);
    });

    test('watchAll returns stream', () async {
      final stream = dao.watchAll();
      await dao.insert(LabelsCompanion.insert(id: 'l1', name: 'Work'));
      expect(stream, emits(isA<List<Label>>()));
    });
  });
}
