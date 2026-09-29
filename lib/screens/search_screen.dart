import 'package:flutter/material.dart';
import '../services/local_bible.dart';
import '../services/local_store.dart';
import 'bible_reader_screen.dart';

/// Busca textual nos versículos (Fase 2 trará a busca semântica com IA).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<SearchHit> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.length < 3) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final translations = await LocalBible.availableTranslations();
      if (translations.isEmpty) throw 'Nenhuma tradução em assets/bibles/.';
      final saved = await LocalStore.translationId();
      final t = translations.firstWhere((x) => x.id == saved,
          orElse: () => translations.first);
      final r = await LocalBible.search(t.id, q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _searched = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro na busca: $e';
        _loading = false;
      });
    }
  }

  void _open(SearchHit hit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReaderScreen(
          bookId: hit.book.id,
          bookName: hit.book.name,
          chapterNumber: hit.chapter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: const InputDecoration(
            hintText: 'Buscar na Bíblia...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _searched && _results.isEmpty
                  ? const Center(child: Text('Nenhum versículo encontrado.'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final v = _results[i];
                        return ListTile(
                          title: Text(v.reference,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(v.text,
                              maxLines: 3, overflow: TextOverflow.ellipsis),
                          onTap: () => _open(v),
                        );
                      },
                    ),
    );
  }
}
