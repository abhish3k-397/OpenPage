class BookMetadata {
  final String title;
  final String? author;
  final String? description;
  final String? language;
  final String? publisher;
  final String? publishDate;

  BookMetadata({
    required this.title,
    this.author,
    this.description,
    this.language,
    this.publisher,
    this.publishDate,
  });
}

class ManifestItem {
  final String id;
  final String href;
  final String mediaType;

  ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
  });
}

class SpineItem {
  final String idRef;
  final bool linear;

  SpineItem({
    required this.idRef,
    required this.linear,
  });
}

class EpubBook {
  final BookMetadata metadata;
  final List<ManifestItem> manifest;
  final List<SpineItem> spine;
  final String baseDirectory;
  final String? coverPath;
  final String? opfPath;

  EpubBook({
    required this.metadata,
    required this.manifest,
    required this.spine,
    required this.baseDirectory,
    this.coverPath,
    this.opfPath,
  });

  @override
  String toString() {
    return 'EpubBook(title: ${metadata.title}, author: ${metadata.author}, spineItems: ${spine.length})';
  }
}
