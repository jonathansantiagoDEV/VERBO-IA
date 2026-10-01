import 'package:flutter/material.dart';
import '../services/local_bible.dart';
import '../services/strong_dictionary.dart';
import '../screens/bible_reader_screen.dart';

/// Folha com o original (hebraico, aramaico ou grego) e o significado
/// das palavras que o usuário tocou.
class StrongSheet extends StatefulWidget {
  final String word;
  final List<String> ids;
  final String translationId;

  const StrongSheet({
    super.key,
    required this.word,
    required this.ids,
    required this.translationId,
  });

  @override
  State<StrongSheet> createState() => _StrongSheetState();
}

class _StrongSheetState extends State<StrongSheet> {
  late final Future<List<StrongEntry?>> _future = Future.wait<StrongEntry?>(
      widget.ids.map((id) => StrongDictionary.entry(id)));

  Widget _section(BuildContext context, String title, String text) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 2),
            SelectableText(text),
          ],
        ),
      );

  Widget _card(BuildContext context, String id, StrongEntry? e) {
    final theme = Theme.of(context);
    final isGreek = id.startsWith('G');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$id · ${e?.language ?? (isGreek ? 'Grego' : 'Hebraico')}',
                style: theme.textTheme.labelLarge
                    ?.copyWith(color: theme.colorScheme.primary)),
            if (e == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Dicionário Strong não instalado. '
                    'Rode: python tools/montar_strong.py dicionario'),
              )
            else ...[
              const SizedBox(height: 8),
              Directionality(
                textDirection: isGreek ? TextDirection.ltr : TextDirection.rtl,
                child: SizedBox(
                  width: double.infinity,
                  child: Text(e.lemma,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium),
                ),
              ),
              if (e.translit != null || e.pron != null)
                Center(
                  child: Text(
                    [
                      if (e.translit != null) e.translit!,
                      if (e.pron != null) '(${e.pron})',
                    ].join(' '),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              if (e.meaning != null)
                _section(
                    context,
                    e.pt != null ? 'Significado' : 'Significado (Strong, em inglês)',
                    e.meaning!),
              if (e.pt != null && e.def != null)
                _section(context, 'Definição original (inglês)', e.def!),
              if (e.derivation != null && e.derivation!.isNotEmpty)
                _section(context, 'Origem', e.derivation!),
              if (e.kjvDef != null && e.kjvDef!.isNotEmpty)
                _section(context, 'Como a KJV traduz', e.kjvDef!),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.manage_search, size: 20),
                label: const Text('Ver ocorrências'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StrongOccurrencesScreen(
                        id: id, translationId: widget.translationId),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.word.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ''),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<StrongEntry?>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final list = snap.data!;
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (var i = 0; i < list.length; i++)
                        _card(context, widget.ids[i], list[i]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Todos os versículos da tradução em que o número Strong aparece.
class StrongOccurrencesScreen extends StatelessWidget {
  final String id;
  final String translationId;
  const StrongOccurrencesScreen(
      {super.key, required this.id, required this.translationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ocorrências de $id')),
      body: FutureBuilder<List<SearchHit>>(
        future: LocalBible.findStrong(translationId, id),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final hits = snap.data!;
          if (hits.isEmpty) {
            return const Center(child: Text('Nenhuma ocorrência encontrada.'));
          }
          return ListView.separated(
            itemCount: hits.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final h = hits[i];
              return ListTile(
                title: Text(h.reference,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text(h.text, maxLines: 3, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BibleReaderScreen(
                      bookId: h.book.id,
                      bookName: h.book.name,
                      chapterNumber: h.chapter,
                      initialVerse: h.verse,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
