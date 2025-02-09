import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RapidApiService {
  var baseUrl = dotenv.env['BASE_URL'] ?? '';

  final Dio _dio = Dio();

  RapidApiService() {
    // Set the base URL
    _dio.options.baseUrl = baseUrl;

    // Load the API key from the .env file
    final String apiKey = dotenv.env['RAPID_API_KEY'] ?? '';

    // Set headers
    _dio.options.headers = {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
      'Content-Type': 'application/json',
    };
  }

  // Fetch workout data
  Future<dynamic> getTargetWorkoutData(
      String target, Map<String, dynamic> queryParams) async {
    try {
      final response = await _dio.get(
        '$baseUrl/exercises/target/$target',
        queryParameters: queryParams,
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch workout data: $e');
    }
  }
}
