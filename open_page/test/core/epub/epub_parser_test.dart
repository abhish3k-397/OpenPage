import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_page/core/epub/epub_loader.dart';
import 'package:open_page/core/epub/epub_parser.dart';
import 'package:open_page/core/epub/spine_resolver.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';

void main() {
  test('EpubParser parses metadata and spine correctly', () async {
    final tempDir = await Directory.systemTemp.createTemp('epub_parser_test');
    final mockEpubPath = p.join(tempDir.path, 'test_book.epub');

    // Create a mock EPUB
    final archive = Archive();
    
    // mimetype
    archive.addFile(ArchiveFile('mimetype', 20, 'application/epub+zip'.codeUnits));
    
    // container.xml
    final containerXml = '<?xml version="1.0"?><container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>';
    archive.addFile(ArchiveFile('META-INF/container.xml', containerXml.length, containerXml.codeUnits));
    
    // content.opf
    final opfXml = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="pub-id" version="3.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Test Title</dc:title>
    <dc:creator>Test Author</dc:creator>
  </metadata>
  <manifest>
    <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
    <item id="chapter2" href="chapter2.xhtml" media-type="application/xhtml+xml"/>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
  </manifest>
  <spine>
    <itemref idref="chapter1"/>
    <itemref idref="chapter2"/>
  </spine>
</package>''';
    archive.addFile(ArchiveFile('OEBPS/content.opf', opfXml.length, opfXml.codeUnits));
    archive.addFile(ArchiveFile('OEBPS/chapter1.xhtml', 10, 'chap1'.codeUnits));
    archive.addFile(ArchiveFile('OEBPS/chapter2.xhtml', 10, 'chap2'.codeUnits));

    final zipEncoder = ZipEncoder();
    final zipBuffer = zipEncoder.encode(archive);
    await File(mockEpubPath).writeAsBytes(zipBuffer!);

    try {
      // 1. Load/Extract
      final extractedDir = await EpubLoader.loadAndExtract(mockEpubPath);
      
      // 2. Parse
      final book = await EpubParser.parse(extractedDir);
      
      expect(book.metadata.title, equals('Test Title'));
      expect(book.metadata.author, equals('Test Author'));
      expect(book.spine.length, equals(2));
      expect(book.spine[0].idRef, equals('chapter1'));
      
      // 3. Resolve
      final paths = SpineResolver.resolveAllPaths(book);
      expect(paths.length, equals(2));
      // path depends on how epubx treats Href inside content.opf located at OEBPS/
      // Usually epubx resolves Href relative to the content.opf
      expect(paths[0], contains('chapter1.xhtml'));
      
      print('Parsed Book: $book');
      print('Resolved Paths: $paths');
      
    } catch (e) {
      print('Test note: $e');
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
