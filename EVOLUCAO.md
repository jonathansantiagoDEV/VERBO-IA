# Evolução do VERBO IA

## Feito nesta rodada
- Leitor: navegação anterior/próximo capítulo, tamanho de letra (salvo no aparelho), versículos favoritados destacados, ícone de nota, feedback de erro/sucesso, botão "tentar novamente".
- Busca textual (tela nova) com referência (Livro cap:vers) e abertura direta no capítulo.
- "Continuar leitura" na Home, lembrando o último capítulo lido.
- Chave anon do Supabase via `--dart-define` (sem colar no código).
- `.gitignore` protegendo keystore e `key.properties`.

## Como rodar
flutter pub get
flutter run --dart-define=SUPABASE_ANON_KEY=sua_chave

## Próximos passos sugeridos
1. Assinatura de release (key.properties + signingConfigs.release).
2. Tela de Favoritos e Notas (aba Perfil ou Estudos).
3. Fase 2: Edge Function "explicar versículo" + botão "Me explicar" no leitor.
4. Seletor de versão da Bíblia (hoje usa sempre a primeira ativa).

## Bíblia local (sem banco)
Livros e traduções agora vivem dentro do app. O Supabase virou opcional (só login).
- `lib/data/bible_catalog.dart`: os 66 livros, com abreviação e nº de capítulos.
- `lib/data/bible_translations.dart`: traduções conhecidas (ARC, KJV, ARA, NAA, NVI, DEMO).
- `assets/bibles/<id>.json`: o texto. A tradução só aparece no app se o arquivo existir.
- Formato: lista de 66 livros na ordem canônica; cada livro tem `chapters` = lista de capítulos = lista de versículos (strings).
- Validar um arquivo: `python tools/check_bible.py assets/bibles/arc.json`
- Favoritos, notas, tradução escolhida e último capítulo ficam no aparelho.
- ARA/NAA/NVI têm direitos autorais: só inclua com licença de distribuição.

## Baixar traduções
`python tools/baixar_biblias.py` baixa ACF, AA, NVI e KJV para assets/bibles/ (precisa de internet).
Depois: `flutter pub get` e `flutter run`. Para outras traduções (ARA, NAA...), coloque seu arquivo em assets/bibles/<id>.json.
