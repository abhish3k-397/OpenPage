import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/reader/webview_bridge.dart';
import 'dart:developer' as developer;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EPUB Reader'),
        actions: [
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
              developer.log('Loading: $url', name: 'ReaderScreen');
              setState(() => _isLoading = true);
            },
            onLoadStop: (controller, url) {
              developer.log('Finished loading: $url', name: 'ReaderScreen');
              setState(() => _isLoading = false);
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
