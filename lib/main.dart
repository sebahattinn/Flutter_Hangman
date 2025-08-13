import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

// CONTROLLER'lar — tek ve tutarlı yol
import 'package:hangman/Controller/usecase_controller.dart';
import 'package:hangman/Controller/settings_controller.dart';
import 'package:hangman/Controller/index_controller.dart';

// EKRANLAR
import 'package:hangman/screens/index.dart';
import 'package:hangman/screens/game_index.dart';
import 'package:hangman/screens/settings_screen.dart';
import 'package:hangman/screens/exist_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // .env yükleniyor
  runApp(MyApp());
}

class AppBindings extends Bindings {
  @override
  void dependencies() {
    Get.put(SettingsController(), permanent: true); // 1
    Get.put<UsecaseController>(UsecaseController(), permanent: true); // 2
    Get.put<IndexController>(IndexController(), permanent: true); // 3
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Adam Asmaca',
      debugShowCheckedModeBanner: false,
      initialBinding: AppBindings(),
      initialRoute: '/', // Uygulama hoş geldin ile başlar
      getPages: [
        // Hoş geldin
        GetPage(
          name: '/',
          page: () => const WelcomeScreen(),
          transition: Transition.fadeIn,
        ),
        // Oyun ekranı
        GetPage(
          name: '/game',
          page: () => const GameIndex(),
          transition: Transition.rightToLeft,
        ),
        // Ayarlar
        GetPage(
          name: '/settings',
          page: () => SettingsScreen(),
          transition: Transition.downToUp,
        ),
        // Çıkış
        GetPage(
          name:
              '/exist', // Projende 'exist_screen.dart' kullandığın için rota adını korudum
          page: () => const ExistScreen(),
          transition: Transition.cupertino,
        ),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepOrange,
      ),
    );
  }
}
