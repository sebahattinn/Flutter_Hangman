import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:hangman/Controller/index_controller.dart';
import 'package:hangman/services/dio_get_movie.dart';
import 'package:hangman/screens/exist_screen.dart';
import 'package:hangman/screens/game_index.dart';
import 'package:hangman/screens/settings_screen.dart';
import 'package:hangman/Controller/settings_controller.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(
    ChangeNotifierProvider(
      create: (_) => SettingsController(),
      child: const Uygulamam(),
    ),
  );
}

class Uygulamam extends StatelessWidget {
  const Uygulamam({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    if (!settings.isLoaded) {
      return const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 211, 237, 119),
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      home: const MainMenuScreen(),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  Future<void> _startGame(BuildContext context) async {
    final settings = context.read<SettingsController>();
    try {
      final movies = await fetchMovies();
      final rnd = IndexController.getRandomMovie(movies);

      final totalRounds =
          settings.mode == GameMode.classic ? settings.rounds : 1 << 30;

      appNavigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => GameIndex(
            word: rnd['title'],
            movieId: rnd['id'],
            currentRound: 1,
            totalRounds: totalRounds,
            totalScore: 0,
          ),
        ),
      );
    } catch (e) {
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Film alınamadı: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        // Arka plan gradient (daha açık tonlar)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.9, -1),
            end: Alignment(1, 1),
            colors: [
              Color.fromARGB(255, 130, 234, 200), // çok açık mavi-gri
              Color.fromARGB(255, 211, 99, 99), // pastel açık mor
              Color.fromARGB(255, 52, 64, 227), // yumuşak açık ton
            ],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _GlassCard(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Adam Asmaca",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Film isimlerini tahmin etmeye çalışın.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Görsel kısmı (renk filtresini kaldırdık)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        color: Colors.white.withOpacity(.06),
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/cop_adam.png',
                          height: 140,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Butonlar
                    _MenuButton(
                      label: "Oyuna Başla",
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => _startGame(context),
                      filled: true,
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      label: "Ayarlar",
                      icon: Icons.settings_rounded,
                      onPressed: () => appNavigatorKey.currentState!.push(
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuButton(
                      label: "Çıkış",
                      icon: Icons.logout_rounded,
                      onPressed: () => appNavigatorKey.currentState!.push(
                        MaterialPageRoute(builder: (_) => const ExistScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cam efekti kart
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Tutarlı buton (hover + doldurulmuş varyant)
class _MenuButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;

  const _MenuButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.filled = false,
  });

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.filled
        ? (_hover ? const Color(0xFF6C73D1) : const Color(0xFF5A61C6))
        : Colors.white.withOpacity(_hover ? 0.15 : 0.10);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withOpacity(widget.filled ? 0.0 : 0.18),
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
