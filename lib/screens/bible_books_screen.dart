import 'package:flutter/material.dart';
import '../data/bible_catalog.dart';
import 'bible_chapters_screen.dart';

class BibleBooksScreen extends StatelessWidget {
  const BibleBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(tabs: [
            Tab(text: 'Antigo Testamento'),
            Tab(text: 'Novo Testamento'),
          ]),
          Expanded(
            child: TabBarView(
              children: [
                _BookList(books: BibleCatalog.byTestament(Testament.ot)),
                _BookList(books: BibleCatalog.byTestament(Testament.nt)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final List<BookInfo> books;
  const _BookList({required this.books});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: books.length,
      itemBuilder: (context, i) {
        final book = books[i];
        return ListTile(
          title: Text(book.name),
          subtitle: Text('${book.abbr} · ${book.chapters} capítulos'),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BibleChaptersScreen(book: book),
            ),
          ),
        );
      },
    );
  }
}
