import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:purenote/core/theme/app_theme.dart';
import 'package:purenote/core/providers/settings_provider.dart';

part 'theme_provider.g.dart';

@Riverpod(keepAlive: true)
ThemeData appTheme(AppThemeRef ref) {
  final settings = ref.watch(settingsNotifierProvider);
  return settings.themeMode == ThemeMode.dark
      ? AppTheme.dark()
      : AppTheme.light();
}
