import 'package:flutter/material.dart';
import '../data/bible_catalog.dart';
import 'bible_reader_screen.dart';

class BibleChaptersScreen extends StatelessWidget {
  final BookInfo book;
  const BibleChaptersScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 64,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemCount: book.chapters,
        itemBuilder: (context, i) => OutlinedButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BibleReaderScreen(
                bookId: book.id,
                bookName: book.name,
                chapterNumber: i + 1,
              ),
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('${i + 1}'),
        ),
      ),
    );
  }
}
