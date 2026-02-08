import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fitness_app/services/rapid_api_services.dart';

class LocalVideoService {
  final RapidApiService _apiService = RapidApiService();
  
  // Map exercise names to local video file paths
  // This will be populated based on your video file names
  final Map<String, String> _videoMap = {};
  
  // Cache for exercise data
  Map<String, List<dynamic>> _exerciseCache = {};

  LocalVideoService() {
    _initializeVideoMap();
  }

  // Initialize video mapping - maps exercise names to local video files
  void _initializeVideoMap() {
    // Biceps workouts
    _videoMap['barbell curl'] = 'assets/videos/barbell_curl.mp4';
    _videoMap['cable one arm curl'] = 'assets/videos/cable_one_arm_curl.mp4';
    _videoMap['one arm cable curl'] = 'assets/videos/cable_one_arm_curl.mp4';
    _videoMap['cable curl'] = 'assets/videos/cable_one_arm_curl.mp4';
    
    // Chest workouts
    _videoMap['barbell bench press'] = 'assets/videos/barbell_bench_press.mp4';
    _videoMap['bench press'] = 'assets/videos/barbell_bench_press.mp4';
    _videoMap['barbell decline bench press'] = 'assets/videos/barbell_decline_bench_press.mp4';
    _videoMap['decline barbell bench press'] = 'assets/videos/barbell_decline_bench_press.mp4';
    _videoMap['decline bench press'] = 'assets/videos/barbell_decline_bench_press.mp4';
    
    // Abs stretching
    _videoMap['seated twist'] = 'assets/videos/stretching_seated_twist_straight_arm.mp4';
    _videoMap['seated twist straight arm'] = 'assets/videos/stretching_seated_twist_straight_arm.mp4';
    _videoMap['straight arm seated twist'] = 'assets/videos/stretching_seated_twist_straight_arm.mp4';
  }

  // Get video path for an exercise
  String? getVideoPath(String exerciseName) {
    if (exerciseName.isEmpty) return null;
    
    // Normalize exercise name for lookup
    final normalizedName = exerciseName.toLowerCase().trim();
    
    // Try exact match first
    if (_videoMap.containsKey(normalizedName)) {
      return _videoMap[normalizedName];
    }
    
    // Try partial match - check if exercise name contains key words or vice versa
    for (var entry in _videoMap.entries) {
      final key = entry.key.toLowerCase();
      // Check if exercise name contains the key or key contains exercise name
      if (normalizedName.contains(key) || key.contains(normalizedName)) {
        return entry.value;
      }
      
      // Also try matching key words (for multi-word exercises)
      final exerciseWords = normalizedName.split(' ');
      final keyWords = key.split(' ');
      
      // If most words match, consider it a match
      int matchCount = 0;
      for (var word in exerciseWords) {
        if (keyWords.any((kw) => kw.contains(word) || word.contains(kw))) {
          matchCount++;
        }
      }
      // If at least 2 words match or if it's a 2-word exercise and both match
      if (matchCount >= 2 || (exerciseWords.length <= 2 && matchCount == exerciseWords.length)) {
        return entry.value;
      }
    }
    
    // Try fuzzy matching for specific known exercises
    // Barbell curl variations
    if (normalizedName.contains('barbell') && normalizedName.contains('curl')) {
      return 'assets/videos/barbell_curl.mp4';
    }
    
    // Cable curl variations
    if (normalizedName.contains('cable') && normalizedName.contains('curl')) {
      return 'assets/videos/cable_one_arm_curl.mp4';
    }
    
    // Bench press variations
    if (normalizedName.contains('bench press') && !normalizedName.contains('decline')) {
      return 'assets/videos/barbell_bench_press.mp4';
    }
    
    // Decline bench press variations
    if (normalizedName.contains('decline') && normalizedName.contains('bench')) {
      return 'assets/videos/barbell_decline_bench_press.mp4';
    }
    
    // Seated twist / stretching variations
    if ((normalizedName.contains('seated') || normalizedName.contains('twist')) && 
        (normalizedName.contains('stretch') || normalizedName.contains('abs'))) {
      return 'assets/videos/stretching_seated_twist_straight_arm.mp4';
    }
    
    return null; // No match found, will fall back to GIF
  }

  // Fetch exercises from API and enhance with local video paths
  Future<List<dynamic>> getTargetWorkoutData(
      String target, Map<String, dynamic> queryParams) async {
    try {
      // Check cache first
      final cacheKey = 'target_$target';
      if (_exerciseCache.containsKey(cacheKey)) {
        return _enhanceWithVideos(_exerciseCache[cacheKey]!);
      }

      // Fetch from API
      final data = await _apiService.getTargetWorkoutData(target, queryParams);
      
      // Cache the data
      _exerciseCache[cacheKey] = List<dynamic>.from(data);
      
      return _enhanceWithVideos(data);
    } catch (e) {
      throw Exception('Failed to fetch workout data: $e');
    }
  }

  Future<List<dynamic>> getBodyPartsWorkoutData(
      String bodyPart, Map<String, dynamic> queryParams) async {
    try {
      // Check cache first
      final cacheKey = 'bodypart_$bodyPart';
      if (_exerciseCache.containsKey(cacheKey)) {
        return _enhanceWithVideos(_exerciseCache[cacheKey]!);
      }

      // Fetch from API
      final data = await _apiService.getBodyPartsWorkoutData(bodyPart, queryParams);
      
      // Cache the data
      _exerciseCache[cacheKey] = List<dynamic>.from(data);
      
      return _enhanceWithVideos(data);
    } catch (e) {
      throw Exception('Failed to fetch workout data: $e');
    }
  }

  // Enhance exercise data with local video paths
  List<dynamic> _enhanceWithVideos(List<dynamic> exercises) {
    return exercises.map((exercise) {
      final exerciseName = exercise['name']?.toString() ?? '';
      final videoPath = getVideoPath(exerciseName);
      
      return {
        ...exercise,
        'localVideoPath': videoPath,
        'hasLocalVideo': videoPath != null,
      };
    }).toList();
  }

  // Add video mapping manually (useful for custom mappings)
  void addVideoMapping(String exerciseName, String videoPath) {
    _videoMap[exerciseName.toLowerCase().trim()] = videoPath;
  }

  // Load video mappings from a JSON file
  Future<void> loadVideoMappingsFromJson() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/json/video_mappings.json');
      final Map<String, dynamic> mappings = json.decode(jsonString);
      
      mappings.forEach((key, value) {
        _videoMap[key.toLowerCase().trim()] = value.toString();
      });
    } catch (e) {
      // File doesn't exist or invalid JSON - that's okay, we'll use default mapping
      print('Could not load video mappings: $e');
    }
  }
}

