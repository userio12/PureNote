import 'package:home_widget/home_widget.dart';
import 'package:purenote/core/database/daos/note_dao.dart';
import 'package:purenote/core/utils/delta_utils.dart';

class WidgetService {
  static const _titleKey = 'title';
  static const _bodyKey = 'body';

  static Future<void> updateWidgetData(NoteDao dao) async {
    try {
      final notes = await dao.getAll();
      final nonEmpty = notes.where((n) => n.content.isNotEmpty || n.title.isNotEmpty).toList();
      nonEmpty.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final recent = nonEmpty.take(5).toList();

      String title;
      String body;

      if (recent.isEmpty) {
        title = 'purenote';
        body = 'No notes yet';
      } else {
        final first = recent.first;
        title = first.title.isNotEmpty ? first.title : 'Untitled';
        final preview = stripQuillDelta(first.content).replaceAll('\n', ' ').trim();
        body = preview.isNotEmpty ? preview : '(empty)';

        if (recent.length > 1) {
          body += '\n+${recent.length - 1} more';
        }
      }

      await HomeWidget.saveWidgetData<String>(_titleKey, title);
      await HomeWidget.saveWidgetData<String>(_bodyKey, body);
      await HomeWidget.updateWidget(
        androidName: 'PureNoteWidgetProvider',
        qualifiedAndroidName: 'com.purenote.purenote.PureNoteWidgetProvider',
      );
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<void> widgetBackgroundCallback(Uri? uri) async {
  try {
    final title = await HomeWidget.getWidgetData<String>(WidgetService._titleKey);
    final body = await HomeWidget.getWidgetData<String>(WidgetService._bodyKey);
    if (title != null) {
      await HomeWidget.saveWidgetData(WidgetService._titleKey, title);
    }
    if (body != null) {
      await HomeWidget.saveWidgetData(WidgetService._bodyKey, body);
    }
    await HomeWidget.updateWidget(
      androidName: 'PureNoteWidgetProvider',
      qualifiedAndroidName: 'com.purenote.purenote.PureNoteWidgetProvider',
    );
  } catch (_) {}
}
