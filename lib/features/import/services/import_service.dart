import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:purenote/core/database/daos/note_dao.dart';
import 'package:purenote/core/database/daos/label_dao.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/error/result.dart';
import 'package:purenote/features/import/services/keep_parser.dart';
import 'package:purenote/features/import/services/evernote_parser.dart';
import 'package:purenote/features/import/services/quillpad_parser.dart';

enum ImportSource { keep, evernote, quillpad }

class ImportResult {
  final int imported;
  final int skipped;
  final int failed;
  final List<String> errors;

  ImportResult({
    required this.imported,
    required this.skipped,
    required this.failed,
    required this.errors,
  });
}

class ImportProgress {
  final int current;
  final int total;
  final String message;

  ImportProgress({required this.current, required this.total, required this.message});
}

class ImportService {
  final NoteDao _noteDao;
  final LabelDao _labelDao;

  ImportService(this._noteDao, this._labelDao);

  Stream<ImportProgress> importFile(String filePath, ImportSource source) async* {
    final file = File(filePath);
    if (!await file.exists()) {
      yield* Stream.error('File not found');
      return;
    }

    final content = await file.readAsString();
    var imported = 0;
    var skipped = 0;
    var failed = 0;
    final errors = <String>[];

    try {
      switch (source) {
        case ImportSource.keep:
          final notes = KeepParser.parse(content);
          for (var i = 0; i < notes.length; i++) {
            yield ImportProgress(current: i, total: notes.length, message: 'Importing Keep note ${i + 1}...');
            try {
              final success = await _importNote(
                title: notes[i].title,
                delta: KeepParser.keepToDelta(notes[i]),
                tags: notes[i].tags,
                createdAt: notes[i].createdAt,
                updatedAt: notes[i].updatedAt,
              );
              if (success) { imported++; } else { failed++; }
            } catch (e) {
              failed++;
              errors.add('Error: $e');
            }
          }
          break;

        case ImportSource.evernote:
          final notes = EvernoteParser.parse(content);
          for (var i = 0; i < notes.length; i++) {
            yield ImportProgress(current: i, total: notes.length, message: 'Importing Evernote note ${i + 1}...');
            try {
              final success = await _importNote(
                title: notes[i].title,
                delta: EvernoteParser.enmlToDelta(notes[i].content),
                tags: notes[i].tags,
                createdAt: notes[i].createdAt,
                updatedAt: notes[i].updatedAt,
              );
              if (success) { imported++; } else { failed++; }
            } catch (e) {
              failed++;
              errors.add('Error: $e');
            }
          }
          break;

        case ImportSource.quillpad:
          final notes = QuillpadParser.parse(content);
          for (var i = 0; i < notes.length; i++) {
            yield ImportProgress(current: i, total: notes.length, message: 'Importing note ${i + 1}...');
            try {
              final success = await _importNote(
                title: notes[i].title,
                delta: QuillpadParser.quillpadToDelta(notes[i]),
                tags: notes[i].tags,
                createdAt: notes[i].createdAt,
                updatedAt: notes[i].updatedAt,
              );
              if (success) { imported++; } else { failed++; }
            } catch (e) {
              failed++;
              errors.add('Error: $e');
            }
          }
          break;
      }
    } catch (e) {
      yield* Stream.error('Import failed: $e');
      return;
    }

    yield ImportProgress(
      current: imported + skipped + failed,
      total: imported + skipped + failed,
      message: 'Done: $imported imported, $skipped skipped, $failed failed',
    );
  }

  Future<bool> _importNote({
    required String title,
    required List<Map<String, dynamic>> delta,
    required List<String> tags,
    required int createdAt,
    required int updatedAt,
  }) async {
    final id = const Uuid().v4();
    final json = jsonEncode(delta);
    final result = await _noteDao.insert(id: id, createdAt: createdAt, updatedAt: updatedAt);
    if (result case Ok(:final value)) {
      await _noteDao.updateFields(NotesCompanion(
        id: Value(value.id),
        title: Value(title),
        content: Value(json),
      ));
      await _importTags(tags, value.id);
      return true;
    }
    return false;
  }

  Future<void> _importTags(List<String> tagNames, String noteId) async {
    for (final name in tagNames) {
      if (name.trim().isEmpty) continue;
      final existingLabels = await _labelDao.getAll();
      var label = existingLabels.where((l) => l.name.toLowerCase() == name.trim().toLowerCase()).firstOrNull;

      if (label == null) {
        final id = const Uuid().v4();
        final result = await _labelDao.insert(LabelsCompanion.insert(id: id, name: name.trim()));
        if (result case Ok(:final value)) label = value;
      }

      if (label != null) {
        await _labelDao.assignLabelToNote(noteId, label.id);
      }
    }
  }
}
