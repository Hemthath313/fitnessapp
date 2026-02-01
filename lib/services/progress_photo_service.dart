import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fitness_app/model/progress_photo.dart';

class ProgressPhotoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _photosCollection {
    if (_uid == null) throw Exception("User not authenticated");
    return _db.collection('users').doc(_uid).collection('progress_photos');
  }

  /// Upload a photo to Firebase Storage and save metadata to Firestore
  Future<ProgressPhoto> uploadPhoto({
    required File imageFile,
    required String category,
    double? weight,
    String? notes,
  }) async {
    if (_uid == null) throw Exception("User not authenticated");

    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${_uid}_${timestamp}_$category.jpg';
      final storageRef = _storage.ref().child('progress_photos/$_uid/$fileName');

      // Upload file
      final uploadTask = await storageRef.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Create photo object
      final photo = ProgressPhoto(
        id: '', // Will be set by Firestore
        imageUrl: downloadUrl,
        date: DateTime.now(),
        weight: weight,
        notes: notes,
        category: category,
      );

      // Save metadata to Firestore
      final docRef = await _photosCollection.add(photo.toMap());

      return ProgressPhoto(
        id: docRef.id,
        imageUrl: photo.imageUrl,
        date: photo.date,
        weight: photo.weight,
        notes: photo.notes,
        category: photo.category,
      );
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Get all photos for the current user, ordered by date (newest first)
  Stream<List<ProgressPhoto>> getPhotos() {
    return _photosCollection
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressPhoto.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get photos filtered by category
  Stream<List<ProgressPhoto>> getPhotosByCategory(String category) {
    return _photosCollection
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProgressPhoto.fromMap(
                doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  /// Get photos within a date range
  Future<List<ProgressPhoto>> getPhotosByDateRange(
      DateTime start, DateTime end) async {
    final snapshot = await _photosCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) =>
            ProgressPhoto.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  /// Delete a photo (both from Storage and Firestore)
  Future<void> deletePhoto(ProgressPhoto photo) async {
    try {
      // Delete from Storage
      final storageRef = _storage.refFromURL(photo.imageUrl);
      await storageRef.delete();

      // Delete from Firestore
      await _photosCollection.doc(photo.id).delete();
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  /// Get the latest photo for comparison
  Future<ProgressPhoto?> getLatestPhoto() async {
    final snapshot =
        await _photosCollection.orderBy('date', descending: true).limit(1).get();

    if (snapshot.docs.isEmpty) return null;

    return ProgressPhoto.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id);
  }

  /// Get the oldest photo for comparison
  Future<ProgressPhoto?> getOldestPhoto() async {
    final snapshot =
        await _photosCollection.orderBy('date', descending: false).limit(1).get();

    if (snapshot.docs.isEmpty) return null;

    return ProgressPhoto.fromMap(
        snapshot.docs.first.data() as Map<String, dynamic>,
        snapshot.docs.first.id);
  }
}
