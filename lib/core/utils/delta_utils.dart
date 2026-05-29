import 'dart:convert';

String stripQuillDelta(String content) {
  if (content.isEmpty) return '';
  try {
    final delta = jsonDecode(content) as List;
    final buffer = StringBuffer();
    for (final op in delta) {
      if (op is! Map) continue;
      final insert = op['insert'];
      if (insert is String) {
        buffer.write(insert);
      } else if (insert is Map) {
        buffer.write(insert['alt'] ?? '');
      }
    }
    return buffer.toString();
  } catch (_) {
    return content;
  }
}
