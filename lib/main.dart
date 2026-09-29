import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/supabase_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.init();
  runApp(const ProviderScope(child: VerboIaApp()));
}

class VerboIaApp extends StatelessWidget {
  const VerboIaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.merriweatherTextTheme();

    return MaterialApp(
      title: 'VERBO IA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E5339), // verde profundo, tema bíblico/orgânico
        brightness: Brightness.light,
        textTheme: baseTextTheme,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E5339),
        brightness: Brightness.dark,
        textTheme: baseTextTheme,
      ),
      themeMode: ThemeMode.system,
      // No PC/navegador, limita a largura para o app não esticar demais.
      builder: (context, child) => ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: child,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

/// Decide, com base no estado de autenticação, se mostra o login
/// ou a Home do app.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    // Sem Supabase configurado, o app abre direto, em modo local.
    if (!SupabaseConfig.ready) return const HomeScreen();
    return ValueListenableBuilder<bool>(
      valueListenable: guestMode,
      builder: (context, isGuest, _) =>
          isGuest ? const HomeScreen() : _authStream(),
    );
  }

  Widget _authStream() {
    return StreamBuilder(
      stream: AuthService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }
        final session = AuthService.currentUser;
        if (session == null) {
          return const LoginScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
