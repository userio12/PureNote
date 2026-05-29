import 'dart:convert';
import 'package:purenote/features/import/services/delta_converter.dart';

class QuillpadNote {
  final String title;
  final dynamic content;
  final List<String> tags;
  final int? color;
  final int createdAt;
  final int updatedAt;

  QuillpadNote({
    required this.title,
    required this.content,
    required this.tags,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });
}

class QuillpadParser {
  static List<QuillpadNote> parse(String jsonContent) {
    final notes = <QuillpadNote>[];
    final data = jsonDecode(jsonContent);

    if (data is List) {
      for (final item in data) {
        notes.add(_parseItem(item as Map<String, dynamic>));
      }
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey('notes')) {
        for (final item in data['notes'] as List) {
          notes.add(_parseItem(item as Map<String, dynamic>));
        }
      } else {
        notes.add(_parseItem(data));
      }
    }

    return notes;
  }

  static QuillpadNote _parseItem(Map<String, dynamic> item) {
    return QuillpadNote(
      title: (item['title'] as String?)?.trim() ?? 'Untitled',
      content: item['content'] ?? item['body'] ?? '',
      tags: (item['tags'] as List?)?.cast<String>() ?? [],
      color: item['color'] as int?,
      createdAt: _parseTimestamp(item['createdAt'] ?? item['created_at'] ?? item['created']),
      updatedAt: _parseTimestamp(item['updatedAt'] ?? item['updated_at'] ?? item['updated'] ?? item['createdAt']),
    );
  }

  static int _parseTimestamp(dynamic ts) {
    if (ts == null) return DateTime.now().millisecondsSinceEpoch;
    if (ts is int) return ts;
    if (ts is String) {
      final parsed = DateTime.tryParse(ts);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    return DateTime.now().millisecondsSinceEpoch;
  }

  static List<Map<String, dynamic>> quillpadToDelta(QuillpadNote note) {
    if (note.content is List) {
      try {
        return (note.content as List).cast<Map<String, dynamic>>();
      } catch (_) {}
    }
    if (note.content is String) {
      final text = note.content as String;
      try {
        final parsed = jsonDecode(text);
        if (parsed is List) return parsed.cast<Map<String, dynamic>>();
      } catch (_) {}
      return textToDelta(text);
    }
    return [{'insert': '\n'}];
  }
}
