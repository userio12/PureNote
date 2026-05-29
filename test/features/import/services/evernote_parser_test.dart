import 'package:flutter_test/flutter_test.dart';
import 'package:purenote/features/import/services/evernote_parser.dart';

void main() {
  group('EvernoteParser', () {
    test('parses a simple ENEX note', () {
      final enex = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-export SYSTEM "http://xml.evernote.com/pub/evernote-export3.dtd">
<en-export export-date="2024-01-15T10:00:00Z" application="Evernote" version="10.0">
  <note>
    <title>Meeting Notes</title>
    <content><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml2.dtd">
<en-note><div>Discuss Q1 roadmap</div></en-note>]]></content>
    <tag>work</tag>
    <tag>meetings</tag>
    <created>2024-01-14T09:00:00Z</created>
    <updated>2024-01-15T10:00:00Z</updated>
  </note>
</en-export>''';

      final notes = EvernoteParser.parse(enex);
      expect(notes.length, 1);
      expect(notes.first.title, 'Meeting Notes');
      expect(notes.first.tags, containsAll(['work', 'meetings']));
    });

    test('parses multiple notes from ENEX', () {
      final enex = '''<?xml version="1.0" encoding="UTF-8"?>
<en-export>
  <note>
    <title>Note 1</title>
    <content><![CDATA[<en-note>Content 1</en-note>]]></content>
    <created>2024-01-14T09:00:00Z</created>
    <updated>2024-01-15T10:00:00Z</updated>
  </note>
  <note>
    <title>Note 2</title>
    <content><![CDATA[<en-note>Content 2</en-note>]]></content>
    <created>2024-01-14T09:00:00Z</created>
    <updated>2024-01-15T10:00:00Z</updated>
  </note>
</en-export>''';

      final notes = EvernoteParser.parse(enex);
      expect(notes.length, 2);
    });

    test('handles missing title', () {
      final enex = '''<?xml version="1.0"?>
<en-export>
  <note>
    <content><![CDATA[<en-note>Content</en-note>]]></content>
    <created>2024-01-14T09:00:00Z</created>
    <updated>2024-01-15T10:00:00Z</updated>
  </note>
</en-export>''';

      final notes = EvernoteParser.parse(enex);
      expect(notes.length, 1);
      expect(notes.first.title, 'Untitled');
    });

    test('handles empty input', () {
      expect(() => EvernoteParser.parse(''), throwsA(isA<Exception>()));
      expect(() => EvernoteParser.parse('not xml'), throwsA(isA<Exception>()));
    });

    test('enmlToDelta converts ENML to delta', () {
      final delta = EvernoteParser.enmlToDelta('<div>Hello world</div>');
      expect(delta, isNotEmpty);
      expect(delta.any((d) => d['insert'] == 'Hello world'), isTrue);
    });
  });
}
