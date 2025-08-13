import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Controller/index_controller.dart';
import '../Controller/settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SettingsController settings;
  late final IndexController game;

  // Yerel geçici değer: UI üzerinde oynarız, kaydederken Settings'e yazarız
  late int _livesTemp;

  @override
void initState() {
  super.initState();
  settings = Get.find<SettingsController>();
  game = Get.find<IndexController>();

  // Settings'teki mevcut hak sayısıyla başlat (RxInt → .value)
  _livesTemp = settings.livesPerRound.value;
}

void _applyAndStartNewRound() {
  // Değeri ayarlara yaz (RxInt → .value) ya da setter fonksiyonunu kullan
  settings.livesPerRound.value = _livesTemp;
  // alternatif: settings.setLivesPerRound(_livesTemp);

  // Yeni turu başlat ve oyuna dön
  game.startNewGame();
  Get.offAllNamed('/game');
}

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Oyun', style: t.textTheme.titleLarge),

          const SizedBox(height: 12),
          Text(
            'Tur başına can (hak) sayısı: $_livesTemp',
            style: t.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          // Hak sayısı slider
          Slider(
            value: _livesTemp.toDouble(),
            min: 3,
            max: 10,
            divisions: 7,
            label: '$_livesTemp',
            onChanged: (v) => setState(() => _livesTemp = v.round()),
          ),

          // Hızlı preset düğmeleri
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [3, 4, 5, 6, 7, 8, 9, 10].map((n) {
              final selected = _livesTemp == n;
              return ChoiceChip(
                label: Text('$n'),
                selected: selected,
                onSelected: (_) => setState(() => _livesTemp = n),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),
          Text(
            'Not: Buradaki hak sayısı yeni tur başladığında uygulanır.',
            style: t.textTheme.bodySmall,
          ),

          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: _applyAndStartNewRound,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Kaydet ve Yeni Oyun Başlat'),
          ),

          const SizedBox(height: 12),
         
        

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // İsteğe bağlı: Uygulama hakkında kısa açıklama
          Text('Hakkında', style: t.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Adam Asmaca – Film başlıklarıyla oynanan Türkçe destekli bir kelime oyunu. '
            'Kelimeler bölünmeden satır sonlarında düzgünce hizalanır, ipucu için ampul simgesine dokunabilirsin.',
            style: t.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
