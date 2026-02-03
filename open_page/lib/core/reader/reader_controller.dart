import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class ReaderController {
  static const String _prefix = 'open_page_pos_';

  /// Saves the vertical scroll percentage (0.0 to 1.0) for a specific book and chapter.
  static Future<void> savePosition({
    required String bookId,
    required String chapterPath,
    required double progress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${bookId}_${chapterPath.hashCode}';
    await prefs.setDouble(key, progress);
    developer.log('Saved position for $bookId: ${(progress * 100).toStringAsFixed(2)}%', name: 'ReaderController');
  }

  /// Retrieves the vertical scroll percentage for a specific book and chapter.
  /// Returns 0.0 if no position is saved.
  static Future<double> getPosition({
    required String bookId,
    required String chapterPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefix${bookId}_${chapterPath.hashCode}';
    return prefs.getDouble(key) ?? 0.0;
  }
}
