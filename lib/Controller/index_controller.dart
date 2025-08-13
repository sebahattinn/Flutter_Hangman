import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'settings_controller.dart';
import '../services/dio_get_movie.dart';
import '../services/dio_get_detail.dart';

class IndexController extends GetxController {
  late SettingsController settings;

  // --- Oyun durumu ---
  final RxString _currentWord = 'ASLAN KRAL'.obs; // TR harf + boşluk (temizlenmiş)
  final RxSet<String> guessed = <String>{}.obs;   // Sadece Türkçe büyük harfler
  final RxInt lives = 5.obs;
  final RxBool isGameOver = false.obs;
  final RxBool isWin = false.obs;

  // --- TMDB / ipucu durumu ---
  final RxList<Map<String, dynamic>> _movies = <Map<String, dynamic>>[].obs;
  final RxnInt _currentMovieId = RxnInt();
  final RxMap<String, String> hint = <String, String>{}.obs;

  // --- Anti-repeat deste (deck) ---
  final Random _rnd = Random();
  List<int> _deck = [];   // _movies içindeki index’lerin karıştırılmış hali
  int _deckPos = 0;       // sıradaki kartın pozisyonu

  // --- Getter'lar ---
  String get currentWord => _currentWord.value;

  /// Ekranda görünen maske (bilinmeyen harfler “_”)
  String get maskedWord => _currentWord.value
      .split('')
      .map((ch) => ch == ' ' ? ' ' : (guessed.contains(ch) ? ch : '_'))
      .join(' ');

  /// Yanlış tahminler
  List<String> get wrongLetters =>
      guessed.where((g) => g.length == 1 && !_currentWord.value.contains(g)).toList();

  /// Doğru tahminler
  List<String> get correctLetters =>
      guessed.where((g) => _currentWord.value.contains(g)).toList();

  /// Kalan açılmamış harf sayısı
  int get remainingLettersCount =>
      _currentWord.value.split('').where((ch) => ch != ' ' && !guessed.contains(ch)).length;

  @override
  void onInit() {
    settings = Get.find<SettingsController>();
    super.onInit();
    _bootstrap();
  }

  /// Uygulama açılışında film listesini yükle ve oyunu başlat
  Future<void> _bootstrap() async {
    try {
      await _loadMoviesIfNeeded();
      _rebuildDeck(); // liste geldikten sonra deste hazırla
      startNewGame(); // her turda rastgele bir film başlığı (desteden)
    } catch (e) {
      Get.snackbar('TMDB', 'Film listesi alınamadı: $e');
      startNewGame(word: 'ASLAN KRAL'); // yedek
    }
  }

  /// Filmleri TMDB'den çek, ayıklayıp (_movies) içine koy
  Future<void> _loadMoviesIfNeeded() async {
    if (_movies.isNotEmpty) return;

    final p1 = await fetchPopularMovies(page: 1);
    final p2 = await fetchPopularMovies(page: 2);

    final filtered = <Map<String, dynamic>>[];
    for (final m in [...p1, ...p2]) {
      final rawTitle = (m['title'] ?? '').toString();
      final cleaned = settings.cleanTitleTr(rawTitle); // TR-upper + temizlik
      if (settings.isTitleAllowed(cleaned)) {
        filtered.add({'id': m['id'], 'title': rawTitle, 'cleaned': cleaned});
      }
    }

    _movies.assignAll(filtered);
  }

  /// Karıştırılmış deste oluştur
  void _rebuildDeck() {
    _deck = List<int>.generate(_movies.length, (i) => i)..shuffle(_rnd);
    _deckPos = 0;
  }

  /// Desteden bir sonraki uygun filmi seç (kurallara uymayanları atlar)
  Map<String, dynamic>? _pickNextMovie() {
    if (_movies.isEmpty) return null;
    if (_deck.isEmpty) _rebuildDeck();

    final int n = _deck.length;
    // Tüm desteyi dolaşmayı dene
    for (int step = 0; step < n; step++) {
      final idx = _deck[_deckPos];
      _deckPos = (_deckPos + 1) % n;

      final m = _movies[idx];
      final cleaned = (m['cleaned'] ?? '') as String;

      // Kurallara uygun mu?
      if (!settings.isTitleAllowed(cleaned)) continue;

      // Bir önceki kelimeyle aynı olmasın
      if (cleaned == _currentWord.value) continue;

      return m;
    }

    // Hiç uygun bulunamadıysa: desteyi yenile ve tek şans daha ver
    _rebuildDeck();
    for (int step = 0; step < _deck.length; step++) {
      final idx = _deck[_deckPos];
      _deckPos = (_deckPos + 1) % _deck.length;

      final m = _movies[idx];
      final cleaned = (m['cleaned'] ?? '') as String;
      if (!settings.isTitleAllowed(cleaned)) continue;
      if (cleaned == _currentWord.value) continue;
      return m;
    }

    // Hâlâ yoksa pes: null dön
    return null;
  }

  /// Yeni tur başlat. (word verilirse onu, verilmezse desteden seç)
  void startNewGame({String? word}) {
    hint.clear();

    if (word == null) {
      if (_movies.isEmpty) {
        _currentWord.value = 'ASLAN KRAL';
        _currentMovieId.value = null;
      } else {
        final next = _pickNextMovie();
        if (next != null) {
          _currentMovieId.value = next['id'] as int?;
          _currentWord.value = (next['cleaned'] ?? '') as String;
        } else {
          // son çare
          _currentWord.value = 'ASLAN KRAL';
          _currentMovieId.value = null;
        }
      }
    } else {
      final cleaned = settings.cleanTitleTr(word);
      _currentWord.value = settings.isTitleAllowed(cleaned) ? cleaned : 'ASLAN KRAL';
      _currentMovieId.value = null;
    }

    // Tahminler ve canlar sıfırlanır
    guessed.clear();
    lives.value = settings.livesPerRound.value; // <- RxInt .value
    isGameOver.value = false;
    isWin.value = false;
  }

  /// Oyunu sıfırla (yeni tur)
  void resetGame() => startNewGame();

  /// Tur bitişini yönetir (kazandı/kaybetti)
  void _endRound({required bool win, String? loseReason}) {
    if (isGameOver.value) return;
    isGameOver.value = true;
    isWin.value = win;

    if (win) {
      Get.snackbar('Kazandın!', 'Harika iş 🎉');
    } else {
      final reason = loseReason ?? 'Kelime: ${_currentWord.value}';
      Get.snackbar('Kaybettin', reason);
    }
  }

  /// Harf tahmini yap
  void guess(String input) {
    if (isGameOver.value || input.isEmpty) return;

    // Girilen ilk karakteri TR-Upper yap
    final ch = settings.upperChar(input[0]);

    // İzinli karakter mi? (A-Z, Ç, Ğ, İ, Ö, Ş, Ü)
    if (!settings.isAllowedChar(ch)) return;

    // Aynı harf daha önce tahmin edildiyse geç
    if (guessed.contains(ch)) return;

    guessed.add(ch);

    // Yanlış tahmin ise can azalt
    if (!_currentWord.value.contains(ch)) {
      lives.value = lives.value - 1;
      if (lives.value <= 0) _endRound(win: false);
      return;
    }

    // Doğru tahmin: tüm harfler açıldı mı?
    final allRevealed =
        _currentWord.value.split('').every((c) => c == ' ' || guessed.contains(c));
    if (allRevealed) _endRound(win: true);
  }

  /// TMDB'den ipucu göster (açıklama, tür, süre, oy sayısı vs.)
  Future<void> showHint() async {
    if (_currentMovieId.value == null) {
      Get.snackbar('İpucu', 'Bu tur için film bağlantısı yok.');
      return;
    }
    try {
      final detail = await fetchMovieDetail(_currentMovieId.value!);
      hint.assignAll(buildHintFields(detail));
      Get.bottomSheet(
        _HintSheet(hint: hint),
        isScrollControlled: true,
        backgroundColor: Get.theme.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      );
    } catch (e) {
      Get.snackbar('İpucu', 'Detay alınamadı: $e');
    }
  }
}

/// TMDB ipucu alt tabakası
class _HintSheet extends StatelessWidget {
  const _HintSheet({required this.hint});
  final Map<String, String> hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hint['title'] ?? '—', style: t.titleLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _chip('Tür', hint['genres']),
                _chip('Çıkış', hint['release_date']),
                _chip('TMDB', hint['vote_average']),
                _chip('Oy', hint['vote_count']),
                _chip('Popülerlik', hint['popularity']),
                _chip('Hasılat', hint['revenue']),
                _chip(
                  'Süre',
                  (hint['runtime'] != null && hint['runtime']!.isNotEmpty)
                      ? '${hint['runtime']} dk'
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(hint['overview'] ?? '—', style: t.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final v = (value == null || value.isEmpty) ? '—' : value;
    return Chip(label: Text('$label: $v'));
  }
}
