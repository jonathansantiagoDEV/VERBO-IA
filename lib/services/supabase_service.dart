import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// true quando o usuário escolheu "Continuar sem conta" no login.
final ValueNotifier<bool> guestMode = ValueNotifier(false);

/// Configuração central do Supabase para o app VERBO IA.
///
/// IMPORTANTE: nunca coloque a `service_role key` aqui — apenas a
/// `anon public key`, que é segura para uso no cliente porque todo o
/// controle de acesso real é feito via Row Level Security (RLS) no banco.
class SupabaseConfig {
  // TODO: troque pela URL do seu projeto (Settings -> API no painel Supabase)
  static const String supabaseUrl = 'https://pbvazsitelrmcbevttvq.supabase.co';

  // Passe a "anon public" key na hora de rodar/compilar, sem fixar no código:
  //   flutter run --dart-define=SUPABASE_ANON_KEY=sua_chave
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'COLE_AQUI_A_ANON_KEY',
  );

  /// true quando o Supabase foi iniciado com sucesso. Sem chave (ou sem
  /// internet/projeto), o app funciona em modo local, sem conta.
  static bool ready = false;

  static Future<void> init() async {
    if (supabaseAnonKey == 'COLE_AQUI_A_ANON_KEY') return;
    try {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
      ready = true;
    } catch (_) {
      ready = false;
    }
  }
}

/// Atalho para acessar o client do Supabase em qualquer lugar do app.
final supabase = Supabase.instance.client;

class AuthService {
  /// Login com Google, usando o fluxo nativo Android (deep link).
  /// O redirectTo precisa bater com o deep link configurado no
  /// Supabase (Authentication -> URL Configuration) e no
  /// AndroidManifest.xml.
  static Future<bool> signInWithGoogle() async {
    return supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.verboia.app://login-callback',
    );
  }

  static Future<void> signInWithEmail(String email, String password) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  static Future<void> signUpWithEmail(String email, String password) async {
    await supabase.auth.signUp(email: email, password: password);
  }

  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  static User? get currentUser => supabase.auth.currentUser;

  static Stream<AuthState> get authStateChanges =>
      supabase.auth.onAuthStateChange;
}

/// Serviço de acesso à Bíblia digital (leitura pública, sem RLS de usuário).
class BibleService {
  static Future<List<Map<String, dynamic>>> getVersions() async {
    final data = await supabase
        .from('bible_versions')
        .select()
        .eq('is_active', true)
        .order('code');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getBooks(String versionId) async {
    final data = await supabase
        .from('bible_books')
        .select()
        .eq('version_id', versionId)
        .order('book_number');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getChapters(String bookId) async {
    final data = await supabase
        .from('bible_chapters')
        .select()
        .eq('book_id', bookId)
        .order('chapter_number');
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>?> getChapterByNumber(
      String bookId, int chapterNumber) async {
    return supabase
        .from('bible_chapters')
        .select()
        .eq('book_id', bookId)
        .eq('chapter_number', chapterNumber)
        .maybeSingle();
  }

  static Future<List<Map<String, dynamic>>> getVerses(String chapterId) async {
    final data = await supabase
        .from('bible_verses')
        .select()
        .eq('chapter_id', chapterId)
        .order('verse_number');
    return List<Map<String, dynamic>>.from(data);
  }

  /// Busca textual simples (usa o índice full-text já criado no banco).
  static Future<List<Map<String, dynamic>>> searchText(String query) async {
    final data = await supabase
        .from('bible_verses')
        .select('id, verse_number, text, chapter_id, '
            'bible_chapters(chapter_number, bible_books(id, name))')
        .textSearch('search_vector', query, config: 'portuguese')
        .limit(50);
    return List<Map<String, dynamic>>.from(data);
  }
}

/// Notas, destaques e favoritos pessoais (protegidos por RLS: cada
/// usuário só enxerga os próprios registros).
class PersonalContentService {
  /// IDs (entre [verseIds]) que o usuário atual favoritou.
  static Future<Set<String>> bookmarkedAmong(List<String> verseIds) async {
    if (verseIds.isEmpty) return {};
    final data = await supabase
        .from('bookmarks')
        .select('verse_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .inFilter('verse_id', verseIds);
    return {for (final r in data) r['verse_id'] as String};
  }

  /// IDs (entre [verseIds]) que já têm alguma nota do usuário atual.
  static Future<Set<String>> notedAmong(List<String> verseIds) async {
    if (verseIds.isEmpty) return {};
    final data = await supabase
        .from('notes')
        .select('verse_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .inFilter('verse_id', verseIds);
    return {for (final r in data) r['verse_id'] as String};
  }

  static Future<void> addNote(String verseId, String content) async {
    await supabase.from('notes').insert({
      'user_id': supabase.auth.currentUser!.id,
      'verse_id': verseId,
      'content': content,
    });
  }

  static Future<void> toggleBookmark(String verseId) async {
    final existing = await supabase
        .from('bookmarks')
        .select('id')
        .eq('verse_id', verseId)
        .eq('user_id', supabase.auth.currentUser!.id)
        .maybeSingle();

    if (existing == null) {
      await supabase.from('bookmarks').insert({
        'user_id': supabase.auth.currentUser!.id,
        'verse_id': verseId,
      });
    } else {
      await supabase.from('bookmarks').delete().eq('id', existing['id']);
    }
  }

  static Future<void> highlight(String verseId, String color) async {
    await supabase.from('highlights').insert({
      'user_id': supabase.auth.currentUser!.id,
      'verse_id': verseId,
      'color': color,
    });
  }
}
