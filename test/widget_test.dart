import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:purenote/main.dart';
import 'package:purenote/core/database/database.dart';
import 'package:purenote/core/providers/database_provider.dart';
import 'package:purenote/core/providers/settings_provider.dart';

void main() {
  testWidgets('App renders with bottom navigation', (WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) => db),
          settingsNotifierProvider.overrideWith(
            () => _TestSettingsNotifier(),
          ),
        ],
        child: const PurenoteApp(),
      ),
    );
    await tester.pump();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Notes'), findsAtLeastNWidgets(1));
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    await db.close();
  });
}

class _TestSettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();

  @override
  Future<void> load() async {}

  @override
  Future<void> update(AppSettings newSettings) async {
    state = newSettings;
  }
}
