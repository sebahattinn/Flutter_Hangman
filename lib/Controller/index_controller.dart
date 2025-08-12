import 'dart:math';

class IndexController {
  // Sadece şu karakterlere izin ver: Türkçe büyük harfler + boşluk
  static final RegExp _allowedPattern =
      RegExp(r'^[ABCÇDEFGĞHIİJKLMNOÖPRSŞTUÜVYZ ]+$');

  /// Dışarıdan gelen film listesini filtreler ve Başlığı sadece izinli karakterlerden oluşanları döner.
  static List<dynamic> _filterMoviesByTitle(List<dynamic> movies) {
    return movies.where((movie) {
      final rawTitle = (movie['title'] ?? '').toString().trim();
      if (rawTitle.isEmpty) return false;

      // Küçük harf gelse bile kabul etmek için büyük harfe çeviriyoruz
      final title = rawTitle.toUpperCase();
      return _allowedPattern.hasMatch(title);
    }).toList();
  }

  /// Filmler listesinden rastgele bir tanesini döndürür (filtreli)
  static Map<String, dynamic> getRandomMovie(List<dynamic> movies) {
    if (movies.isEmpty) {
      throw Exception("Film listesi boş");
    }

    final filtered = _filterMoviesByTitle(movies);

    if (filtered.isEmpty) {
      throw Exception("Filtreye uygun film bulunamadı");
    }

    final random = Random();
    final index = random.nextInt(filtered.length);
    final picked = filtered[index];

    print("Rastgele seçilen film: ${picked['title']}");
    return picked as Map<String, dynamic>;
  }
}
