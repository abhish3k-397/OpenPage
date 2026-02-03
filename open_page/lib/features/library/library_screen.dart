import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/database_service.dart';
import '../../core/epub/import_service.dart';
import '../../core/epub/epub_parser.dart';
import '../../core/epub/spine_resolver.dart';
import 'dart:developer' as developer;

final booksProvider = FutureProvider<List<BookRecord>>((ref) async {
  return await DatabaseService.instance.getAllBooks();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OpenPage Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => Navigator.pushNamed(context, '/check'),
          ),
        ],
      ),
      body: booksAsync.when(
        data: (books) => books.isEmpty
            ? const Center(child: Text('Add your first book to start reading'))
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index];
                    return _BookCard(book: book);
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            final book = await ImportService.pickAndImport();
            if (book != null) {
              ref.invalidate(booksProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Imported ${book.title}')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Import failed: $e')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final BookRecord book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          try {
            // Parse full book to get first chapter if no position saved
            final epubBook = await EpubParser.parse(book.extractPath);
            final paths = SpineResolver.resolveAllPaths(epubBook);
            
            if (paths.isNotEmpty) {
              Navigator.pushNamed(
                context,
                '/reader',
                arguments: {'path': paths.first, 'bookId': book.id},
              );
            }
          } catch (e) {
            developer.log('Could not open book: $e', name: 'LibraryScreen');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: book.coverPath.isNotEmpty && File(book.coverPath).existsSync()
                  ? Image.file(File(book.coverPath), fit: BoxFit.cover)
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.book, size: 50, color: Colors.grey),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
