import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';

Future<List<dynamic>> fetchMovies() async {
  final apiKey = dotenv.env['TMDB_API_KEY'];
  final url =
      'https://api.themoviedb.org/3/movie/popular?api_key=$apiKey&language=tr-TR&page=1';

  try {
    final response = await Dio().get(url);
    return response.data['results']; // Film listesi
  } catch (e) {
    throw Exception('Filmler alınamadı: $e');
  }
}
