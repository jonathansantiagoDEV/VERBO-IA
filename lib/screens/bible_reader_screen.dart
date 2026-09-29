import 'dart:async';
import 'package:flutter/material.dart';
import '../services/reading_progress.dart';
import '../data/bible_catalog.dart';
import '../data/bible_translations.dart';
import '../services/local_bible.dart';
import '../services/local_store.dart';
import '../services/verse_share.dart';
import '../data/reading_plans.dart';
import '../services/reading_plan_store.dart';
import '../widgets/compare_verse_sheet.dart';

class BibleReaderScreen extends StatefulWidget {
  final String bookId;
  final String bookName;
  final int chapterNumber;

  /// Versículo a destacar e rolar até ele ao abrir (ex.: vindo dos favoritos).
  final int? initialVerse;
  final int? initialVerseEnd;

  const BibleReaderScreen({
    super.key,
    required this.bookId,
    required this.bookName,
    required this.chapterNumber,
    this.initialVerse,
    this.initialVerseEnd,
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
  int? _highlight;
  int? _highlightEnd;
  String? _planId;
  bool _inPlan = false;
  bool _chapterRead = false;
  final _targetKey = GlobalKey();
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _highlight = widget.initialVerse;
    _highlightEnd = widget.initialVerseEnd;
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
      final planId = await ReadingPlanStore.activePlanId();
      final plan = planId == null ? null : ReadingPlans.byId(planId);
      final inPlan =
          plan != null && plan.dayOf(widget.bookId, _chapterNumber) != null;
      final chapterRead = inPlan
          ? await ReadingPlanStore.isRead(planId!, widget.bookId, _chapterNumber)
          : false;
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
        _planId = planId;
        _inPlan = inPlan;
        _chapterRead = chapterRead;
        _loading = false;
      });
      _scheduleScroll();
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

  void _scheduleScroll() {
    if (_highlight == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _targetKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            alignment: 0.15,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut);
      }
    });
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _highlight = null);
    });
  }

  void _goTo(int chapter) {
    if (chapter < 1 || chapter > _chapterCount) return;
    _chapterNumber = chapter;
    _highlight = null;
    _highlightEnd = null;
    _highlightTimer?.cancel();
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

  Future<void> _toggleRead() async {
    final id = _planId;
    if (id == null) return;
    final next = !_chapterRead;
    await ReadingPlanStore.setRead(id, widget.bookId, _chapterNumber, next);
    if (!mounted) return;
    setState(() => _chapterRead = next);
    _snack(next ? 'Capítulo marcado como lido.' : 'Marcação removida.');
  }

  void _showCompare(int verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CompareVerseSheet(
        bookId: widget.bookId,
        bookName: widget.bookName,
        chapter: _chapterNumber,
        verse: verse,
        translations: _translations,
      ),
    );
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

  String _formatted(int verse) => VerseShare.format(
        reference: '${widget.bookName} $_chapterNumber:$verse',
        text: _verses[verse - 1],
        translation: _translation?.shortName,
      );

  void _showVerseActions(int verse) {
    final isMarked = _bookmarked.contains(_key(verse));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Text('${widget.bookName} $_chapterNumber:$verse',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              ListTile(
                leading: Icon(
                    isMarked ? Icons.bookmark : Icons.bookmark_border),
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
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copiar'),
                onTap: () async {
                  Navigator.pop(context);
                  await VerseShare.copy(_formatted(verse));
                  _snack('Versículo copiado.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Compartilhar'),
                onTap: () {
                  Navigator.pop(context);
                  VerseShare.share(_formatted(verse));
                },
              ),
              ListTile(
                leading: const Icon(Icons.compare_arrows),
                title: const Text('Comparar traduções'),
                onTap: () {
                  Navigator.pop(context);
                  _showCompare(verse);
                },
              ),
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
            ],
          ),
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
          if (_inPlan)
            IconButton(
              tooltip: _chapterRead
                  ? 'Desmarcar como lido'
                  : 'Marcar capítulo como lido',
              icon: Icon(_chapterRead
                  ? Icons.check_circle
                  : Icons.check_circle_outline),
              onPressed: _toggleRead,
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
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < _verses.length; i++)
            _buildVerse(i + 1, _verses[i], scheme),
        ],
      ),
    );
  }

  Widget _buildVerse(int number, String text, ColorScheme scheme) {
    final marked = _bookmarked.contains(_key(number));
    final noted = _noted.contains(_key(number));
    final hl = _highlight;
    final highlighted =
        hl != null && number >= hl && number <= (_highlightEnd ?? hl);
    return InkWell(
      key: number == hl ? _targetKey : null,
      onLongPress: () => _showVerseActions(number),
      child: Container(
        decoration: BoxDecoration(
          color: highlighted
              ? scheme.tertiaryContainer
              : marked
                  ? scheme.primaryContainer.withOpacity(0.45)
                  : null,
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
              TextSpan(text: text),
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
  }
}
