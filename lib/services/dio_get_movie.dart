import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final Dio _dio = Dio(BaseOptions(
  baseUrl: 'https://api.themoviedb.org/3',
  connectTimeout: Duration(seconds: 8),
  receiveTimeout: Duration(seconds: 12),
));

final _onlyTrLetters = RegExp(r'^[A-Za-zÇĞİÖŞÜçğıöşü ]+$'); // harf + boşluk
final _hasDigit = RegExp(r'\d');
// popüler filmleri alırken sayfa numarası varsayılan 1
Future<List<Map<String, dynamic>>> fetchPopularMovies({int page = 1}) async {
  final key = dotenv.env['TMDB_API_KEY'];
  if (key == null || key.isEmpty) throw Exception('TMDB_API_KEY yok.');

  final r = await _dio.get('/movie/popular', queryParameters: {
    'api_key': key,
    'language': 'tr-TR',
    'page': page,
  });

  return ((r.data?['results'] as List?) ?? [])
      .whereType<Map>()
      .where((e) {
        final t = (e['title'] ?? '').toString().trim();
        return e['id'] != null &&
            t.isNotEmpty &&
            !_hasDigit.hasMatch(t) &&
            _onlyTrLetters.hasMatch(t);
      })
      .map((e) => {'id': e['id'], 'title': e['title']})
      .toList();
}
