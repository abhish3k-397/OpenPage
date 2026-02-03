import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_html/flutter_html.dart';
import 'dart:developer' as developer;

typedef ReaderJavascriptEvaluator = Future<void> Function(String source);

abstract class ReaderWebController {
  Future<void> reload();
  Future<void> evaluateJavascript(String source);
}

class ReaderWebView extends StatefulWidget {
  final String filePath;
  final ValueChanged<double> onScrollProgress;
  final ValueChanged<ReaderWebController> onControllerReady;
  final VoidCallback onPageReady;

  const ReaderWebView({
    super.key,
    required this.filePath,
    required this.onScrollProgress,
    required this.onControllerReady,
    required this.onPageReady,
  });

  @override
  State<ReaderWebView> createState() => _ReaderWebViewState();
}

class _ReaderWebViewState extends State<ReaderWebView> {
  @override
  Widget build(BuildContext context) {
    if (Platform.isLinux) {
      return _LinuxReaderView(
        filePath: widget.filePath,
        onScrollProgress: widget.onScrollProgress,
        onControllerReady: widget.onControllerReady,
      );
    }

    // Windows, Android, iOS, macOS use flutter_inappwebview.
    return _InAppReaderWebView(
      filePath: widget.filePath,
      onScrollProgress: widget.onScrollProgress,
      onControllerReady: widget.onControllerReady,
      onPageReady: widget.onPageReady,
    );
  }
}

class _InAppReaderWebView extends StatefulWidget {
  final String filePath;
  final ValueChanged<double> onScrollProgress;
  final ValueChanged<ReaderWebController> onControllerReady;
  final VoidCallback onPageReady;

  const _InAppReaderWebView({
    required this.filePath,
    required this.onScrollProgress,
    required this.onControllerReady,
    required this.onPageReady,
  });

  @override
  State<_InAppReaderWebView> createState() => _InAppReaderWebViewState();
}

class _InAppReaderWebViewState extends State<_InAppReaderWebView> {
  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      key: ValueKey(widget.filePath),
      initialUrlRequest: URLRequest(url: WebUri(Uri.file(widget.filePath).toString())),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        useHybridComposition: true,
        isInspectable: true,
        supportZoom: true,
        builtInZoomControls: false,
        displayZoomControls: false,
      ),
      onWebViewCreated: (controller) {
        controller.addJavaScriptHandler(
          handlerName: 'onScroll',
          callback: (args) {
            final progress = (args.isNotEmpty ? args[0] : 0).toDouble();
            widget.onScrollProgress(progress);
          },
        );

        widget.onControllerReady(_InAppController(controller));
      },
      onLoadStop: (controller, url) async {
        // Install scroll monitor
        await controller.evaluateJavascript(
          source: _scrollMonitorJsForInAppWebView(),
        );
        widget.onPageReady();
      },
    );
  }

  String _scrollMonitorJsForInAppWebView() {
    return '''
      (function() {
        window.onscroll = function() {
          var scrollPos = window.scrollY || document.documentElement.scrollTop || document.body.scrollTop || 0;
          var totalHeight = document.documentElement.scrollHeight - window.innerHeight;
          var progress = totalHeight > 0 ? scrollPos / totalHeight : 0;
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('onScroll', progress);
          }
        };
      })();
    ''';
  }
}

class _InAppController implements ReaderWebController {
  final InAppWebViewController _controller;
  _InAppController(this._controller);

  @override
  Future<void> reload() => _controller.reload();

  @override
  Future<void> evaluateJavascript(String source) =>
      _controller.evaluateJavascript(source: source);
}

class _LinuxReaderView extends StatefulWidget {
  final String filePath;
  final ValueChanged<double> onScrollProgress;
  final ValueChanged<ReaderWebController> onControllerReady;
  const _LinuxReaderView({
    required this.filePath,
    required this.onScrollProgress,
    required this.onControllerReady,
  });

  @override
  State<_LinuxReaderView> createState() => _LinuxReaderViewState();
}

class _LinuxReaderWebController implements ReaderWebController {
  @override
  Future<void> reload() async {}

  @override
  Future<void> evaluateJavascript(String source) async {}
}

class _LinuxReaderViewState extends State<_LinuxReaderView> {
  late Future<String> _htmlFuture;

  @override
  void initState() {
    super.initState();
    _htmlFuture = _loadHtml();
    // Provide a no-op controller so the rest of the reader flow works.
    widget.onControllerReady(_LinuxReaderWebController());
  }

  Future<String> _loadHtml() async {
    developer.log('LinuxReaderView loading: ${widget.filePath}', name: 'ReaderWebView');
    final file = File(widget.filePath);
    final exists = await file.exists();
    developer.log('Chapter file exists: $exists', name: 'ReaderWebView');
    if (!exists) {
      return '<p>Chapter file not found: ${widget.filePath}</p>';
    }
    try {
      return await file.readAsString();
    } catch (e, stack) {
      developer.log('Failed to read chapter file', error: e, stackTrace: stack, name: 'ReaderWebView');
      return '<p>Failed to read chapter: $e</p>';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Failed to load chapter.'));
        }

        final html = snapshot.data!;

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.maxScrollExtent > 0) {
              final progress = (metrics.pixels / metrics.maxScrollExtent).clamp(0.0, 1.0);
              widget.onScrollProgress(progress);
            }
            return false;
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Html(
              data: html,
              style: {
                'body': Style(
                  fontSize: FontSize(18),
                  lineHeight: LineHeight.number(1.5),
                ),
              },
            ),
          ),
        );
      },
    );
  }
}

