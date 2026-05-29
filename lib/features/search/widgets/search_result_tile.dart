import 'package:flutter/material.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/utils/delta_utils.dart';

class SearchResultTile extends StatelessWidget {
  final Note note;
  final String query;
  final VoidCallback onTap;

  const SearchResultTile({
    super.key,
    required this.note,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _extractPreview(note.content);
    final title = note.title.isEmpty ? 'Untitled' : note.title;

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: note.color != null
            ? Color(note.color!)
            : theme.colorScheme.surfaceContainerHighest,
        radius: 20,
        child: Icon(Icons.article_outlined, size: 20, color: theme.colorScheme.onSurfaceVariant),
      ),
      title: _highlightText(title, query, theme, bold: true),
      subtitle: preview.isNotEmpty
          ? _highlightText(preview, query, theme, maxLines: 2)
          : null,
    );
  }

  String _extractPreview(String content) {
    if (content.isEmpty) return '';
    try {
      return stripQuillDelta(content).replaceAll('\n', ' ').trim();
    } catch (_) {
      return '';
    }
  }

  Widget _highlightText(String text, String query, ThemeData theme, {bool bold = false, int? maxLines}) {
    if (query.trim().isEmpty) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodySmall,
      );
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) break;

      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: theme.colorScheme.primaryContainer,
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ));
      start = index + query.length;
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return Text.rich(
      TextSpan(
        style: bold ? theme.textTheme.titleSmall : theme.textTheme.bodySmall,
        children: spans.isEmpty ? [TextSpan(text: text)] : spans,
      ),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}
