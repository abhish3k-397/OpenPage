enum ReaderTheme { light, dark, sepia }

typedef JavascriptEvaluator = Future<void> Function(String source);

class CssInjector {
  static String getThemeCss(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.dark:
        return 'body { background-color: #121212 !important; color: #e0e0e0 !important; }';
      case ReaderTheme.sepia:
        return 'body { background-color: #f4ecd8 !important; color: #5b4636 !important; }';
      case ReaderTheme.light:
      default:
        return 'body { background-color: #ffffff !important; color: #121212 !important; }';
    }
  }

  static String getTypographyCss({
    required double fontSize,
    required double lineHeight,
    required double horizontalMargin,
  }) {
    return '''
      body {
        font-size: ${fontSize}px !important;
        line-height: $lineHeight !important;
        padding-left: ${horizontalMargin}px !important;
        padding-right: ${horizontalMargin}px !important;
        padding-top: 20px !important;
        padding-bottom: 20px !important;
      }
      p { margin-bottom: 1em !important; }
    ''';
  }

  static String getCombinedJs({
    required ReaderTheme theme,
    required double fontSize,
    required double lineHeight,
    required double horizontalMargin,
  }) {
    final css = '${getThemeCss(theme)} ${getTypographyCss(fontSize: fontSize, lineHeight: lineHeight, horizontalMargin: horizontalMargin)}';
    
    // JS to inject or update a <style> tag with id "open-page-styles"
    return '''
      (function() {
        var style = document.getElementById('open-page-styles');
        if (!style) {
          style = document.createElement('style');
          style.id = 'open-page-styles';
          document.head.appendChild(style);
        }
        style.innerHTML = `$css`;
      })();
    ''';
  }

  static Future<void> inject(
    JavascriptEvaluator evaluateJavascript, {
    required ReaderTheme theme,
    required double fontSize,
    required double lineHeight,
    required double horizontalMargin,
  }) async {
    final js = getCombinedJs(
      theme: theme,
      fontSize: fontSize,
      lineHeight: lineHeight,
      horizontalMargin: horizontalMargin,
    );
    await evaluateJavascript(js);
  }
}
