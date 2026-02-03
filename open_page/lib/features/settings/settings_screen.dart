import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/settings/settings_provider.dart';
import '../../core/reader/css_injector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Global Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Default Reader Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'New books will use these settings by default.',
            style: TextStyle(color: Colors.grey),
          ),
          const Divider(height: 40),
          
          const Text('Default Theme', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _themeButton(ref, ReaderTheme.light, 'Light', Colors.white, Colors.black, settings),
              _themeButton(ref, ReaderTheme.sepia, 'Sepia', const Color(0xFFF4ECD8), const Color(0xFF5B4636), settings),
              _themeButton(ref, ReaderTheme.dark, 'Dark', const Color(0xFF121212), Colors.white, settings),
            ],
          ),
          
          const Divider(height: 40),
          _sliderSetting(ref, 'Default Font Size', settings.fontSize, 12, 32, (val) {
            ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(fontSize: val));
          }),
          
          const Divider(height: 40),
          _sliderSetting(ref, 'Default Line Height', settings.lineHeight, 1.0, 2.5, (val) {
            ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(lineHeight: val));
          }),
          
          const Divider(height: 40),
          _sliderSetting(ref, 'Default Margins', settings.margin, 0, 50, (val) {
            ref.read(settingsProvider.notifier).updateSettings(settings.copyWith(margin: val));
          }),
        ],
      ),
    );
  }

  Widget _themeButton(WidgetRef ref, ReaderTheme theme, String label, Color bg, Color text, ReaderSettings current) {
    bool isSelected = current.theme == theme;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: text)),
      selected: isSelected,
      selectedColor: bg.withOpacity(0.8),
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isSelected ? Colors.deepPurple : Colors.grey, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      onSelected: (selected) {
        if (selected) {
          ref.read(settingsProvider.notifier).updateSettings(current.copyWith(theme: theme));
        }
      },
    );
  }

  Widget _sliderSetting(WidgetRef ref, String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: value,
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
            Text(value.toStringAsFixed(1)),
          ],
        ),
      ],
    );
  }
}
