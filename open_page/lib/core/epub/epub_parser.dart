import 'dart:io';
import 'package:epubx/epubx.dart' as epub;
import 'package:path/path.dart' as p;
import 'epub_models.dart';
import 'dart:developer' as developer;

class EpubParser {
  /// Parses an extracted EPUB directory and returns an [EpubBook] model.
  static Future<EpubBook> parse(String extractedPath) async {
    developer.log('Parsing EPUB at: $extractedPath', name: 'EpubParser');

    // To use epubx effectively, we often need the full epub bytes,
    // but the requirement is to parse the extracted structure.
    // However, epubx is designed to parse from bytes.
    // We can read the .epub file we copied during extraction if it exists,
    // or we can manually parse the XMLs. 
    // Given the "using epubx" requirement, let's find the .epub file in the directory.
    
    final dir = Directory(extractedPath);
    final files = await dir.list().toList();
    final epubFile = files.whereType<File>().firstWhere(
      (f) => p.extension(f.path).toLowerCase() == '.epub',
      orElse: () => throw Exception('Original .epub file not found in $extractedPath'),
    );

    final bytes = await epubFile.readAsBytes();
    final book = await epub.EpubReader.readBook(bytes);

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

    // Find cover image. epubx identifies it for us.
    String? coverPath;
    if (book.CoverImage != null) {
      // Find which manifest item corresponds to the cover
      // epubx doesn't directly give the relative path in the extracted dir easily 
      // without some searching.
      final coverItem = book.Schema?.Package?.Manifest?.Items?.firstWhere(
        (item) => item.Id == 'cover' || item.Properties == 'cover-image',
        orElse: () => book.Schema?.Package?.Manifest?.Items?.firstWhere(
          (item) => item.MediaType?.startsWith('image/') ?? false,
          orElse: () => null,
        ),
      );
      if (coverItem != null) {
        coverPath = p.join(extractedPath, book.Schema?.ContentDirectoryPath ?? '', coverItem.Href);
      }
    }

    return EpubBook(
      metadata: metadata,
      manifest: manifest,
      spine: spine,
      baseDirectory: extractedPath,
      coverPath: coverPath,
      opfPath: p.join(extractedPath, book.Schema?.Package?.ContentDirectoryPath ?? '', 'content.opf'), // Approximate
    );
  }
}
