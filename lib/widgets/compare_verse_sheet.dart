import 'package:flutter/material.dart';
import '../data/bible_translations.dart';
import '../services/local_bible.dart';
import '../services/verse_share.dart';

class _Row {
  final TranslationInfo translation;
  final String? text;
  const _Row(this.translation, this.text);
}

/// Mostra o mesmo versículo em todas as traduções instaladas.
class CompareVerseSheet extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapter;
  final int verse;
  final List<TranslationInfo> translations;

  const CompareVerseSheet({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.translations,
  });

  @override
  State<CompareVerseSheet> createState() => _CompareVerseSheetState();
}

class _CompareVerseSheetState extends State<CompareVerseSheet> {
  late final Future<List<_Row>> _future = _load();

  String get _reference =>
      '${widget.bookName} ${widget.chapter}:${widget.verse}';

  Future<List<_Row>> _load() {
    return Future.wait<_Row>(widget.translations.map((t) async {
      String? text;
      try {
        text = await LocalBible.verseText(
            t.id, widget.bookId, widget.chapter, widget.verse);
      } catch (_) {
        text = null;
      }
      return _Row(t, text);
    }));
  }

  Future<void> _copy(_Row r) async {
    await VerseShare.copy(VerseShare.format(
      reference: _reference,
      text: r.text!,
      translation: r.translation.shortName,
    ));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Versículo copiado.')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comparar traduções', style: theme.textTheme.titleMedium),
            Text(_reference, style: theme.textTheme.bodyMedium),
            if (widget.translations.length < 2)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Só há uma tradução instalada. Rode '
                  'tools/baixar_biblias.py para adicionar mais.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 8),
            Flexible(
              child: FutureBuilder<List<_Row>>(
                future: _future,
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return ListView(
                    shrinkWrap: true,
                    children: [
                      for (final r in snap.data!)
                        Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 6, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${r.translation.shortName} · ${r.translation.name}',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                                color:
                                                    theme.colorScheme.primary),
                                      ),
                                    ),
                                    if (r.text != null)
                                      IconButton(
                                        tooltip: 'Copiar',
                                        visualDensity: VisualDensity.compact,
                                        icon: const Icon(Icons.copy, size: 18),
                                        onPressed: () => _copy(r),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: SelectableText(
                                    r.text ??
                                        'Versículo não disponível nesta tradução.',
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(height: 1.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
