import 'package:flutter/material.dart';
import '../data/bible_catalog.dart';
import '../services/local_bible.dart';
import '../services/local_store.dart';
import '../services/verse_share.dart';
import 'bible_reader_screen.dart';

class _SavedItem {
  final String key;
  final BookInfo book;
  final int chapter;
  final int verse;
  final String? text;
  const _SavedItem(this.key, this.book, this.chapter, this.verse, this.text);

  String get reference => '${book.name} $chapter:$verse';
}

/// Tudo o que o usuário salvou: versículos favoritos e notas.
class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  bool _loading = true;
  String? _error;
  String? _translationName;
  List<_SavedItem> _bookmarks = [];
  List<_SavedItem> _noted = [];
  Map<String, List<String>> _notes = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<List<_SavedItem>> _build(Iterable<String> keys, String? tId) async {
    final items = <_SavedItem>[];
    for (final k in keys) {
      final p = LocalStore.parseKey(k);
      final book = p == null ? null : BibleCatalog.byId(p.bookId);
      if (p == null || book == null) continue;
      String? text;
      if (tId != null) {
        try {
          text = await LocalBible.verseText(tId, p.bookId, p.chapter, p.verse);
        } catch (_) {
          text = null;
        }
      }
      items.add(_SavedItem(k, book, p.chapter, p.verse, text));
    }
    items.sort((a, b) {
      final c = BibleCatalog.indexOf(a.book.id)
          .compareTo(BibleCatalog.indexOf(b.book.id));
      if (c != 0) return c;
      final ch = a.chapter.compareTo(b.chapter);
      return ch != 0 ? ch : a.verse.compareTo(b.verse);
    });
    return items;
  }

  Future<void> _load() async {
    try {
      final t = await LocalBible.currentTranslation();
      final marks = await LocalStore.bookmarks();
      final notes = await LocalStore.notes();
      final bookmarks = await _build(marks, t?.id);
      final noted = await _build(notes.keys, t?.id);
      if (!mounted) return;
      setState(() {
        _translationName = t?.shortName;
        _bookmarks = bookmarks;
        _noted = noted;
        _notes = notes;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar seus itens salvos.\n$e';
        _loading = false;
      });
    }
  }

  void _snack(String msg, {SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), action: action));
  }

  Future<void> _open(_SavedItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReaderScreen(
          bookId: item.book.id,
          bookName: item.book.name,
          chapterNumber: item.chapter,
          initialVerse: item.verse,
        ),
      ),
    );
    _load();
  }

  String? _formatted(_SavedItem item) => item.text == null
      ? null
      : VerseShare.format(
          reference: item.reference,
          text: item.text!,
          translation: _translationName,
        );

  Future<void> _removeBookmark(_SavedItem item) async {
    setState(() => _bookmarks.removeWhere((b) => b.key == item.key));
    await LocalStore.setBookmark(item.key, false);
    _snack(
      'Favorito removido: ${item.reference}',
      action: SnackBarAction(
        label: 'Desfazer',
        onPressed: () async {
          await LocalStore.setBookmark(item.key, true);
          _load();
        },
      ),
    );
  }

  Future<void> _bookmarkMenu(String action, _SavedItem item) async {
    switch (action) {
      case 'copy':
        final t = _formatted(item);
        if (t == null) return _snack('Texto indisponível nesta tradução.');
        await VerseShare.copy(t);
        _snack('Versículo copiado.');
      case 'share':
        final t = _formatted(item);
        if (t == null) return _snack('Texto indisponível nesta tradução.');
        await VerseShare.share(t);
      case 'remove':
        await _removeBookmark(item);
    }
  }

  Future<String?> _noteDialog(String title, {String initial = ''}) {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escreva sua nota...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isEmpty) return;
              Navigator.pop(ctx, t);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(_SavedItem item, int index) async {
    final current = _notes[item.key]![index];
    final text =
        await _noteDialog('Editar nota — ${item.reference}', initial: current);
    if (text == null) return;
    await LocalStore.updateNote(item.key, index, text);
    _load();
  }

  Future<void> _deleteNote(_SavedItem item, int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar nota?'),
        content: Text(_notes[item.key]![index]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Apagar')),
        ],
      ),
    );
    if (ok != true) return;
    await LocalStore.removeNote(item.key, index);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final noteCount = _notes.values.fold<int>(0, (n, l) => n + l.length);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favoritos e notas'),
          bottom: TabBar(tabs: [
            Tab(text: 'Favoritos (${_bookmarks.length})'),
            Tab(text: 'Notas ($noteCount)'),
          ]),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          FilledButton(
                              onPressed: _load,
                              child: const Text('Tentar novamente')),
                        ],
                      ),
                    ),
                  )
                : TabBarView(children: [_bookmarksTab(), _notesTab()]),
      ),
    );
  }

  Widget _empty(String msg) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(msg, textAlign: TextAlign.center),
        ),
      );

  Widget _verseText(_SavedItem item) => Text(
        item.text ?? 'Texto indisponível nesta tradução.',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );

  Widget _bookmarksTab() {
    if (_bookmarks.isEmpty) {
      return _empty('Nenhum favorito ainda.\n'
          'Segure um versículo na leitura e toque em Favoritar.');
    }
    return ListView.separated(
      itemCount: _bookmarks.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final item = _bookmarks[i];
        return Dismissible(
          key: ValueKey('bm-${item.key}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete_outline),
          ),
          onDismissed: (_) => _removeBookmark(item),
          child: ListTile(
            title: Text(item.reference,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _verseText(item),
            onTap: () => _open(item),
            trailing: PopupMenuButton<String>(
              onSelected: (a) => _bookmarkMenu(a, item),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'copy', child: Text('Copiar')),
                PopupMenuItem(value: 'share', child: Text('Compartilhar')),
                PopupMenuItem(value: 'remove', child: Text('Remover')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _notesTab() {
    if (_noted.isEmpty) {
      return _empty('Nenhuma nota ainda.\n'
          'Segure um versículo na leitura e toque em Anotar.');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _noted.length,
      itemBuilder: (context, i) {
        final item = _noted[i];
        final notes = _notes[item.key] ?? const <String>[];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(item.reference,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: _verseText(item),
                onTap: () => _open(item),
              ),
              for (var n = 0; n < notes.length; n++)
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.sticky_note_2_outlined, size: 20),
                  title: Text(notes[n]),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => _editNote(item, n),
                      ),
                      IconButton(
                        tooltip: 'Apagar',
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () => _deleteNote(item, n),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }
}
