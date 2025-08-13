import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../Controller/index_controller.dart';
import '../widgets/hangman_figure.dart';

class GameIndex extends StatefulWidget {
  const GameIndex({super.key});

  @override
  State<GameIndex> createState() => _GameIndexState();
}

class _GameIndexState extends State<GameIndex> {
  late final IndexController controller;
  Worker? _gameOverWorker;

  // Dialog'un üst üste açılmasını engelleyen bayrak
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
    controller = Get.find<IndexController>();

    // Oyun bitti mi dinle, popup göster
    _gameOverWorker = ever<bool>(controller.isGameOver, (over) {
      if (over && !_dialogShown) {
        _dialogShown = true;
        _showEndDialog(win: controller.isWin.value).whenComplete(() {
          // dialog gerçekten kapanınca yeniden açılabilir hale getir
          _dialogShown = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _gameOverWorker?.dispose();
    super.dispose();
  }

  Future<void> _showEndDialog({required bool win}) {
    Get.closeAllSnackbars();
    final title = win ? 'Kazandın 🎉' : 'Kaybettin 😔';
    final desc = win
        ? 'Harika iş! Yeni bir kelimeyle devam etmek ister misin?'
        : 'Üzülme, bir sonraki kelimede şansın açık!';

    return Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(desc),
        actions: [
          // Ana menü
          TextButton(
            onPressed: () {
              Get.back(); // önce dialogu kapat
              Future.microtask(() => Get.offAllNamed('/')); // sonra yönlen
            },
            child: const Text('Ana Menü'),
          ),

          // Yeni oyun
          FilledButton.icon(
            onPressed: () {
              Get.back(); // önce dialogu kapat
              // dialog tamamen kapandıktan sonra yeni tur başlat

              Future.microtask(() => controller.startNewGame());
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Yeni Oyun'),
          ),
        ],
      ),
      barrierDismissible: false, // dışarı tıklayınca kapanmasın
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text('Adam Asmaca (GetX ile birlikte)'),
  actions: [
    PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'hint':
            controller.showHint();
            break;
          case 'refresh':
            Get.offAllNamed('/'); // index.dart route
            break;
          case 'exit':
            Get.toNamed('/exist');
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem(
          value: 'hint',
          child: Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 8),
              Text('İpucu Göster'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh, color: Colors.blue),
              SizedBox(width: 8),
              Text('Ana Ekrana Dön'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'exit',
          child: Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.red),
              SizedBox(width: 8),
              Text('Oyundan Çık'),
            ],
          ),
        ),
      ],
    ),
  ],
      ),
    
      body: SafeArea(
        child: Obx(() {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Kalan Hak: ${controller.lives.value}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      controller.isGameOver.value
                          ? (controller.isWin.value ? 'Kazandın' : 'Kaybettin')
                          : '',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: controller.isWin.value
                                ? Colors.green
                                : (controller.isGameOver.value
                                    ? Colors.red
                                    : null),
                          ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Column(
                    children: [
                      HangmanFigure(
                        wrongCount: controller.wrongLetters.length,
                        maxSteps: controller.wrongLetters.length +
                            controller.lives.value, // 🔹 toplam hak
                        width: 260,
                        height: 220,
                      ),
                      const SizedBox(height: 12),
                      _MaskedWordGrouped(
                        word: controller.currentWord,
                        guessed: controller.guessed,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ===================== KLAVYE =====================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Obx(() {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _trKeys.map((ch) {
                      final isGuessed = controller.guessed.contains(ch);
                      final isWrong = controller.wrongLetters.contains(ch);
                      final disabled = isGuessed || controller.isGameOver.value;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 44,
                            height: 40,
                            child: ElevatedButton(
                              onPressed:
                                  disabled ? null : () => controller.guess(ch),
                              child: Text(ch),
                            ),
                          ),
                          if (isGuessed && isWrong)
                            IgnorePointer(
                              child: CustomPaint(
                                size: const Size(44, 40),
                                painter: _RedCrossPainter(),
                              ),
                            ),
                        ],
                      );
                    }).toList(),
                  );
                }),
              ),
              const SizedBox(height: 42),

              
              const SizedBox(height: 25),
            ],
          );
        }),
      ),
    );
  }
}

/// ===================== KELİMELERİ BLOKLAYAN MASKE =====================
class _MaskedWordGrouped extends StatelessWidget {
  const _MaskedWordGrouped({required this.word, required this.guessed});
  final String word;
  final Set<String> guessed;

  @override
  Widget build(BuildContext context) {
    final words = word.split(' ').where((w) => w.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 30, // kelimeler arası boşluk
        runSpacing: 12, // satırlar arası boşluk
        children: words.map((w) {
          return LayoutBuilder(
            builder: (ctx, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _WordMask(word: w, guessed: guessed),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Tek bir kelimeyi (harf harf) çizen, tek blokluk yapı
class _WordMask extends StatelessWidget {
  const _WordMask({required this.word, required this.guessed});
  final String word;
  final Set<String> guessed;

  @override
  Widget build(BuildContext context) {
    final letters = word.split('');
    final textStyle = Theme.of(context)
        .textTheme
        .headlineSmall
        ?.copyWith(fontWeight: FontWeight.w600);

    const letterSpacing = 8.0;
    const boxWidth = 22.0;
    const boxHeight = 32.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < letters.length; i++) ...[
          SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Center(
              child: Text(
                guessed.contains(letters[i]) ? letters[i] : '_',
                style: textStyle,
              ),
            ),
          ),
          if (i != letters.length - 1) const SizedBox(width: letterSpacing),
        ],
      ],
    );
  }
}

/// Tuşun üstüne kırmızı X çizen painter
class _RedCrossPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.red.withOpacity(0.85)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        const Offset(4, 4), Offset(size.width - 4, size.height - 4), p);
    canvas.drawLine(Offset(size.width - 4, 4), Offset(4, size.height - 4), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Türk alfabesi (29 harf) — büyük (istersen X/W'yi kaldır)
const List<String> _trKeys = [
  'A',
  'B',
  'C',
  'Ç',
  'D',
  'E',
  'F',
  'G',
  'Ğ',
  'H',
  'I',
  'İ',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'Ö',
  'P',
  'R',
  'S',
  'Ş',
  'T',
  'U',
  'Ü',
  'V',
  'Y',
  'Z',
  'X',
  'W',
];
