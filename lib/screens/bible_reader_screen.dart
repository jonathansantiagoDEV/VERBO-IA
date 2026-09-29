import 'package:flutter/material.dart';
import '../services/reading_progress.dart';
import '../data/bible_catalog.dart';
import '../data/bible_translations.dart';
import '../services/local_bible.dart';
import '../services/local_store.dart';

class BibleReaderScreen extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapterNumber;

  const BibleReaderScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
  });

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  late int _chapterNumber = widget.chapterNumber;
  late final int _chapterCount =
      BibleCatalog.byId(widget.bookId)?.chapters ?? 1;
  List<TranslationInfo> _translations = [];
  TranslationInfo? _translation;
  List<String> _verses = [];
  Set<String> _bookmarked = {};
  Set<String> _noted = {};
  double _fontSize = 17;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    ReadingProgress.loadFontSize().then((v) {
      if (mounted) setState(() => _fontSize = v);
    });
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_translation == null) {
        _translations = await LocalBible.availableTranslations();
        if (_translations.isEmpty) {
          throw 'Nenhuma tradução encontrada em assets/bibles/.';
        }
        final saved = await LocalStore.translationId();
        _translation = _translations.firstWhere(
          (t) => t.id == saved,
          orElse: () => _translations.first,
        );
      }
      final verses = await LocalBible.verses(
          _translation!.id, widget.bookId, _chapterNumber);
      final marks = await LocalStore.bookmarks();
      final notes = await LocalStore.notes();
      await ReadingProgress.save(
        bookId: widget.bookId,
        bookName: widget.bookName,
        chapterNumber: _chapterNumber,
      );
      if (!mounted) return;
      setState(() {
        _verses = verses;
        _bookmarked = marks;
        _noted = notes.keys.toSet();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar o capítulo.\n$e';
        _loading = false;
      });
    }
  }

  String _key(int verseNumber) =>
      LocalStore.key(widget.bookId, _chapterNumber, verseNumber);

  void _showTranslationSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tradução'),
            ),
            for (final t in _translations)
              ListTile(
                leading: Icon(t.id == _translation?.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off),
                title: Text(t.shortName),
                subtitle: Text(t.name),
                onTap: () async {
                  Navigator.pop(context);
                  await LocalStore.setTranslationId(t.id);
                  _translation = t;
                  _load();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _goTo(int chapter) {
    if (chapter < 1 || chapter > _chapterCount) return;
    _chapterNumber = chapter;
    _load();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _toggleBookmark(int verseNumber) async {
    final k = _key(verseNumber);
    final added = await LocalStore.toggleBookmark(k);
    setState(() => added ? _bookmarked.add(k) : _bookmarked.remove(k));
  }

  void _showFontSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tamanho da letra'),
                Slider(
                  min: 14,
                  max: 28,
                  divisions: 14,
                  value: _fontSize,
                  label: _fontSize.round().toString(),
                  onChanged: (v) {
                    setSheet(() {});
                    setState(() => _fontSize = v);
                  },
                  onChangeEnd: ReadingProgress.saveFontSize,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVerseActions(int verse) {
    final isMarked = _bookmarked.contains(_key(verse));
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            const ListTile(
              leading: Icon(Icons.auto_awesome),
              title: Text('Me explicar'),
              subtitle: Text('Disponível a partir da Fase 2 (IA)'),
              enabled: false,
            ),
            const ListTile(
              leading: Icon(Icons.link),
              title: Text('Referências'),
              subtitle: Text('Disponível a partir da Fase 2 (IA)'),
              enabled: false,
            ),
            ListTile(
              leading: Icon(isMarked ? Icons.bookmark : Icons.bookmark_border),
              title: Text(isMarked ? 'Remover dos favoritos' : 'Favoritar'),
              onTap: () {
                Navigator.pop(context);
                _toggleBookmark(verse);
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('Anotar'),
              onTap: () {
                Navigator.pop(context);
                _showNoteDialog(verse);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(int verse) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
            'Nova nota — ${widget.bookName} $_chapterNumber:$verse'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escreva sua nota...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(dialogContext);
              await LocalStore.addNote(_key(verse), text);
              setState(() => _noted.add(_key(verse)));
              _snack('Nota salva.');
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.bookName} $_chapterNumber'),
        actions: [
          if (_translation != null)
            TextButton(
              onPressed: _showTranslationSheet,
              child: Text(_translation!.shortName),
            ),
          IconButton(
            tooltip: 'Tamanho da letra',
            icon: const Icon(Icons.text_fields),
            onPressed: _showFontSheet,
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _chapterNumber > 1 && !_loading
                        ? () => _goTo(_chapterNumber - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Anterior'),
                  ),
                  Text('$_chapterNumber / $_chapterCount'),
                  TextButton(
                    onPressed: _chapterNumber < _chapterCount && !_loading
                        ? () => _goTo(_chapterNumber + 1)
                        : null,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [Text('Próximo'), Icon(Icons.chevron_right)],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                  onPressed: _load, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }
    if (_verses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Este capítulo não está disponível na tradução '
            '${_translation?.shortName ?? ''}.\n'
            'Troque a tradução no topo da tela.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _verses.length,
      itemBuilder: (context, i) {
        final number = i + 1;
        final marked = _bookmarked.contains(_key(number));
        final noted = _noted.contains(_key(number));
        final scheme = Theme.of(context).colorScheme;
        return InkWell(
          onLongPress: () => _showVerseActions(number),
          child: Container(
            decoration: BoxDecoration(
              color: marked ? scheme.primaryContainer.withOpacity(0.45) : null,
              borderRadius: BorderRadius.circular(6),
            ),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Text.rich(
              TextSpan(
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      fontSize: _fontSize,
                      height: 1.6,
                      color: scheme.onSurface,
                    ),
                children: [
                  TextSpan(
                    text: '$number ',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  TextSpan(text: _verses[i]),
                  if (noted)
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Icon(Icons.sticky_note_2_outlined,
                            size: _fontSize, color: scheme.primary),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
