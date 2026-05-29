import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:purenote/features/import/services/quillpad_parser.dart';

void main() {
  group('QuillpadParser', () {
    test('parses a single note from JSON array', () {
      final json = jsonEncode([
        {
          'title': 'My Note',
          'content': [{'insert': 'Hello\n'}],
          'tags': ['personal'],
          'createdAt': 1705312800000,
          'updatedAt': 1705312800000,
        }
      ]);

      final notes = QuillpadParser.parse(json);
      expect(notes.length, 1);
      expect(notes.first.title, 'My Note');
      expect(notes.first.tags, contains('personal'));
    });

    test('parses from JSON object with notes key', () {
      final json = jsonEncode({
        'notes': [
          {
            'title': 'Note 1',
            'content': [{'insert': 'Content 1\n'}],
            'tags': [],
            'createdAt': 1705312800000,
            'updatedAt': 1705312800000,
          },
          {
            'title': 'Note 2',
            'content': [{'insert': 'Content 2\n'}],
            'tags': ['work'],
            'createdAt': 1705312800000,
            'updatedAt': 1705312800000,
          },
        ]
      });

      final notes = QuillpadParser.parse(json);
      expect(notes.length, 2);
    });

    test('handles missing title', () {
      final json = jsonEncode([
        {
          'content': [{'insert': 'Some content\n'}],
          'tags': [],
          'createdAt': 1705312800000,
          'updatedAt': 1705312800000,
        }
      ]);

      final notes = QuillpadParser.parse(json);
      expect(notes.length, 1);
      expect(notes.first.title, 'Untitled');
    });

    test('handles empty input', () {
      final notes = QuillpadParser.parse('[]');
      expect(notes, isEmpty);
    });

    test('handles invalid JSON', () {
      expect(() => QuillpadParser.parse('not json'), throwsException);
    });

    test('quillpadToDelta returns existing delta list', () {
      final json = jsonEncode([
        {
          'title': 'Test',
          'content': [{'insert': 'Hello\n'}],
          'tags': [],
          'createdAt': 1705312800000,
          'updatedAt': 1705312800000,
        }
      ]);

      final notes = QuillpadParser.parse(json);
      final delta = QuillpadParser.quillpadToDelta(notes.first);
      expect(delta.length, 1);
      expect(delta.first['insert'], 'Hello\n');
    });

    test('quillpadToDelta converts string content to delta', () {
      final json = jsonEncode([
        {
          'title': 'Test',
          'content': 'Plain text content',
          'tags': [],
          'createdAt': 1705312800000,
          'updatedAt': 1705312800000,
        }
      ]);

      final notes = QuillpadParser.parse(json);
      final delta = QuillpadParser.quillpadToDelta(notes.first);
      expect(delta, isNotEmpty);
    });
  });
}
