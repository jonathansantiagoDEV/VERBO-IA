import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import '../services/verse_share.dart';

/// "Me explicar": explicação do versículo gerada por IA.
class ExplainSheet extends StatefulWidget {
  final String reference;
  final String text;
  final String translation;
  final List<String> strongs;

  const ExplainSheet({
    super.key,
    required this.reference,
    required this.text,
    required this.translation,
    this.strongs = const [],
  });

  @override
  State<ExplainSheet> createState() => _ExplainSheetState();
}

class _ExplainSheetState extends State<ExplainSheet> {
  late Future<String> _future = _run();

  Future<String> _run({bool force = false}) => AiService.explain(
        reference: widget.reference,
        text: widget.text,
        translation: widget.translation,
        strongs: widget.strongs,
        force: force,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Me explicar', style: theme.textTheme.titleLarge),
            Text(widget.reference, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<String>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${snap.error}'),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => setState(() => _future = _run()),
                          child: const Text('Tentar de novo'),
                        ),
                      ],
                    );
                  }
                  final answer = snap.data!;
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SelectableText(answer,
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(height: 1.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Explicação gerada por IA. Confira com a Bíblia e '
                          'com a sua liderança.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton.icon(
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copiar'),
                              onPressed: () async {
                                await VerseShare.copy(answer);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Explicação copiada.')));
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Gerar de novo'),
                              onPressed: () => setState(
                                  () => _future = _run(force: true)),
                            ),
                          ],
                        ),
                      ],
                    ),
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
