import 'package:flutter/material.dart';
import '../data/bible_catalog.dart';
import '../data/reading_plans.dart';
import '../services/reading_plan_store.dart';
import 'bible_reader_screen.dart';

/// Plano de leitura: escolha do plano, leitura de hoje, dias atrasados,
/// progresso e dias seguidos. Funciona sem internet.
class ReadingPlanScreen extends StatefulWidget {
  const ReadingPlanScreen({super.key});

  @override
  State<ReadingPlanScreen> createState() => _ReadingPlanScreenState();
}

class _ReadingPlanScreenState extends State<ReadingPlanScreen> {
  static const _maxPending = 14;

  PlanSnapshot? _snap;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final s = await ReadingPlanStore.snapshot();
    if (!mounted) return;
    setState(() {
      _snap = s;
      _loading = false;
    });
  }

  Future<void> _start(ReadingPlan plan) async {
    await ReadingPlanStore.activate(plan.id);
    _refresh();
  }

  Future<void> _setRead(PlanSnapshot s, ChapterRef c, bool value) async {
    await ReadingPlanStore.setRead(s.plan.id, c.bookId, c.chapter, value);
    _refresh();
  }

  Future<void> _open(ChapterRef c) async {
    final book = BibleCatalog.byId(c.bookId);
    if (book == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReaderScreen(
          bookId: book.id,
          bookName: book.name,
          chapterNumber: c.chapter,
        ),
      ),
    );
    _refresh();
  }

  Future<void> _restart(PlanSnapshot s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recomeçar plano?'),
        content: const Text(
            'Volta para o dia 1 e apaga o que você marcou como lido neste plano.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Recomeçar')),
        ],
      ),
    );
    if (ok != true) return;
    await ReadingPlanStore.restart(s.plan.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = _snap;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plano de leitura'),
        actions: [
          if (s != null)
            PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'switch') {
                  await ReadingPlanStore.deactivate();
                  _refresh();
                } else if (v == 'restart') {
                  _restart(s);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'switch', child: Text('Trocar plano')),
                PopupMenuItem(
                    value: 'restart', child: Text('Recomeçar do dia 1')),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : s == null
              ? _buildPicker()
              : _buildDashboard(s),
    );
  }

  Widget _buildPicker() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Escolha um plano',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        const Text('Você marca o que leu e acompanha seus dias seguidos.'),
        const SizedBox(height: 12),
        for (final plan in ReadingPlans.all)
          Card(
            child: ListTile(
              title: Text(plan.name),
              subtitle: Text('${plan.description}\n'
                  '${plan.chapters.length} capítulos em ${plan.days} dias'),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _start(plan),
            ),
          ),
      ],
    );
  }

  Widget _buildDashboard(PlanSnapshot s) {
    final theme = Theme.of(context);
    final pending = s.pendingDays();
    final streakText = s.streak == 0
        ? 'Leia hoje para começar sua sequência'
        : s.streak == 1
            ? '1 dia seguido'
            : '${s.streak} dias seguidos';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.plan.name, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(s.finished
                    ? 'Plano concluído! 🎉'
                    : 'Dia ${s.today} de ${s.plan.days}'),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                      value: s.progress, minHeight: 10),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${s.readCount} de ${s.totalChapters} capítulos'),
                    Text('${(s.progress * 100).floor()}%'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.local_fire_department,
                        color: s.streak > 0 ? Colors.orange : Colors.grey),
                    const SizedBox(width: 6),
                    Text(streakText),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Leitura de hoje · dia ${s.today}',
            style: theme.textTheme.titleMedium),
        if (s.todayDone)
          Card(
            color: theme.colorScheme.primaryContainer,
            child: const ListTile(
              leading: Icon(Icons.check_circle),
              title: Text('Leitura de hoje concluída!'),
            ),
          ),
        for (final c in s.todayChapters) _chapterTile(s, c),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Dias atrasados (${pending.length})',
                style: theme.textTheme.titleMedium),
            children: [
              for (final d in pending.take(_maxPending)) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Dia $d',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.primary)),
                  ),
                ),
                for (final c in s.plan.chaptersForDay(d))
                  if (!s.read.contains(c.key)) _chapterTile(s, c),
              ],
              if (pending.length > _maxPending)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                      'e mais ${pending.length - _maxPending} dias atrasados'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chapterTile(PlanSnapshot s, ChapterRef c) {
    final book = BibleCatalog.byId(c.bookId);
    final done = s.read.contains(c.key);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: done,
        onChanged: (v) => _setRead(s, c, v ?? false),
      ),
      title: Text(
        '${book?.name ?? c.bookId} ${c.chapter}',
        style: done
            ? const TextStyle(
                decoration: TextDecoration.lineThrough, color: Colors.grey)
            : null,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(c),
    );
  }
}
