import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExistScreen extends StatelessWidget {
  const ExistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Exit Game')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Oyundan çıkmak istediğinize emin misiniz?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
             const SizedBox(height: 8),
            FilledButton(
              onPressed: () => Get.back(),
              child: const Text('Oyuna Devam Et'),
            ),
            TextButton(
              onPressed: () => Get.offAllNamed('/'),
              child: const Text('Ana Menüye Dön'),
            ),
           
          ],
        ),
      ),
    );
  }
}
