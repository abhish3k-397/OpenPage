import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../epub/epub_loader.dart';
import '../epub/epub_parser.dart';
import '../storage/database_service.dart';
import 'dart:developer' as developer;

class ImportService {
  static final _uuid = const Uuid();

  /// Opens a file picker and imports the selected EPUB book.
  static Future<BookRecord?> pickAndImport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['epub'],
      );

      if (result == null || result.files.single.path == null) {
        return null;
      }

      final sourcePath = result.files.single.path!;
      
      // 1. Extract
      final extractPath = await EpubLoader.loadAndExtract(sourcePath);
      
      // 2. Parse metadata
      final epubBook = await EpubParser.parse(extractPath);
      
      // 3. Save to database
      final bookRecord = BookRecord(
        id: _uuid.v4(),
        title: epubBook.metadata.title,
        author: epubBook.metadata.author ?? 'Unknown Author',
        coverPath: epubBook.coverPath ?? '',
        extractPath: extractPath,
        lastReadDate: DateTime.now(),
      );

      await DatabaseService.instance.insertBook(bookRecord);
      
      developer.log('Imported book: ${bookRecord.title}', name: 'ImportService');
      return bookRecord;
    } catch (e) {
      developer.log('Failed to import book: $e', name: 'ImportService', error: e);
      rethrow;
    }
  }
}
