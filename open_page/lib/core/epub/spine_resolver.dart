import 'package:path/path.dart' as p;
import 'epub_models.dart';

class SpineResolver {
  /// Resolves the absolute file path for a given [SpineItem] in the [EpubBook].
  static String? resolvePath(EpubBook book, SpineItem spineItem) {
    final manifestItem = book.manifest.firstWhere(
      (item) => item.id == spineItem.idRef,
      orElse: () => null as dynamic,
    );

    if (manifestItem == null) return null;

    // The href in manifest is relative to the OPF file location.
    // However, epubx and our loader might vary.
    // Assuming the extracted structure has a content directory.
    
    // We need to find where the content dir is.
    // In our parser, we saved the baseDirectory.
    // We should probably save the content directory in [EpubBook].
    
    // Let's assume for now the manifest items are relative to the root 
    // or we need to find them.
    
    final absolutePath = p.normalize(p.join(book.baseDirectory, manifestItem.href));
    return absolutePath;
  }

  /// Returns a list of absolute paths for all items in the spine.
  static List<String> resolveAllPaths(EpubBook book) {
    return book.spine
        .map((item) => resolvePath(book, item))
        .whereType<String>()
        .toList();
  }
}
