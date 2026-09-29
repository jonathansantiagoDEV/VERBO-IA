# VERBO IA — App Android (Flutter)

Fase 1: estrutura do app com **Autenticação** (e-mail/senha + Google nativo) e **Bíblia digital** (livros → capítulos → versículos, favoritos e notas).

## 1. Pré-requisitos

- **Flutter SDK** instalado (https://docs.flutter.dev/get-started/install/windows) — depois de instalar, rode `flutter doctor` no terminal e resolva qualquer pendência apontada.
- **Android Studio** já instalado (você já tem).
- Um dispositivo Android físico com depuração USB ativada, ou um emulador criado no Android Studio.

## 2. Colocando o projeto para rodar

1. Extraia esta pasta em `C:\VERBO IA\app` (ou onde preferir).
2. No terminal, dentro da pasta do projeto:
   ```
   flutter pub get
   ```
3. Abra `lib/services/supabase_service.dart` e cole a sua **anon public key** do Supabase no lugar de `COLE_AQUI_A_ANON_KEY`.
   - Pegue em: Supabase → projeto `verbo-ia` → **Settings → API → Project API keys → anon public**.
   - Essa chave é segura para ficar no app (não é a `service_role key`, que é secreta e nunca deve ir para o cliente).
4. Conecte o celular (ou abra o emulador) e rode:
   ```
   flutter run
   ```

## 3. O que já funciona nessa versão

- Tela de login: e-mail/senha e "Continuar com Google" (fluxo nativo, com o deep link `io.verboia.app://login-callback` já configurado no `AndroidManifest.xml`).
- Home com atalhos (a maioria ainda são placeholders das próximas fases).
- Bíblia digital completa: lista de livros (AT/NT em abas), capítulos, leitura de versículos.
- Ao segurar (long press) em um versículo: favoritar e adicionar nota — já salvos no Supabase, protegidos por RLS (só o próprio usuário vê).

## 4. O que ainda falta (próximas fases)

- Explicação de versículo por IA, busca semântica, exegese, sermões, devocionais, EBD, planos de leitura, quiz, assinaturas — tudo isso é Fase 2 em diante, conforme o roadmap combinado.
- Assinar o app com o keystore de release (`verbo-ia-release.keystore`) antes de publicar — hoje o `build.gradle` usa a assinatura de debug para simplificar o desenvolvimento.

## 5. Estrutura de pastas

```
lib/
├── main.dart                    # entrada do app, tema, AuthGate
├── services/
│   └── supabase_service.dart    # Auth, Bíblia, notas/favoritos
└── screens/
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── home_screen.dart         # bottom navigation
    ├── bible_books_screen.dart
    ├── bible_chapters_screen.dart
    └── bible_reader_screen.dart
```
