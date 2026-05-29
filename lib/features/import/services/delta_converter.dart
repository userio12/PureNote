List<Map<String, dynamic>> textToDelta(String text) {
  final lines = text.split('\n');
  final ops = <Map<String, dynamic>>[];
  for (final line in lines) {
    if (line.startsWith('# ')) {
      ops.add({'insert': line.substring(2), 'attributes': {'header': 1}});
    } else if (line.startsWith('## ')) {
      ops.add({'insert': line.substring(3), 'attributes': {'header': 2}});
    } else if (line.startsWith('### ')) {
      ops.add({'insert': line.substring(4), 'attributes': {'header': 3}});
    } else if (line.startsWith('- ') || line.startsWith('* ')) {
      ops.add({'insert': line.substring(2), 'attributes': {'list': 'bullet'}});
    } else {
      ops.add({'insert': line});
    }
    ops.add({'insert': '\n'});
  }
  return ops;
}

List<Map<String, dynamic>> htmlToDelta(String html) {
  if (html.trim().isEmpty) return [{'insert': '\n'}];

  final lines = <String>[];
  var current = '';
  var inTag = false;

  for (var i = 0; i < html.length; i++) {
    if (html[i] == '<') {
      if (current.isNotEmpty) {
        lines.add(current);
        current = '';
      }
      inTag = true;
    } else if (html[i] == '>') {
      inTag = false;
    } else if (!inTag) {
      if (html[i] == '\n') {
        if (current.isNotEmpty) {
          lines.add(current);
          current = '';
        }
      } else {
        current += html[i];
      }
    }
  }
  if (current.isNotEmpty) lines.add(current);

  final ops = <Map<String, dynamic>>[];
  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      ops.add({'insert': trimmed});
    }
    ops.add({'insert': '\n'});
  }
  if (ops.isEmpty) ops.add({'insert': '\n'});

  return ops;
}
