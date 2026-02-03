import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/epub/epub_loader.dart';
import '../../core/epub/epub_parser.dart';
import '../../core/storage/book_dao.dart';

class LibraryNotifier extends AsyncNotifier<List<BookRecord>> {
  final _bookDao = BookDao();
  final _uuid = const Uuid();

  @override
  Future<List<BookRecord>> build() async {
    return _bookDao.getBooks();
  }

  Future<void> importBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result == null || result.files.single.path == null) return;

    state = const AsyncValue.loading();

    try {
      final sourcePath = result.files.single.path!;
      
      // 1. Load and Extract
      final extractedDir = await EpubLoader.loadAndExtract(sourcePath);
      
      // 2. Parse Metadata
      final epubBook = await EpubParser.parse(extractedDir);
      
      // 3. Save to Database
      final bookRecord = BookRecord(
        id: _uuid.v4(),
        title: epubBook.metadata.title,
        author: epubBook.metadata.author,
        coverPath: epubBook.coverPath,
        rootPath: extractedDir,
      );
      
      await _bookDao.insertBook(bookRecord);
      
      // 4. Refresh List
      state = AsyncValue.data(await _bookDao.getBooks());
    } catch (e, stack) {
      developer.log('Import Error', error: e, stackTrace: stack, name: 'LibraryNotifier');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBook(String id) async {
    await _bookDao.deleteBook(id);
    state = AsyncValue.data(await _bookDao.getBooks());
  }
}

final libraryProvider = AsyncNotifierProvider<LibraryNotifier, List<BookRecord>>(() {
  return LibraryNotifier();
});
