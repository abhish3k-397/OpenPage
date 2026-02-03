import 'dart:io';
import 'package:epubx/epubx.dart' as epub;
import 'package:path/path.dart' as p;
import 'epub_models.dart';
import 'dart:developer' as developer;

class EpubParser {
  /// Parses an extracted EPUB directory and returns an [EpubBook] model.
  static Future<EpubBook> parse(String extractedPath) async {
    developer.log('Parsing EPUB at: $extractedPath', name: 'EpubParser');

    final dir = Directory(extractedPath);
    final files = await dir.list().toList();
    final epubFile = files.whereType<File>().firstWhere(
      (f) => p.extension(f.path).toLowerCase() == '.epub',
      orElse: () => throw Exception('Original .epub file not found in $extractedPath'),
    );

    final bytes = await epubFile.readAsBytes();
    final book = await epub.EpubReader.readBook(bytes);

    final contentDir = book.Schema?.ContentDirectoryPath ?? '';
    final baseDir = p.join(extractedPath, contentDir);

    final metadata = BookMetadata(
      title: book.Title ?? 'Unknown Title',
      author: book.Author,
      description: book.Schema?.Package?.Metadata?.Description,
      language: book.Schema?.Package?.Metadata?.Languages?.firstOrNull,
      publisher: book.Schema?.Package?.Metadata?.Publishers?.firstOrNull,
      publishDate: book.Schema?.Package?.Metadata?.Dates?.firstOrNull?.Date,
    );

    final manifest = book.Schema?.Package?.Manifest?.Items?.map((item) => ManifestItem(
      id: item.Id ?? '',
      href: item.Href ?? '',
      mediaType: item.MediaType ?? '',
    )).toList() ?? [];

    final spine = book.Schema?.Package?.Spine?.Items?.map((item) => SpineItem(
      idRef: item.IdRef ?? '',
      linear: item.IsLinear ?? true,
    )).toList() ?? [];

    String? coverPath;
    if (book.CoverImage != null) {
      final items = book.Schema?.Package?.Manifest?.Items;
      if (items != null) {
        try {
          final coverItem = items.firstWhere(
            (item) => item.Id == 'cover' || item.Properties == 'cover-image',
            orElse: () => items.firstWhere(
              (item) => item.MediaType?.startsWith('image/') ?? false,
            ),
          );
          coverPath = p.join(baseDir, coverItem.Href);
        } catch (_) {
          // No cover found
        }
      }
    }

    return EpubBook(
      metadata: metadata,
      manifest: manifest,
      spine: spine,
      baseDirectory: baseDir,
      coverPath: coverPath,
      opfPath: p.join(baseDir, 'content.opf'),
    );
  }
}
