/// Traduções que o app sabe carregar. Cada uma vira um arquivo
/// `assets/bibles/<id>.json`. A tradução só aparece no app se o arquivo
/// existir, então basta colocar o JSON na pasta e recompilar.
class TranslationInfo {
  final String id;
  final String name;
  final String shortName;
  final String language;
  final bool publicDomain;

  /// Texto com números Strong (`palavra<H1121>`): as palavras marcadas
  /// abrem o dicionário com o original hebraico, aramaico ou grego.
  final bool strong;

  const TranslationInfo(
      this.id, this.name, this.shortName, this.language, this.publicDomain,
      {this.strong = false});

  String get asset => 'assets/bibles/$id.json';
}

class BibleTranslations {
  static const List<TranslationInfo> all = [
    TranslationInfo('arc', 'Almeida Revista e Corrigida', 'ARC', 'pt', true),
    TranslationInfo('kjv', 'King James Version', 'KJV', 'en', true),
    // Abaixo: têm direitos autorais. Só inclua o arquivo se você tiver
    // licença para distribuir o texto dentro do app.
    TranslationInfo(
        'acf', 'Almeida Corrigida Fiel', 'ACF', 'pt', false),
    TranslationInfo(
        'aa', 'Almeida Revisada Imprensa Bíblica', 'AA', 'pt', false),
    TranslationInfo('ara', 'Almeida Revista e Atualizada', 'ARA', 'pt', false),
    TranslationInfo('naa', 'Nova Almeida Atualizada', 'NAA', 'pt', false),
    TranslationInfo('nvi', 'Nova Versão Internacional', 'NVI', 'pt', false),
    // Traduções com números Strong. Veja tools/montar_strong.py.
    TranslationInfo('kjvs', 'King James com Strong', 'KJV+S', 'en', true,
        strong: true),
    TranslationInfo('acfs', 'Almeida Corrigida Fiel com Strong', 'ACF+S', 'pt',
        false,
        strong: true),
    TranslationInfo('aras', 'Almeida Revista e Atualizada com Strong', 'ARA+S',
        'pt', false,
        strong: true),
    TranslationInfo(
        'demos', 'Demonstração com Strong (João 1:1-5)', 'DEMO+S', 'pt', true,
        strong: true),
    // Amostra pequena só para testar o app (João 1:1-5).
    TranslationInfo('demo', 'Demonstração (João 1:1-5)', 'DEMO', 'pt', true),
  ];

  static TranslationInfo? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
