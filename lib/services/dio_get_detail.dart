import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final Dio _dio = Dio(BaseOptions(
  baseUrl: 'https://api.themoviedb.org/3',
  connectTimeout: const Duration(seconds: 8),
  receiveTimeout: const Duration(seconds: 12),
));

Future<Map<String, dynamic>> fetchMovieDetail(int movieId) async {
  final apiKey = dotenv.env['TMDB_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    throw Exception('TMDB_API_KEY .env içinde bulunamadı.');
  }

  final res = await _dio.get(
    '/movie/$movieId',
    queryParameters: {'api_key': apiKey, 'language': 'tr-TR'},
  );
  if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
    return res.data as Map<String, dynamic>;
  }
  throw Exception('Geçersiz yanıt: ${res.statusCode}');
}
       //ipucu detaylarını oluştur, genre bilgilerini düzenli bir şekilde al
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
    'vote_average': (detail['vote_average']?.toString() ?? '—'),
    'vote_count': (detail['vote_count']?.toString() ?? '—'),
    'popularity': (detail['popularity']?.toString() ?? '—'),
    'revenue': (detail['revenue']?.toString() ?? '—'),
    'runtime': (detail['runtime']?.toString() ?? '—'),
  };
}
