import 'package:flutter_test/flutter_test.dart';
import 'package:purenote/features/import/services/delta_converter.dart';

void main() {
  group('delta_converter', () {
    group('textToDelta', () {
      test('plain text converts to insert + newline', () {
        final delta = textToDelta('Hello world');
        expect(delta.length, 2);
        expect(delta.first['insert'], 'Hello world');
        expect(delta.last['insert'], '\n');
      });

      test('empty text returns empty insert + newline', () {
        final delta = textToDelta('');
        expect(delta.length, 2);
        expect(delta[0]['insert'], '');
        expect(delta[1]['insert'], '\n');
      });

      test('multiline text converts with newlines', () {
        final delta = textToDelta('Line 1\nLine 2');
        expect(delta.length, 4);
        expect(delta[0]['insert'], 'Line 1');
        expect(delta[1]['insert'], '\n');
        expect(delta[2]['insert'], 'Line 2');
        expect(delta[3]['insert'], '\n');
      });
    });

    group('htmlToDelta', () {
      test('extracts text from simple HTML', () {
        final delta = htmlToDelta('<div>Hello</div>');
        expect(delta, isNotEmpty);
        expect(delta.any((d) => d['insert'] == 'Hello'), isTrue);
      });

      test('returns newline for empty input', () {
        final delta = htmlToDelta('');
        expect(delta.length, 1);
        expect(delta.first['insert'], '\n');
      });

      test('handles nested tags', () {
        final delta = htmlToDelta('<p><b>Bold</b> and <i>italic</i></p>');
        expect(delta.any((d) => d['insert'] == 'Bold'), isTrue);
        expect(delta.any((d) => d['insert'] == 'and'), isTrue);
        expect(delta.any((d) => d['insert'] == 'italic'), isTrue);
      });
    });
  });
}
