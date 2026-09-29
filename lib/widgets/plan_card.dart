import 'package:flutter/material.dart';
import '../screens/reading_plan_screen.dart';
import '../services/reading_plan_store.dart';

/// Atalho para o plano de leitura, com o resumo de hoje.
class PlanCard extends StatefulWidget {
  const PlanCard({super.key});

  @override
  State<PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<PlanCard> {
  PlanSnapshot? _snap;
  bool _loaded = false;

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
      _loaded = true;
    });
  }

  String get _subtitle {
    if (!_loaded) return '';
    final s = _snap;
    if (s == null) return 'Escolha um plano e leia um pouco a cada dia';
    if (s.finished) return '${s.plan.name} · concluído 🎉';
    final fire = s.streak > 0 ? ' · 🔥 ${s.streak}' : '';
    final today =
        s.todayDone ? 'leitura de hoje feita' : 'leitura de hoje pendente';
    return '${s.plan.name} · dia ${s.today} de ${s.plan.days} · $today$fire';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.event_available_outlined),
        title: const Text('Plano de leitura'),
        subtitle: Text(_subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReadingPlanScreen()),
          );
          _refresh();
        },
      ),
    );
  }
}
