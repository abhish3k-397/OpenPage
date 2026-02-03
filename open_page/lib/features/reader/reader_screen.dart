import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/reader/css_injector.dart';
import '../../core/reader/reader_controller.dart';
import '../../core/reader/reader_webview.dart';
import 'reader_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  ReaderWebController? _webViewController;
  double _scrollProgress = 0.0;

  void _applyStyles(ReaderSettings settings) {
    // On Linux we render HTML directly and style is applied in the widget.
    if (Platform.isLinux) return;
    if (_webViewController != null) {
      CssInjector.inject(
        (source) => _webViewController!.evaluateJavascript(source),
        theme: settings.theme,
        fontSize: settings.fontSize,
        lineHeight: settings.lineHeight,
        horizontalMargin: settings.margin,
      );
    }
  }

  void _showSettings(ReaderState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Appearance',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _themeOption(ReaderTheme.light, 'Light', const Color(0xFFFFFFFF), const Color(0xFF121212), state),
                  _themeOption(ReaderTheme.sepia, 'Sepia', const Color(0xFFF4ECD8), const Color(0xFF5B4636), state),
                  _themeOption(ReaderTheme.dark, 'Dark', const Color(0xFF121212), const Color(0xFFE0E0E0), state),
                ],
              ),
              const SizedBox(height: 32),
              _sliderSetting('Font Size', state.settings.fontSize, 12, 32, (val) {
                final newSettings = state.settings.copyWith(fontSize: val);
                ref.read(readerProvider.notifier).updateSettings(newSettings);
                _applyStyles(newSettings);
              }),
              const SizedBox(height: 16),
              _sliderSetting('Line Height', state.settings.lineHeight, 1.0, 2.5, (val) {
                final newSettings = state.settings.copyWith(lineHeight: val);
                ref.read(readerProvider.notifier).updateSettings(newSettings);
                _applyStyles(newSettings);
              }),
              const SizedBox(height: 16),
              _sliderSetting('Margins', state.settings.margin, 0, 50, (val) {
                final newSettings = state.settings.copyWith(margin: val);
                ref.read(readerProvider.notifier).updateSettings(newSettings);
                _applyStyles(newSettings);
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _themeOption(ReaderTheme theme, String label, Color bg, Color text, ReaderState state) {
    final isSelected = state.settings.theme == theme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () {
        final newSettings = state.settings.copyWith(theme: theme);
        ref.read(readerProvider.notifier).updateSettings(newSettings);
        _applyStyles(newSettings);
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 50,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text('Aa', style: TextStyle(color: text, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderSetting(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(1), style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readerProvider.notifier).initialize(widget.bookId);
    });

    if (state.isLoading || state.spinePaths.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentPath = state.spinePaths[state.currentChapterIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chapter ${state.currentChapterIndex + 1}',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_format_rounded),
            onPressed: () => _showSettings(state),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: _scrollProgress,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
          Expanded(
            child: ReaderWebView(
              key: ValueKey(currentPath),
              filePath: currentPath,
              theme: state.settings.theme,
              fontSize: state.settings.fontSize,
              lineHeight: state.settings.lineHeight,
              margin: state.settings.margin,
              onScrollProgress: (progress) {
                if (mounted) setState(() => _scrollProgress = progress);
                ReaderController.savePosition(
                  bookId: widget.bookId,
                  chapterPath: currentPath,
                  progress: progress,
                );
              },
              onControllerReady: (controller) {
                _webViewController = controller;
              },
              onPageReady: () async {
                _applyStyles(state.settings);
                await _restoreScrollPosition(currentPath);
              },
            ),
          ),
          _buildNavigation(state),
        ],
      ),
    );
  }

  Widget _buildNavigation(ReaderState state) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: state.currentChapterIndex > 0
                  ? () {
                      ref.read(readerProvider.notifier).previousChapter();
                      setState(() => _scrollProgress = 0.0);
                    }
                  : null,
            ),
            Text(
              '${state.currentChapterIndex + 1} of ${state.spinePaths.length}',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: state.currentChapterIndex < state.spinePaths.length - 1
                  ? () {
                      ref.read(readerProvider.notifier).nextChapter();
                      setState(() => _scrollProgress = 0.0);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreScrollPosition(String path) async {
    if (Platform.isLinux) return;
    final double progress = await ReaderController.getPosition(
      bookId: widget.bookId,
      chapterPath: path,
    );
    if (progress > 0) {
      final js = '''
        setTimeout(function() {
          var totalHeight = document.documentElement.scrollHeight - window.innerHeight;
          window.scrollTo(0, totalHeight * $progress);
        }, 150);
      ''';
      await _webViewController?.evaluateJavascript(js);
    }
  }
}
