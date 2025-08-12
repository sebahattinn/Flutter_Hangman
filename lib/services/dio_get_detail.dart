import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Tek bir Dio örneği (timeout’lu)
final Dio _dio = Dio(BaseOptions(
  baseUrl: 'https://api.themoviedb.org/3',
  connectTimeout: const Duration(seconds: 8),
  receiveTimeout: const Duration(seconds: 12),
));

/// TMDB’den film detayını çeker.
Future<Map<String, dynamic>> fetchMovieDetail(int movieId) async {
  final apiKey = dotenv.env['TMDB_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('TMDB_API_KEY .env içinde bulunamadı.');
  }

  try {
    final res = await _dio.get(
      '/movie/$movieId',
      queryParameters: {'api_key': apiKey, 'language': 'tr-TR'},
    );
    if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
      return res.data as Map<String, dynamic>;
    }
    throw Exception('Geçersiz yanıt: ${res.statusCode}');
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    final msg = e.response?.data is Map
        ? (e.response?.data['status_message'] ?? e.message)
        : e.message;
    throw Exception('Film detayı alınamadı (HTTP $code): $msg');
  } catch (e) {
    throw Exception('Film detayı alınamadı: $e');
  }
}

/// İpucu için okunur alanlar üretir.
Map<String, String> buildHintFields(Map<String, dynamic> detail) {
  final genres = (detail['genres'] as List<dynamic>?)
          ?.map((e) => e is Map ? e['name'] : null)
          .whereType<String>()
          .join(', ') ??
      '—';

  return {
    'title': (detail['title'] ?? detail['name'] ?? '—').toString(),
    'overview': (detail['overview'] ?? 'Özet bulunamadı.').toString(),
    'release_date': (detail['release_date'] ?? '—').toString(),
    'genres': genres,
    'vote_count': (detail['vote_count']?.toString() ?? '—'),
    'popularity': (detail['popularity']?.toString() ?? '—'),
  };
}
