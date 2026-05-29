import 'package:flutter_test/flutter_test.dart';
import 'package:purenote/core/utils/delta_utils.dart';

void main() {
  group('stripQuillDelta', () {
    test('returns empty string for empty input', () {
      expect(stripQuillDelta(''), '');
    });

    test('extracts text from simple delta', () {
      final delta = '[{"insert":"Hello world\\n"}]';
      expect(stripQuillDelta(delta), 'Hello world\n');
    });

    test('handles multiple operations', () {
      final delta = '[{"insert":"Line 1"},{"insert":"\\n"},{"insert":"Line 2"}]';
      expect(stripQuillDelta(delta), 'Line 1\nLine 2');
    });

    test('handles attributes', () {
      final delta = '[{"insert":"Bold text","attributes":{"bold":true}}]';
      expect(stripQuillDelta(delta), 'Bold text');
    });

    test('handles embed operations', () {
      final delta = '[{"insert":{"image":"https://example.com/img.png"}}]';
      expect(stripQuillDelta(delta), '');
    });

    test('handles embed with alt text', () {
      final delta = '[{"insert":{"image":"img.png","alt":"Photo"}}]';
      expect(stripQuillDelta(delta), 'Photo');
    });

    test('returns raw content when not valid JSON', () {
      expect(stripQuillDelta('Plain text content'), 'Plain text content');
    });

    test('returns raw content when not a List', () {
      expect(stripQuillDelta('{"not":"an array"}'), '{"not":"an array"}');
    });

    test('handles complex mixed delta', () {
      final delta = '''
        [
          {"insert":"Heading\\n","attributes":{"header":1}},
          {"insert":"Body text with "},
          {"insert":"bold","attributes":{"bold":true}},
          {"insert":" and "},
          {"insert":"italic","attributes":{"italic":true}},
          {"insert":"\\n"}
        ]
      '''.replaceAll('  ', '');
      final result = stripQuillDelta(delta);
      expect(result, contains('Heading'));
      expect(result, contains('Body text with'));
      expect(result, contains('bold'));
      expect(result, contains('italic'));
    });
  });
}
