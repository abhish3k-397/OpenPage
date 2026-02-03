import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/epub/epub_parser.dart';
import '../../core/epub/spine_resolver.dart';
import '../../core/reader/css_injector.dart';
import '../../core/storage/book_dao.dart';

class ReaderSettings {
  final ReaderTheme theme;
  final double fontSize;
  final double lineHeight;
  final double margin;

  ReaderSettings({
    this.theme = ReaderTheme.light,
    this.fontSize = 18.0,
    this.lineHeight = 1.5,
    this.margin = 20.0,
  });

  ReaderSettings copyWith({
    ReaderTheme? theme,
    double? fontSize,
    double? lineHeight,
    double? margin,
  }) {
    return ReaderSettings(
      theme: theme ?? this.theme,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      margin: margin ?? this.margin,
    );
  }
}

class ReaderState {
  final String bookId;
  final List<String> spinePaths;
  final int currentChapterIndex;
  final ReaderSettings settings;
  final bool isLoading;

  ReaderState({
    required this.bookId,
    required this.spinePaths,
    this.currentChapterIndex = 0,
    required this.settings,
    this.isLoading = true,
  });

  ReaderState copyWith({
    List<String>? spinePaths,
    int? currentChapterIndex,
    ReaderSettings? settings,
    bool? isLoading,
  }) {
    return ReaderState(
      bookId: bookId,
      spinePaths: spinePaths ?? this.spinePaths,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ReaderNotifier extends FamilyNotifier<ReaderState, String> {
  final _bookDao = BookDao();

  @override
  ReaderState build(String arg) {
    // Initialization handled via an async internal method 
    // to avoid complex build logic
    _init(arg);
    return ReaderState(
      bookId: arg,
      spinePaths: [],
      settings: ReaderSettings(),
    );
  }

  Future<void> _init(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Settings
    final themeIndex = prefs.getInt('reader_theme') ?? 0;
    final fontSize = prefs.getDouble('reader_font_size') ?? 18.0;
    final lineHeight = prefs.getDouble('reader_line_height') ?? 1.5;
    final margin = prefs.getDouble('reader_margin') ?? 20.0;

    final settings = ReaderSettings(
      theme: ReaderTheme.values[themeIndex],
      fontSize: fontSize,
      lineHeight: lineHeight,
      margin: margin,
    );

    // Load Book & Spine
    final bookRecord = await _bookDao.getBookById(bookId);
    if (bookRecord == null) return;

    final epubBook = await EpubParser.parse(bookRecord.rootPath);
    final paths = SpineResolver.resolveAllPaths(epubBook);

    // Find last chapter or start at 0
    int startIndex = 0;
    if (bookRecord.lastChapter != null) {
      final lastPath = bookRecord.lastChapter!;
      startIndex = paths.indexWhere((p) => p == lastPath);
      if (startIndex == -1) startIndex = 0;
    }

    state = state.copyWith(
      spinePaths: paths,
      currentChapterIndex: startIndex,
      settings: settings,
      isLoading: false,
    );
  }

  void updateSettings(ReaderSettings newSettings) async {
    state = state.copyWith(settings: newSettings);
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reader_theme', newSettings.theme.index);
    await prefs.setDouble('reader_font_size', newSettings.fontSize);
    await prefs.setDouble('reader_line_height', newSettings.lineHeight);
    await prefs.setDouble('reader_margin', newSettings.margin);
  }

  void goToChapter(int index) async {
    if (index < 0 || index >= state.spinePaths.length) return;
    
    state = state.copyWith(currentChapterIndex: index, isLoading: true);
    
    // Save progress to DB
    await _bookDao.updateReadProgress(
      state.bookId, 
      state.spinePaths[index], 
      0.0 // Reset offset for new chapter or handle differently
    );

    state = state.copyWith(isLoading: false);
  }

  void nextChapter() => goToChapter(state.currentChapterIndex + 1);
  void previousChapter() => goToChapter(state.currentChapterIndex - 1);
}

final readerProvider = NotifierProviderFamily<ReaderNotifier, ReaderState, String>(() {
  return ReaderNotifier();
});
