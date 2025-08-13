import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  // ---- TMDB ayarları ----
  final language = 'tr-TR'.obs;
  final includeAdult = false.obs;
  final minVoteCount = 0.obs;

  Map<String, dynamic> tmdbParams({required String apiKey, int page = 1}) => {
        'api_key': apiKey,
        'language': language.value,
        'page': page,
        'include_adult': includeAdult.value,
        'vote_count.gte': minVoteCount.value,
      };

  // ---- Başlık filtreleri ----
  final excludeDigits = true.obs; // sayı varsa ele
  final onlyTrLetters = true.obs; // sadece TR harf + boşluk
  final _reDigit = RegExp(r'\d');
  final _reTr = RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşüxw ]+$');

  /// Başlığı TR-upper yapar, yalnız TR harf + boşluk bırakır, fazla boşlukları tekler.
  String cleanTitleTr(String s) {
    final up = turkishUpper(s);
    final kept =
        up.split('').where((c) => RegExp(r'[A-ZÇĞİÖŞÜXW ]').hasMatch(c)).join();
    return kept.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Başlık kurallarına uygun mu?
  bool isTitleAllowed(String? title) {
    final t = (title ?? '').trim();
    if (t.isEmpty) return false;
    if (excludeDigits.value && _reDigit.hasMatch(t)) return false;
    if (onlyTrLetters.value && !_reTr.hasMatch(t)) return false;
    return RegExp(r'[A-ZÇĞİÖŞÜXW]').hasMatch(t); // en az bir harf olsun
  }

  // ---- Oyun ayarları (timer ve difficulty kaldırıldı) ----
  /// Tur başına can (hak) sayısı. Ayarlardan değiştirilebilir.
  final livesPerRound = 5.obs;

  void setLivesPerRound(int v) {
    // 1–20 aralığına sıkıştır
    if (v < 1) v = 1;
    if (v > 20) v = 20;
    livesPerRound.value = v;
  }

  // ---- Alfabe / karakter yardımcıları ----
  static const _alphabet = <String>{
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
    'W'
  };

  bool isAllowedChar(String ch) => _alphabet.contains(ch);
  String upperChar(String ch) => turkishUpper(ch).characters.first;

  /// TR farkındalıklı uppercase
  String turkishUpper(String s) => s
      .replaceAll('i', 'İ')
      .replaceAll('ı', 'I')
      .replaceAll('ş', 'Ş')
      .replaceAll('ğ', 'Ğ')
      .replaceAll('ü', 'Ü')
      .replaceAll('ö', 'Ö')
      .replaceAll('ç', 'Ç')
      .toUpperCase();

  // ---- Kısa yardımcılar ----
  void toggleAdult() => includeAdult.value = !includeAdult.value;
  void toggleExcludeDigits() => excludeDigits.value = !excludeDigits.value;
  void toggleOnlyTr() => onlyTrLetters.value = !onlyTrLetters.value;
  void setLanguage(String code) => language.value = code;
  void setMinVoteCount(int v) => minVoteCount.value = v < 0 ? 0 : v;
}
