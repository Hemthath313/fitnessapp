import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RapidApiService {
  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  final Dio _dio = Dio();

  RapidApiService() {
    // Set the base URL
    _dio.options.baseUrl = baseUrl;

    // Load the API key from the .env file
    // final String apiKey = dotenv.env['RAPID_API_KEY'] ?? '';

    // Set headers
    // var  headers = {
    //   'Accept': 'application/json', // Accept application/json
    //   'x-rapidapi-ua': 'RapidAPI-Playground', // Specific user-agent
    //   'x-rapidapi-key':
    //       '96f9f9b281msh5f7342cfec7494cp1d057bjsneb0702906f5c', // Your RapidAPI key
    //   'x-rapidapi-host': 'exercisedb.p.rapidapi.com', // RapidAPI host
    // };
  }

  // Fetch workout data
  Future<dynamic> getTargetWorkoutData(
      String target, Map<String, dynamic> queryParams) async {
    try {
      var headers = {
        'Accept': 'application/json', // Accept application/json
        'x-rapidapi-ua': 'RapidAPI-Playground', // Specific user-agent
        'x-rapidapi-key':
            '96f9f9b281msh5f7342cfec7494cp1d057bjsneb0702906f5c', // Your RapidAPI key
        'x-rapidapi-host': 'exercisedb.p.rapidapi.com', // RapidAPI host
      };
      queryParams['limit'] = 30;

      final response = await _dio.get(
        '/exercises/target/$target',
        queryParameters: queryParams,
        options: Options(
          headers: {
            ..._dio.options.headers,
            ...headers,
          },
        ),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch workout data: $e');
    }
  }

  Future<dynamic> getBodyPartsWorkoutData(
      String bodyPart, Map<String, dynamic> queryParams) async {
    try {
      var headers = {
        'Accept': 'application/json', // Accept application/json
        'x-rapidapi-ua': 'RapidAPI-Playground', // Specific user-agent
        'x-rapidapi-key':
            '96f9f9b281msh5f7342cfec7494cp1d057bjsneb0702906f5c', // Your RapidAPI key
        'x-rapidapi-host': 'exercisedb.p.rapidapi.com', // RapidAPI host
      };
      queryParams['limit'] = 20;
      final response = await _dio.get(
        '/exercises/bodyPart/$bodyPart',
        queryParameters: queryParams,
        options: Options(
          headers: {
            ..._dio.options.headers,
            ...headers,
          },
        ),
      );
      return response.data;
    } catch (e) {
      throw Exception('Failed to fetch workout data: $e');
    }
  }
}
