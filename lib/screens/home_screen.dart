import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/reading_progress.dart';
import 'bible_books_screen.dart';
import 'bible_reader_screen.dart';
import 'search_screen.dart';
import 'studies_tab.dart';
import '../widgets/plan_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [
    _HomeTab(),
    BibleBooksScreen(),
    _PlaceholderTab(title: 'IA', icon: Icons.auto_awesome),
    StudiesTab(),
    _PlaceholderTab(title: 'Perfil', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Bíblia'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), label: 'IA'),
          NavigationDestination(icon: Icon(Icons.school_outlined), label: 'Estudos'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context) {
    final userEmail =
        SupabaseConfig.ready ? (AuthService.currentUser?.email ?? '') : '';
    final firstName = userEmail.isEmpty ? '' : userEmail.split('@').first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          firstName.isEmpty ? 'Olá 👋' : 'Olá, $firstName 👋',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        const Text('O que você gostaria de estudar hoje?'),
        const SizedBox(height: 20),
        SearchBar(
          hintText: 'Pergunte à Bíblia...',
          leading: const Icon(Icons.search),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SearchScreen()),
          ),
        ),
        const SizedBox(height: 24),
        const _ContinueReadingCard(),
        const SizedBox(height: 12),
        const PlanCard(),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Devocional do dia',
          subtitle: 'Disponível a partir da Fase 3',
          icon: Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Estudar com IA',
          subtitle: 'Explicar · Contexto · Exegese · Aplicação',
          icon: Icons.auto_awesome,
        ),
      ],
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ReadingProgress.load(),
      builder: (context, snapshot) {
        final last = snapshot.data;
        return Card(
          child: ListTile(
            leading: const Icon(Icons.menu_book_rounded),
            title: const Text('Continuar leitura'),
            subtitle: Text(last == null
                ? 'Comece sua jornada pela Bíblia'
                : '${last.bookName} ${last.chapterNumber}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: last == null
                ? null
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BibleReaderScreen(
                          bookId: last.bookId,
                          bookName: last.bookName,
                          chapterNumber: last.chapterNumber,
                        ),
                      ),
                    ),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {},
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderTab({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text('$title — chega nas próximas fases', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
