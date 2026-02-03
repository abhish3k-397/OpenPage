import '../features/reader/reader_screen.dart';
import '../features/library/library_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const LibraryScreen(),
      '/check': (context) => const DependencyCheckScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/reader') {
      final args = settings.arguments as Map<String, dynamic>?;
      final path = args?['path'] as String?;
      if (path != null) {
        return MaterialPageRoute(
          builder: (context) => ReaderScreen(htmlPath: path),
        );
      }
    }
    return null;
  }
}

