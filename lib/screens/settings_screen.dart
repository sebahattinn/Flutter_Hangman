import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hangman/Controller/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Ayarlar")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Oyun Modu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildModeSelector(controller),
            const SizedBox(height: 24),
            const Text("Zorluk",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDifficultySelector(controller),
            if (controller.mode == GameMode.classic) ...[
              const SizedBox(height: 24),
              const Text("Tur Sayısı",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildRoundsSelector(controller),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: controller.resetDefaults,
                  child: const Text("Sıfırla"),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // değerler zaten controller’da kaydedildi
                    Navigator.pop(context);
                  },
                  child: const Text("Kaydet ve Geri Dön"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
   //mode seçen widget
  Widget _buildModeSelector(SettingsController c) {
    final labels = {
      GameMode.classic: 'classic',
      GameMode.endless: 'endless',
      GameMode.timed: 'timed',
    };
    return Wrap(
      spacing: 12,
      children: GameMode.values.map((mode) {
        return ChoiceChip(
          label: Text(labels[mode]!),
          selected: c.mode == mode,
          onSelected: (_) => c.setMode(mode),
        );
      }).toList(),
    );
  }
 //zorluk seviyesini seçen widget
  Widget _buildDifficultySelector(SettingsController c) {
    final labels = {
      Difficulty.easy: 'easy',
      Difficulty.normal: 'normal',
      Difficulty.hard: 'hard',
    };
    return Wrap(
      spacing: 12,
      children: Difficulty.values.map((diff) {
        return ChoiceChip(
          label: Text(labels[diff]!),
          selected: c.difficulty == diff,
          onSelected: (_) => c.setDifficulty(diff),
        );
      }).toList(),
    );
  }
 // kaç tur oynayacağını seçen widget
  Widget _buildRoundsSelector(SettingsController c) {
    return Slider(
      value: c.rounds.toDouble(),
      min: 1,
      max: 20,
      divisions: 19,
      label: "${c.rounds}",
      onChanged: (val) => c.setRounds(val.toInt()),
    );
  }
}
