import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;

class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String updateUrl;
  final String releaseNotes;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.updateUrl,
    required this.releaseNotes,
  });
}

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Compares two version strings.
  /// Returns 1 if v1 > v2, -1 if v1 < v2, and 0 if v1 == v2.
  int compareVersions(String v1, String v2) {
    // Strip build numbers (e.g. "1.0.5+19" -> "1.0.5")
    final cleanV1 = v1.split('+').first.trim();
    final cleanV2 = v2.split('+').first.trim();

    final List<int> parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final List<int> parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final int maxLength = parts1.length > parts2.length ? parts1.length : parts2.length;
    
    while (parts1.length < maxLength) {
      parts1.add(0);
    }
    while (parts2.length < maxLength) {
      parts2.add(0);
    }

    for (int i = 0; i < maxLength; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Checks Firestore for app update configurations and compares against local version.
  Future<AppUpdateInfo> checkForUpdates() async {
    try {
      // 1. Get current version of the app
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;

      if (kDebugMode) {
        print('Current App Version: $currentVersion');
      }

      // 2. Fetch the update configuration from Firestore
      final DocumentSnapshot doc = await _firestore.collection('config').doc('app_version').get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('Update configuration document does not exist in Firestore.');
        }
        return AppUpdateInfo(
          hasUpdate: false,
          isForceUpdate: false,
          updateUrl: '',
          releaseNotes: '',
        );
      }

      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Determine platform specific fields
      String latestVersion = data['latest_version'] ?? '1.0.0';
      String minRequiredVersion = data['min_required_version'] ?? '1.0.0';
      String releaseNotes = data['release_notes'] ?? 'New features and improvements are available.';
      String updateUrl = '';

      if (kIsWeb) {
        updateUrl = data['update_url_web'] ?? '';
      } else if (Platform.isAndroid) {
        updateUrl = data['update_url_android'] ?? 'https://play.google.com/store';
        // Allow overriding config on a per-platform basis if present
        latestVersion = data['latest_version_android'] ?? latestVersion;
        minRequiredVersion = data['min_required_version_android'] ?? minRequiredVersion;
      } else if (Platform.isIOS) {
        updateUrl = data['update_url_ios'] ?? 'https://apps.apple.com';
        latestVersion = data['latest_version_ios'] ?? latestVersion;
        minRequiredVersion = data['min_required_version_ios'] ?? minRequiredVersion;
      }

      // 3. Perform version comparison
      final bool hasUpdate = compareVersions(latestVersion, currentVersion) > 0;
      final bool isForceUpdate = compareVersions(minRequiredVersion, currentVersion) > 0;

      if (kDebugMode) {
        print('Update Check Result -> hasUpdate: $hasUpdate, isForceUpdate: $isForceUpdate');
      }

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        isForceUpdate: isForceUpdate,
        updateUrl: updateUrl,
        releaseNotes: releaseNotes,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for updates: $e');
      }
      return AppUpdateInfo(
        hasUpdate: false,
        isForceUpdate: false,
        updateUrl: '',
        releaseNotes: '',
      );
    }
  }
}
