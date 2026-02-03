import '../../core/reader/css_injector.dart';

class ReaderScreen extends StatefulWidget {
  final String htmlPath;

  const ReaderScreen({
    super.key,
    required this.htmlPath,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  InAppWebViewController? _webViewController;
  bool _isLoading = true;

  // Reader Settings State
  ReaderTheme _theme = ReaderTheme.light;
  double _fontSize = 18.0;
  double _lineHeight = 1.5;
  double _margin = 20.0;

  void _applyStyles() {
    if (_webViewController != null) {
      CssInjector.inject(
        _webViewController!,
        theme: _theme,
        fontSize: _fontSize,
        lineHeight: _lineHeight,
        horizontalMargin: _margin,
      );
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      _themeButton(ReaderTheme.light, 'Light', Colors.white, Colors.black, setModalState),
                      _themeButton(ReaderTheme.sepia, 'Sepia', const Color(0xFFF4ECD8), const Color(0xFF5B4636), setModalState),
                      _themeButton(ReaderTheme.dark, 'Dark', const Color(0xFF121212), Colors.white, setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _sliderSetting('Font Size', _fontSize, 12, 32, (val) {
                    setState(() => _fontSize = val);
                    setModalState(() {});
                    _applyStyles();
                  }),
                  _sliderSetting('Line Height', _lineHeight, 1.0, 2.5, (val) {
                    setState(() => _lineHeight = val);
                    setModalState(() {});
                    _applyStyles();
                  }),
                  _sliderSetting('Margins', _margin, 0, 50, (val) {
                    setState(() => _margin = val);
                    setModalState(() {});
                    _applyStyles();
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _themeButton(ReaderTheme theme, String label, Color bg, Color text, StateSetter setModalState) {
    bool isSelected = _theme == theme;
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
          setState(() => _theme = theme);
          setModalState(() {});
          _applyStyles();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri('file://${widget.htmlPath}')),
            initialSettings: WebviewBridge.defaultSettings,
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStart: (controller, url) {
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              setState(() => _isLoading = false);
              _applyStyles();
            },
            onReceivedError: (controller, request, error) {
              developer.log('WebView Error: ${error.description}', name: 'ReaderScreen');
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
