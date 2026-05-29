import 'package:xml/xml.dart';
import 'package:purenote/features/import/services/delta_converter.dart';

class EvernoteNote {
  final String title;
  final String content;
  final List<String> tags;
  final int createdAt;
  final int updatedAt;
  final List<EvernoteResource> resources;

  EvernoteNote({
    required this.title,
    required this.content,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.resources,
  });
}

class EvernoteResource {
  final String dataBase64;
  final String mimeType;
  final String fileName;

  EvernoteResource({
    required this.dataBase64,
    required this.mimeType,
    required this.fileName,
  });
}

class EvernoteParser {
  static List<EvernoteNote> parse(String xmlContent) {
    final notes = <EvernoteNote>[];
    final document = XmlDocument.parse(xmlContent);
    final root = document.rootElement;

    for (final noteEl in root.findElements('note')) {
      final title = noteEl.findElements('title').firstOrNull?.innerText ?? 'Untitled';
      final contentEl = noteEl.findElements('content').firstOrNull;
      final content = contentEl?.innerText ?? '';

      final tags = noteEl
          .findElements('tag')
          .map((t) => t.innerText.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final created = _parseDate(noteEl.findElements('created').firstOrNull?.innerText);
      final updated = _parseDate(noteEl.findElements('updated').firstOrNull?.innerText);

      final resources = <EvernoteResource>[];
      for (final resEl in noteEl.findElements('resource')) {
        final dataEl = resEl.findElements('data').firstOrNull;
        final mime = resEl.findElements('mime').firstOrNull?.innerText ?? 'application/octet-stream';
        final fileName = resEl
            .findElements('resource-attributes')
            .firstOrNull
            ?.findElements('file-name')
            .firstOrNull
            ?.innerText ?? 'attachment.bin';

        if (dataEl != null) {
          resources.add(EvernoteResource(
            dataBase64: dataEl.innerText.replaceAll('\n', '').replaceAll('\r', ''),
            mimeType: mime,
            fileName: fileName,
          ));
        }
      }

      notes.add(EvernoteNote(
        title: title,
        content: content,
        tags: tags,
        createdAt: created,
        updatedAt: updated,
        resources: resources,
      ));
    }

    return notes;
  }

  static int _parseDate(String? enexDate) {
    if (enexDate == null) return DateTime.now().millisecondsSinceEpoch;
    try {
      return DateTime.parse(enexDate).millisecondsSinceEpoch;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch;
    }
  }

  static String extractEnmlText(String enmlContent) {
    try {
      final doc = XmlDocument.parse(enmlContent);
      return doc.rootElement.innerText;
    } catch (_) {
      return enmlContent;
    }
  }

  static List<Map<String, dynamic>> enmlToDelta(String enmlContent) {
    final text = extractEnmlText(enmlContent);
    return textToDelta(text);
  }
}
