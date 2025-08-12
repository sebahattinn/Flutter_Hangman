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
      theme: ThemeData(primarySwatch: Colors.blue),
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appMessengerKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Adam Asmaca')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1) Oyuna Başla
              ElevatedButton(
                onPressed: () async {
                  try {
                    final movies = await fetchMovies();
                    final rnd = IndexController.getRandomMovie(movies);

                    final totalRounds = settings.mode == GameMode.classic
                        ? settings.rounds
                        : 1 << 30;

                    appNavigatorKey.currentState!.push(
                      MaterialPageRoute(
                        builder: (_) => GameIndex(
                          word: rnd['title'],
                          movieId: rnd['id'],
                          currentRound: 1,
                          totalRounds: totalRounds,
                          totalScore: 0, // 🔹 puan sayacı başlat
                        ),
                      ),
                    );
                  } catch (e) {
                    appMessengerKey.currentState?.showSnackBar(
                      SnackBar(content: Text('Film alınamadı: $e')),
                    );
                  }
                },
                child: const Text("Oyuna Başla"),
              ),

              const SizedBox(height: 16),

              // 2) Ayarlar
              ElevatedButton(
                onPressed: () {
                  appNavigatorKey.currentState!.push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: const Text("Ayarlar"),
              ),

              const SizedBox(height: 16),

              // 3) Çıkış
              ElevatedButton(
                onPressed: () {
                  appNavigatorKey.currentState!.push(
                    MaterialPageRoute(builder: (_) => const ExistScreen()),
                  );
                },
                child: const Text("Çıkış"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
