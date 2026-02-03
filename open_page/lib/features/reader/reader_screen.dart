import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/reader/css_injector.dart';
import '../../core/reader/reader_controller.dart';
import '../../core/reader/reader_webview.dart';
import 'reader_provider.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final String bookId;

  const ReaderScreen({
    super.key,
    required this.bookId,
    // Note: htmlPath is no longer needed as a primary parameter 
    // because the provider manages the current chapter path.
  });

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  ReaderWebController? _webViewController;
  double _scrollProgress = 0.0;

  void _applyStyles(ReaderSettings settings) {
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
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final settings = state.settings;
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Reader Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _themeButton(ReaderTheme.light, 'Light', Colors.white, Colors.black, settings, setModalState),
                      _themeButton(ReaderTheme.sepia, 'Sepia', const Color(0xFFF4ECD8), const Color(0xFF5B4636), settings, setModalState),
                      _themeButton(ReaderTheme.dark, 'Dark', const Color(0xFF121212), Colors.white, settings, setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sliderSetting('Font Size', settings.fontSize, 12, 32, (val) {
                    final newSettings = settings.copyWith(fontSize: val);
                    ref.read(readerProvider.notifier).updateSettings(newSettings);
                    _applyStyles(newSettings);
                    setModalState(() {});
                  }),
                  _sliderSetting('Line Height', settings.lineHeight, 1.0, 2.5, (val) {
                    final newSettings = settings.copyWith(lineHeight: val);
                    ref.read(readerProvider.notifier).updateSettings(newSettings);
                    _applyStyles(newSettings);
                    setModalState(() {});
                  }),
                  _sliderSetting('Margins', settings.margin, 0, 50, (val) {
                    final newSettings = settings.copyWith(margin: val);
                    ref.read(readerProvider.notifier).updateSettings(newSettings);
                    _applyStyles(newSettings);
                    setModalState(() {});
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeButton(ReaderTheme theme, String label, Color bg, Color text, ReaderSettings current, StateSetter setModalState) {
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
          final newSettings = current.copyWith(theme: theme);
          ref.read(readerProvider.notifier).updateSettings(newSettings);
          _applyStyles(newSettings);
          setModalState(() {});
        }
      },
    );
  }

  Widget _sliderSetting(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerProvider);

    // Manual initialization since we moved away from .family to avoid build issues
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
        title: Text('Chapter ${state.currentChapterIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(state),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: _scrollProgress),
          Expanded(
            child: Stack(
              children: [
                ReaderWebView(
                  key: ValueKey(currentPath), // Force rebuild on chapter change
                  filePath: currentPath,
                  onScrollProgress: (progress) {
                    setState(() => _scrollProgress = progress);
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
              ],
            ),
          ),
          _buildNavigation(state),
        ],
      ),
    );
  }

  Widget _buildNavigation(ReaderState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: state.currentChapterIndex > 0
                ? () {
                    ref.read(readerProvider.notifier).previousChapter();
                    setState(() => _scrollProgress = 0.0);
                  }
                : null,
          ),
          Text(
            '${state.currentChapterIndex + 1} / ${state.spinePaths.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: state.currentChapterIndex < state.spinePaths.length - 1
                ? () {
                    ref.read(readerProvider.notifier).nextChapter();
                    setState(() => _scrollProgress = 0.0);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _restoreScrollPosition(String path) async {
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
