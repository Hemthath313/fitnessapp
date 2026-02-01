import 'dart:io';
import 'package:fitness_app/model/progress_photo.dart';
import 'package:fitness_app/services/progress_photo_service.dart';
import 'package:flutter/material.dart';

class ProgressPhotoProvider with ChangeNotifier {
  final ProgressPhotoService _service = ProgressPhotoService();

  List<ProgressPhoto> _photos = [];
  bool _isLoading = false;
  String? _error;
  String _selectedCategory = 'all';

  List<ProgressPhoto> get photos => _selectedCategory == 'all'
      ? _photos
      : _photos.where((p) => p.category == _selectedCategory).toList();

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedCategory => _selectedCategory;
  bool get hasPhotos => _photos.isNotEmpty;

  /// Set category filter
  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Listen to photo updates from Firestore
  void listenToPhotos() {
    _service.getPhotos().listen(
      (photoList) {
        _photos = photoList;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Upload a new progress photo
  Future<void> uploadPhoto({
    required File imageFile,
    required String category,
    double? weight,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.uploadPhoto(
        imageFile: imageFile,
        category: category,
        weight: weight,
        notes: notes,
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Delete a photo
  Future<void> deletePhoto(ProgressPhoto photo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deletePhoto(photo);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Get photos for comparison (latest and oldest)
  Future<Map<String, ProgressPhoto?>> getComparisonPhotos() async {
    try {
      final latest = await _service.getLatestPhoto();
      final oldest = await _service.getOldestPhoto();
      return {'latest': latest, 'oldest': oldest};
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return {'latest': null, 'oldest': null};
    }
  }

  /// Get all photos (unfiltered)
  List<ProgressPhoto> get allPhotos => _photos;
}
