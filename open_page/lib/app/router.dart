import 'package:flutter/material.dart';
import '../features/reader/reader_screen.dart';
import '../features/library/library_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/dependency_check_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const LibraryScreen(),
      '/check': (context) => const DependencyCheckScreen(),
      '/settings': (context) => const SettingsScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == '/reader') {
      final args = settings.arguments as Map<String, dynamic>?;
      final bookId = args?['bookId'] as String?;
      if (bookId != null) {
        return MaterialPageRoute(
          builder: (context) => ReaderScreen(bookId: bookId),
        );
      }
    }
    return null;
  }
}

