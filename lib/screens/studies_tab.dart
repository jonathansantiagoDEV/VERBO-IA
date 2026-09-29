import 'package:flutter/material.dart';
import '../services/local_store.dart';
import '../widgets/plan_card.dart';
import 'saved_screen.dart';

/// Aba "Estudos": ponto de entrada dos recursos de estudo pessoal.
class StudiesTab extends StatefulWidget {
  const StudiesTab({super.key});

  @override
  State<StudiesTab> createState() => _StudiesTabState();
}

class _StudiesTabState extends State<StudiesTab> {
  String _summary = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final marks = await LocalStore.bookmarks();
    final notes = await LocalStore.notes();
    final noteCount = notes.values.fold<int>(0, (n, l) => n + l.length);
    if (!mounted) return;
    setState(() => _summary = '${marks.length} favoritos · $noteCount notas');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Estudos', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        const PlanCard(),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Favoritos e notas'),
            subtitle: Text(_summary),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavedScreen()),
              );
              _load();
            },
          ),
        ),
      ],
    );
  }
}
