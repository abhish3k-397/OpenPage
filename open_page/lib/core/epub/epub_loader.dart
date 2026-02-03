import 'dart:developer' as developer;
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EpubException implements Exception {
  final String message;
  EpubException(this.message);
  @override
  String toString() => 'EpubException: $message';
}

class EpubLoader {
  /// Loads an EPUB file from [sourcePath], copies it to app storage,
  /// and extracts its contents into a structured directory.
  /// Returns the path to the extracted book directory.
  static Future<String> loadAndExtract(String sourcePath) async {
    developer.log('Starting EPUB extraction for: $sourcePath', name: 'EpubLoader');

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw EpubException('Source file not found at $sourcePath');
    }

    if (p.extension(sourcePath).toLowerCase() != '.epub') {
      throw EpubException('File is not an EPUB: $sourcePath');
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sourcePath);
    final bookId = p.basenameWithoutExtension(sourcePath).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    
    final booksDir = Directory(p.join(appDocDir.path, 'books'));
    if (!await booksDir.exists()) {
      await booksDir.create(recursive: true);
    }

    final bookDir = Directory(p.join(booksDir.path, bookId));
    if (await bookDir.exists()) {
      developer.log('Cleaning existing book directory: ${bookDir.path}', name: 'EpubLoader');
      await bookDir.delete(recursive: true);
    }
    await bookDir.create(recursive: true);

    // Copy original file to app storage (optional but good for persistence)
    final savedEpubPath = p.join(bookDir.path, fileName);
    await sourceFile.copy(savedEpubPath);
    developer.log('Copied EPUB to: $savedEpubPath', name: 'EpubLoader');

    // Extract
    try {
      final bytes = await File(savedEpubPath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File(p.join(bookDir.path, filename));
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory(p.join(bookDir.path, filename)).create(recursive: true);
        }
      }
      developer.log('Extraction complete: ${bookDir.path}', name: 'EpubLoader');
      return bookDir.path;
    } catch (e) {
      developer.log('Extraction failed: $e', name: 'EpubLoader', error: e);
      throw EpubException('Failed to extract EPUB: $e');
    }
  }
}
