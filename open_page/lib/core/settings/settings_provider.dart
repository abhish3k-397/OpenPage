import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../reader/css_injector.dart';
import '../reader/reader_provider.dart';

class SettingsNotifier extends Notifier<ReaderSettings> {
  @override
  ReaderSettings build() {
    // Initial state is default, but we should trigger a load
    _loadSettings();
    return ReaderSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt('global_reader_theme') ?? 0;
    final fontSize = prefs.getDouble('global_reader_font_size') ?? 18.0;
    final lineHeight = prefs.getDouble('global_reader_line_height') ?? 1.5;
    final margin = prefs.getDouble('global_reader_margin') ?? 20.0;

    state = ReaderSettings(
      theme: ReaderTheme.values[themeIndex],
      fontSize: fontSize,
      lineHeight: lineHeight,
      margin: margin,
    );
  }

  Future<void> updateSettings(ReaderSettings newSettings) async {
    state = newSettings;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('global_reader_theme', newSettings.theme.index);
    await prefs.setDouble('global_reader_font_size', newSettings.fontSize);
    await prefs.setDouble('global_reader_line_height', newSettings.lineHeight);
    await prefs.setDouble('global_reader_margin', newSettings.margin);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, ReaderSettings>(() {
  return SettingsNotifier();
});
