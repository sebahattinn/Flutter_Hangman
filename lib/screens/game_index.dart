import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:hangman/Controller/index_controller.dart';
import 'package:hangman/services/dio_get_movie.dart';
import 'package:hangman/services/dio_get_detail.dart';
import 'package:hangman/Controller/settings_controller.dart';

class GameIndex extends StatefulWidget {
  final String word;
  final int movieId;
  final int currentRound;
  final int totalRounds;
  final int totalScore;

  const GameIndex({
    super.key,
    required this.word,
    required this.movieId,
    required this.currentRound,
    required this.totalRounds,
    required this.totalScore,
  });

  @override
  State<GameIndex> createState() => _GameIndexState();
}

class _GameIndexState extends State<GameIndex> {
  final List<String> alphabet = 'ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ'.split('');
  late final Set<String> allowed = Set.of(alphabet);

  final Set<String> dogru = {};
  final Set<String> yanlis = {};

  late int hak;
  late GameMode mode;
  late Difficulty difficulty;

  int totalScore = 0;
  bool _finished = false;

  Timer? _timer;
  int secondsLeft = 0;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>();

    mode = s.mode;
    difficulty = s.difficulty;
    hak = s.initialLives;
    totalScore = widget.totalScore;

    if (mode == GameMode.timed) {
      secondsLeft = s.roundSeconds;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _isWin(String u) {
    for (final ch in u.split('')) {
      if (ch == ' ') continue;
      if (allowed.contains(ch) && !dogru.contains(ch)) return false;
    }
    return true;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return;
      setState(() => secondsLeft--);
      if (secondsLeft <= 0) {
        t.cancel();
        await _endRound(win: false);
      }
    });
  }

  Future<void> _showCorrectAnswer() async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bilemediniz, Doğru Cevap:"),
        content: Text(widget.word),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  Future<void> _showFinalCongratsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Tebrikler!"),
        content: Text(
          "Tüm turları başarıyla tamamladınız.\nToplam Puanınız: $totalScore",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).popUntil((r) => r.isFirst),
            child: const Text("Ana Menüye Dön"),
          ),
        ],
      ),
    );
  }

  Future<void> _endRound({required bool win}) async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    final isClassic =
        context.read<SettingsController>().mode == GameMode.classic;
    final isLastRound = widget.currentRound >= widget.totalRounds;

    // Son tur + kazandı → sadece final tebrik
    if (isClassic && isLastRound && win) {
      _dialogOpen = false;
      await _showFinalCongratsDialog();
      return;
    }

    // Normal round popup (son turda kaybediyorsa metni de ona göre)
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        title: Text(win ? "Tebrikler!" : "Bilemediniz"),
        content: Text(
          win
              ? "Filmi bildiniz. Bonus +20 eklendi."
              : (isClassic && isLastRound
                  ? "Kaybettiniz! Oyun sona erdi."
                  : "Filmi bilemediniz! Yeni tura geçiliyor."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );

    _dialogOpen = false;
    if (!mounted) return;

    // Son tur + kaybetti → ana menüye dön (final pop yok)
    if (isClassic && isLastRound && !win) {
      Navigator.of(context).popUntil((r) => r.isFirst);
      return;
    }

    // Ara turlarda devam
    await _nextGame();
  }

  Future<void> _nextGame() async {
    _timer?.cancel();
    final movies = await fetchMovies();
    final rnd = IndexController.getRandomMovie(movies);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameIndex(
          word: rnd['title'],
          movieId: rnd['id'],
          currentRound: widget.currentRound + 1,
          totalRounds: widget.totalRounds,
          totalScore: totalScore,
        ),
      ),
    );
  }

  Future<void> _showHint() async {
    if (_dialogOpen || !mounted) return;
    _dialogOpen = true;

    try {
      final d = await fetchMovieDetail(widget.movieId);
      final h = buildHintFields(d);

      final text = '''
Tür: ${h['genres']}
Çıkış: ${h['release_date']}
Oy Sayısı: ${h['vote_count']}
Popülarite: ${h['popularity']}

Özet:
${h['overview']}
''';

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("İpucu"),
          content: SingleChildScrollView(child: Text(text)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("İpucu Hatası"),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        ),
      );
    } finally {
      _dialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wordU = widget.word.toUpperCase();
    final hidden = wordU
        .split('')
        .map((c) => c == ' ' ? ' ' : (dogru.contains(c) ? c : '_'))
        .join(' ');

    final s = context.watch<SettingsController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text(
                      "Oyundan Çık",
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Tur: ${widget.currentRound}${s.mode == GameMode.classic ? '/${widget.totalRounds}' : ''}",
                      ),
                      const SizedBox(width: 12),
                      Text("Hak: $hak"),
                      if (mode == GameMode.timed) ...[
                        const SizedBox(width: 12),
                        Text("Süre: $secondsLeft"),
                      ],
                      const SizedBox(width: 12),
                      Text("Puan: $totalScore"),
                    ],
                  ),
                ],
              ),
            ),

            // İpucu
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextButton(
                  onPressed: _showHint,
                  child: const Text(
                    "İpucu",
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ),

            // Görsel (asset)
            Container(
              width: 180,
              height: 200,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/cop_adam.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Kelime
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                hidden,
                style: const TextStyle(fontSize: 28, letterSpacing: 2),
              ),
            ),

            // Alfabe – Expanded ile overflow olmaz
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: alphabet.length,
                  itemBuilder: (_, i) {
                    final letter = alphabet[i];
                    final used =
                        dogru.contains(letter) || yanlis.contains(letter);

                    return GestureDetector(
                      onTap: used || hak <= 0 || _finished
                          ? null
                          : () => _onLetter(letter, wordU),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: used ? Colors.grey : Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          Text(letter,
                              style: const TextStyle(color: Colors.white)),
                          if (yanlis.contains(letter))
                            CustomPaint(
                              size: const Size(40, 40),
                              painter: _CrossLinePainter(),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onLetter(String letter, String wordU) async {
    if (_finished) return;

    final isHit = wordU.contains(letter);

    setState(() {
      if (isHit) {
        if (!dogru.contains(letter)) {
          // Harf kelimede kaç kez geçiyor? → o kadar × 5 puan
          final occurrences = wordU.split('').where((c) => c == letter).length;
          totalScore += occurrences * 5;
        }
        dogru.add(letter);
      } else {
        yanlis.add(letter);
        hak = (hak - 1).clamp(0, 999);
      }
    });

    // Kelime tamamlanırsa: bonus +20 (anında)
    if (isHit && _isWin(wordU)) {
      if (_finished) return;
      _finished = true;
      setState(() => totalScore += 20);
      await _endRound(win: true);
      return;
    }

    // Haklar bitti (timed hariç): önce doğru cevap, sonra kaybet diyalogu
    if (!isHit && hak == 0) {
      _finished = true;
      if (mode != GameMode.timed) {
        await _showCorrectAnswer();
      }
      await _endRound(win: false);
      return;
    }
  }
}

class _CrossLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), p)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(_) => false;
}
