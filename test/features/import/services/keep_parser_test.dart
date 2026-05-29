import 'package:flutter_test/flutter_test.dart';
import 'package:purenote/features/import/services/keep_parser.dart';

void main() {
  group('KeepParser', () {
    test('parses a simple note from HTML', () {
      final html = '''
        <html>
        <head><title>Shopping List</title></head>
        <body>
        <div dir="ltr">Milk, Eggs, Bread</div>
        <span class="tag">personal</span>
        <span class="tag">shopping</span>
        Created: 2024-01-15T10:00:00Z
        Updated: 2024-01-16T10:00:00Z
        </body></html>
      ''';

      final notes = KeepParser.parse(html);
      expect(notes.length, 1);
      expect(notes.first.title, 'Shopping List');
      expect(notes.first.content, 'Milk, Eggs, Bread');
      expect(notes.first.tags, containsAll(['personal', 'shopping']));
    });

    test('handles missing title gracefully', () {
      final html = '<html><body><div dir="ltr">Just content</div></body></html>';
      final notes = KeepParser.parse(html);
      expect(notes.length, 1);
      expect(notes.first.title, 'Untitled');
    });

    test('handles no content', () {
      final html = '<html><head><title>Empty note</title></head><body></body></html>';
      final notes = KeepParser.parse(html);
      expect(notes.length, 1);
      expect(notes.first.title, 'Empty note');
    });

    test('keepToDelta returns delta from note', () {
      final html = '<html><head><title>Test</title></head><body><div dir="ltr">Hello</div></body></html>';
      final notes = KeepParser.parse(html);
      final delta = KeepParser.keepToDelta(notes.first);
      expect(delta, isNotEmpty);
    });
  });
}
