import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:hangman/main.dart';

import 'package:hangman/screens/game_index.dart';
import 'package:hangman/screens/settings_screen.dart';
import 'package:hangman/screens/exist_screen.dart';

import 'package:hangman/Controller/index_controller.dart';

/// Uygulamanın giriş noktası sayfası (hoş geldin ekranı + GetX routing)
class IndexApp extends StatelessWidget {
  const IndexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Adam Asmaca',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      initialRoute: '/',
      getPages: [
        GetPage(
            name: '/',
            page: () => const WelcomeScreen(),
            transition: Transition.fadeIn),
        GetPage(
            name: '/game',
            page: () => const GameIndex(),
            transition: Transition.rightToLeft),
        GetPage(
            name: '/settings',
            page: () => SettingsScreen(),
            transition: Transition.downToUp),
        GetPage(
            name: '/exit',
            page: () => const ExistScreen(),
            transition: Transition.cupertino),
      ],
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
    );
  }
}

/// Hoş geldin ekranı (Index)
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/cop_adam.png',
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  'Adam Asmaca\'ya Hoş Geldin!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kelimeyi tahmin etmeye hazır mısın?',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () {
                    // Controller zaten AppBindings ile register ise find; değilse put et
                    final indexController = Get.isRegistered<IndexController>()
                        ? Get.find<IndexController>()
                        : Get.put<IndexController>(IndexController(),
                            permanent: true);

                    indexController.startNewGame(); // state’i sıfırla
                    Get.offNamed('/game'); // oyuna geç
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Oyuna Başla'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Get.toNamed('/settings'),
                  icon: const Icon(Icons.settings),
                  label: const Text('Ayarlar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
