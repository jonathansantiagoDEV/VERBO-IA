# Assinatura de release (Android)

1. Crie a chave (uma vez só). No Windows, o keytool vem com o Android Studio:
       "C:\Program Files\Android\Android Studio\jbr\bin\keytool" -genkey -v -keystore %USERPROFILE%\verbo-ia-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias verbo
   Guarde as senhas. FAÇA BACKUP do arquivo .jks fora do computador: sem ele você não consegue atualizar o app.
2. Copie `android/key.properties.example` para `android/key.properties` e preencha (use / no caminho). Esse arquivo não vai para o Git.
3. Gere o app:
       flutter build apk --release --dart-define=VERBO_API_URL=https://SEU-PROJETO.vercel.app --dart-define=VERBO_APP_KEY=sua_senha
   O arquivo fica em build/app/outputs/flutter-apk/app-release.apk (instale no celular).
   Para a Play Store, use `flutter build appbundle --release` com os mesmos --dart-define.
