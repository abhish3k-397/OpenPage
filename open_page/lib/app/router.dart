import 'package:flutter/material.dart';
import '../features/library/library_screen.dart';

import '../features/settings/dependency_check_screen.dart';

class AppRouter {
  static Map<String, WidgetBuilder> get routes {
    return {
      '/': (context) => const LibraryScreen(),
      '/check': (context) => const DependencyCheckScreen(),
    };
  }
}
