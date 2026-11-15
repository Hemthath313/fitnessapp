import 'dart:convert';
import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fitness_app/config/app_update_config.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart' as play;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:fitness_app/config/app_update_config.dart';

/// State of optional update prompt / download in the current app session
enum OptionalUpdateSessionState {
  notAttempted,
  downloading,
  downloaded,
  dismissed,
}

/// Representation of the remote update configuration retrieved from Firestore.
class RemoteUpdateConfig {
  final String latestVersion;
  final String minRequiredVersion;
  final bool forceUpdate;
  final String releaseNotes;
  final String updateUrlAndroid;
  final String updateUrlIos;

  const RemoteUpdateConfig({
    required this.latestVersion,
    required this.minRequiredVersion,
    required this.forceUpdate,
    required this.releaseNotes,
    required this.updateUrlAndroid,
    required this.updateUrlIos,
  });

  factory RemoteUpdateConfig.fromMap(Map<String, dynamic> map) {
    final dynamic forceVal = map['force_update'];
    final bool parsedForce = (forceVal is bool)
        ? forceVal
        : (forceVal?.toString().toLowerCase() == 'true');

    return RemoteUpdateConfig(
      latestVersion: map['latest_version']?.toString() ??
          AppUpdateConfig.defaultMinimumRequiredVersion,
      minRequiredVersion: map['min_required_version']?.toString() ??
          AppUpdateConfig.defaultMinimumRequiredVersion,
      forceUpdate: parsedForce,
      releaseNotes: map['release_notes']?.toString() ??
          'A new version of Gym Buddy is available on Google Play!',
      updateUrlAndroid: map['update_url_android']?.toString() ??
          AppUpdateConfig.webPlayStoreUrl,
      updateUrlIos: map['update_url_ios']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latest_version': latestVersion,
      'min_required_version': minRequiredVersion,
      'force_update': forceUpdate,
      'release_notes': releaseNotes,
      'update_url_android': updateUrlAndroid,
      'update_url_ios': updateUrlIos,
    };
  }
}

/// Information regarding app update availability, enforcement policy, and store details.
class AppUpdateInfo {
  final bool hasUpdate;
  final bool isForceUpdate;
  final String updateUrl;
  final String releaseNotes;
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final String minimumRequiredVersion;
  final int? availableVersionCode;
  final bool canUsePlayStoreImmediateUpdate;
  final bool canUsePlayStoreFlexibleUpdate;

  AppUpdateInfo({
    required this.hasUpdate,
    required this.isForceUpdate,
    required this.updateUrl,
    required this.releaseNotes,
    this.currentVersion = '',
    this.currentBuildNumber = 0,
    this.latestVersion = '',
    this.minimumRequiredVersion = '',
    this.availableVersionCode,
    this.canUsePlayStoreImmediateUpdate = false,
    this.canUsePlayStoreFlexibleUpdate = false,
  });

  bool get isRecommended => !isForceUpdate && hasUpdate;
}

/// Service managing remote Firestore update configuration and Google Play In-App Updates.
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  FirebaseFirestore? _customFirestore;
  PackageInfo? _customPackageInfo;
  bool? _customIsAndroid;
  bool get isAndroidPlatform => _customIsAndroid ?? (!kIsWeb && Platform.isAndroid);
  bool? _customPlayStoreUpdateAvailable;
  bool? _customPlayStoreImmediateAllowed;
  bool? _customPlayStoreFlexibleAllowed;
  int? _customPlayStoreVersionCode;
  RemoteUpdateConfig? _customRemoteConfig;
  Map<String, dynamic>? _customRawFirestoreData;
  bool _simulateFirestoreError = false;

  /// Tracks if an update dialog is currently active on screen to prevent duplicates
  bool isDialogOpen = false;

  /// In-progress flags to prevent duplicate simultaneous update requests
  bool _isImmediateUpdateInProgress = false;
  bool _isFlexibleUpdateInProgress = false;
  bool _isFlexibleCompletionInProgress = false;
  bool _isFlexibleDownloaded = false;

  bool get isImmediateUpdateInProgress => _isImmediateUpdateInProgress;
  bool get isFlexibleUpdateInProgress => _isFlexibleUpdateInProgress;
  bool get isFlexibleCompletionInProgress => _isFlexibleCompletionInProgress;
  bool get isFlexibleUpdateDownloaded => _isFlexibleDownloaded;

  play.AppUpdateResult? _customImmediateResult;
  play.AppUpdateResult? _customFlexibleResult;
  bool _mockFlexibleUpdateCompleted = false;
  bool get mockFlexibleUpdateCompleted => _mockFlexibleUpdateCompleted;

  /// Session-level update state for optional updates
  OptionalUpdateSessionState _optionalUpdateState = OptionalUpdateSessionState.notAttempted;
  OptionalUpdateSessionState get optionalUpdateState => _optionalUpdateState;

  bool get shouldPromptOptionalUpdate =>
      _optionalUpdateState == OptionalUpdateSessionState.notAttempted;

  bool get isOptionalUpdateDismissed =>
      _optionalUpdateState == OptionalUpdateSessionState.dismissed;

  void markOptionalUpdateAttempted() {
    if (_optionalUpdateState == OptionalUpdateSessionState.notAttempted) {
      _optionalUpdateState = OptionalUpdateSessionState.downloading;
    }
  }

  void markOptionalUpdateDismissed() {
    _optionalUpdateState = OptionalUpdateSessionState.dismissed;
  }

  void markOptionalUpdateDownloaded() {
    _optionalUpdateState = OptionalUpdateSessionState.downloaded;
    _isFlexibleDownloaded = true;
  }

  void resetOptionalUpdateState() {
    _optionalUpdateState = OptionalUpdateSessionState.notAttempted;
  }

  void resetOptionalUpdateDismissed() {
    _optionalUpdateState = OptionalUpdateSessionState.notAttempted;
  }

  /// Workout session active tracking to protect user workouts from abrupt update prompts / restarts
  bool _isWorkoutSessionActive = false;
  bool get isWorkoutSessionActive => _isWorkoutSessionActive;

  /// Notifier triggered when a flexible update is downloaded and ready to complete
  final ValueNotifier<bool> updateReadyNotifier = ValueNotifier<bool>(false);

  /// Registered callback to show restart UI (e.g. persistent SnackBar with action)
  VoidCallback? onUpdateReadyPrompt;

  void setWorkoutSessionActive(bool active) {
    _isWorkoutSessionActive = active;
    if (!active && _isFlexibleDownloaded) {
      notifyUpdateReady();
    }
  }

  void notifyUpdateReady() {
    updateReadyNotifier.value = true;
    if (_isWorkoutSessionActive) {
      if (kDebugMode) {
        print('Workout session is active; deferring flexible update restart prompt.');
      }
      return;
    }
    if (onUpdateReadyPrompt != null) {
      onUpdateReadyPrompt!();
    }
  }

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  bool? _mockStoreLaunchResult;
  bool _simulateFlexibleCompletionFailure = false;

  @visibleForTesting
  void setMockDependencies({
    FirebaseFirestore? firestore,
    PackageInfo? packageInfo,
    bool? isAndroid,
    bool? playStoreUpdateAvailable,
    bool? playStoreImmediateAllowed,
    bool? playStoreFlexibleAllowed,
    int? playStoreVersionCode,
    RemoteUpdateConfig? remoteConfig,
    Map<String, dynamic>? rawFirestoreData,
    bool simulateFirestoreError = false,
    play.AppUpdateResult? mockImmediateResult,
    play.AppUpdateResult? mockFlexibleResult,
    bool? mockStoreLaunchResult,
    bool simulateFlexibleCompletionFailure = false,
  }) {
    _customFirestore = firestore;
    _customPackageInfo = packageInfo;
    _customIsAndroid = isAndroid;
    _customPlayStoreUpdateAvailable = playStoreUpdateAvailable;
    _customPlayStoreImmediateAllowed = playStoreImmediateAllowed;
    _customPlayStoreFlexibleAllowed = playStoreFlexibleAllowed;
    _customPlayStoreVersionCode = playStoreVersionCode;
    _customRemoteConfig = remoteConfig;
    _customRawFirestoreData = rawFirestoreData;
    _simulateFirestoreError = simulateFirestoreError;
    _customImmediateResult = mockImmediateResult;
    _customFlexibleResult = mockFlexibleResult;
    _mockStoreLaunchResult = mockStoreLaunchResult;
    _simulateFlexibleCompletionFailure = simulateFlexibleCompletionFailure;
  }

  @visibleForTesting
  void resetMockDependencies() {
    _customFirestore = null;
    _customPackageInfo = null;
    _customIsAndroid = null;
    _customPlayStoreUpdateAvailable = null;
    _customPlayStoreImmediateAllowed = null;
    _customPlayStoreFlexibleAllowed = null;
    _customPlayStoreVersionCode = null;
    _customRemoteConfig = null;
    _customRawFirestoreData = null;
    _simulateFirestoreError = false;
    _customImmediateResult = null;
    _customFlexibleResult = null;
    _mockStoreLaunchResult = null;
    _simulateFlexibleCompletionFailure = false;
    _isImmediateUpdateInProgress = false;
    _isFlexibleUpdateInProgress = false;
    _isFlexibleCompletionInProgress = false;
    _isFlexibleDownloaded = false;
    _mockFlexibleUpdateCompleted = false;
    isDialogOpen = false;
    _optionalUpdateState = OptionalUpdateSessionState.notAttempted;
    _isWorkoutSessionActive = false;
    updateReadyNotifier.value = false;
    onUpdateReadyPrompt = null;
    AppUpdateConfig.reset();
  }

  /// Caches the remote update configuration in SharedPreferences
  Future<void> saveCachedConfig(RemoteUpdateConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AppUpdateConfig.cachedRemoteConfigKey,
        jsonEncode(config.toMap()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save update configuration to cache: $e');
      }
    }
  }

  /// Reads the cached remote update configuration from SharedPreferences
  Future<RemoteUpdateConfig?> getCachedConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppUpdateConfig.cachedRemoteConfigKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(jsonStr);
        return RemoteUpdateConfig.fromMap(map);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to read cached update configuration: $e');
      }
    }
    return null;
  }

  /// Fetches remote update configuration from Firestore document config/app_version
  Future<RemoteUpdateConfig> fetchRemoteConfig() async {
    if (_simulateFirestoreError) {
      throw Exception('Simulated Firestore error');
    }
    if (_customRemoteConfig != null) {
      return _customRemoteConfig!;
    }
    if (_customRawFirestoreData != null) {
      return RemoteUpdateConfig.fromMap(_customRawFirestoreData!);
    }

    try {
      final doc = await _firestore
          .collection(AppUpdateConfig.firestoreConfigCollection)
          .doc(AppUpdateConfig.firestoreConfigDocument)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists && doc.data() != null) {
        final config = RemoteUpdateConfig.fromMap(doc.data()!);
        await saveCachedConfig(config);
        return config;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firestore update config fetch failed: $e');
      }
      rethrow;
    }

    throw Exception('Update config document does not exist');
  }

  /// Retrieves update configuration with offline cache fallback and hardcoded safeguard
  Future<RemoteUpdateConfig> getUpdateConfigSafe() async {
    try {
      return await fetchRemoteConfig();
    } catch (_) {
      // 1. Try SharedPreferences cache
      final cached = await getCachedConfig();
      if (cached != null) {
        if (kDebugMode) {
          print('Using cached remote update configuration');
        }
        return cached;
      }

      // 2. Fallback to hardcoded local minimum safeguard
      if (kDebugMode) {
        print('No cached update config found; using local hardcoded safeguard');
      }
      return RemoteUpdateConfig(
        latestVersion: AppUpdateConfig.defaultMinimumRequiredVersion,
        minRequiredVersion: AppUpdateConfig.defaultMinimumRequiredVersion,
        forceUpdate: false,
        releaseNotes: 'A new version of Gym Buddy is available on Google Play!',
        updateUrlAndroid: AppUpdateConfig.webPlayStoreUrl,
        updateUrlIos: '',
      );
    }
  }

  /// Safely resolves PackageInfo with instant fallback if platform channels are unavailable
  Future<PackageInfo> _getPackageInfoSafe() async {
    if (_customPackageInfo != null) return _customPackageInfo!;

    // When running inside automated widget tests without customPackageInfo or mock values,
    // avoid scheduling an uncancelled 300ms FakeAsync timer.
    final bool isTestEnv = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTestEnv) {
      try {
        return await PackageInfo.fromPlatform().timeout(Duration.zero);
      } catch (_) {
        return PackageInfo(
          appName: 'Gym Buddy',
          packageName: AppUpdateConfig.playStorePackageName,
          version: AppUpdateConfig.defaultMinimumRequiredVersion,
          buildNumber: AppUpdateConfig.defaultMinimumRequiredBuildNumber.toString(),
          buildSignature: '',
          installerStore: 'com.android.vending',
        );
      }
    }

    try {
      return await PackageInfo.fromPlatform().timeout(const Duration(milliseconds: 300));
    } catch (_) {
      return PackageInfo(
        appName: 'Gym Buddy',
        packageName: AppUpdateConfig.playStorePackageName,
        version: AppUpdateConfig.defaultMinimumRequiredVersion,
        buildNumber: AppUpdateConfig.defaultMinimumRequiredBuildNumber.toString(),
        buildSignature: '',
        installerStore: 'com.android.vending',
      );
    }
  }

  /// Compares two version strings (semantic versioning, ignoring build numbers after +).
  /// Returns 1 if v1 > v2, -1 if v1 < v2, and 0 if v1 == v2.
  int compareVersions(String v1, String v2) {
    final cleanV1 = v1.split('+').first.trim();
    final cleanV2 = v2.split('+').first.trim();

    final List<int> parts1 = cleanV1
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();
    final List<int> parts2 = cleanV2
        .split('.')
        .map((e) => int.tryParse(e.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
        .toList();

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

  /// Evaluates whether the installed version or build number is below the configured minimum.
  bool isBelowMinimum({
    required String currentVersion,
    required int currentBuildNumber,
    required String minVersion,
    required int minBuildNumber,
  }) {
    final versionComparison = compareVersions(currentVersion, minVersion);
    if (versionComparison < 0) {
      return true;
    } else if (versionComparison == 0) {
      return currentBuildNumber < minBuildNumber;
    } else {
      return false;
    }
  }

  /// Evaluates whether a mandatory update is currently required
  Future<bool> isMandatoryUpdateRequired() async {
    final updateInfo = await checkForUpdates();
    return updateInfo.isForceUpdate;
  }

  /// Checks for updates using Firestore remote configuration and Google Play In-App Updates.
  Future<AppUpdateInfo> checkForUpdates() async {
    try {
      // 1. Get current installed version
      final PackageInfo packageInfo = await _getPackageInfoSafe();
      final String currentVersion = packageInfo.version;
      final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

      final bool isAndroid = _customIsAndroid ?? (!kIsWeb && Platform.isAndroid);

      if (kDebugMode) {
        print('Current App Version: $currentVersion (Build $currentBuildNumber)');
      }

      // 2. Fetch remote update configuration (with cache and safeguard fallback)
      final RemoteUpdateConfig config = await getUpdateConfigSafe();

      // 3. Query Google Play In-App Updates (Android only)
      bool playStoreHasUpdate = _customPlayStoreUpdateAvailable ?? false;
      bool playStoreImmediateAllowed = _customPlayStoreImmediateAllowed ?? false;
      bool playStoreFlexibleAllowed = _customPlayStoreFlexibleAllowed ?? false;
      int? playStoreVersionCode = _customPlayStoreVersionCode;
      // True when Google Play actually answered (a mocked answer counts).
      bool playCheckSucceeded = isAndroid && _customPlayStoreUpdateAvailable != null;

      if (isAndroid && _customPlayStoreUpdateAvailable == null) {
        try {
          final playInfo = await play.InAppUpdate.checkForUpdate();
          playCheckSucceeded = true;
          if (playInfo.updateAvailability == play.UpdateAvailability.updateAvailable ||
              playInfo.updateAvailability == play.UpdateAvailability.developerTriggeredUpdateInProgress) {
            playStoreHasUpdate = true;
            playStoreImmediateAllowed = playInfo.immediateUpdateAllowed;
            playStoreFlexibleAllowed = playInfo.flexibleUpdateAllowed;
            playStoreVersionCode = playInfo.availableVersionCode;
            if (kDebugMode) {
              print('Google Play In-App Update detected: versionCode=$playStoreVersionCode, immediate=$playStoreImmediateAllowed, flexible=$playStoreFlexibleAllowed');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Google Play In-App Update check skipped or failed: $e');
          }
        }
      }

      // 4. Evaluate Update Decision Logic
      // - Older than latest: compareVersions(currentVersion, latestVersion) < 0
      final int latestComparison = compareVersions(currentVersion, config.latestVersion);
      final bool isOlderThanLatest = latestComparison < 0;

      // - Below min required version from Firestore:
      final int minComparison = compareVersions(currentVersion, config.minRequiredVersion);
      final bool isBelowMinRequired = minComparison < 0;

      // - Hardcoded minimum version safeguard check:
      final bool isBelowLocalMin = isBelowMinimum(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        minVersion: AppUpdateConfig.minimumRequiredVersion,
        minBuildNumber: AppUpdateConfig.minimumRequiredBuildNumber,
      );

      final bool isBelowMinimumVersion = isBelowMinRequired || isBelowLocalMin;

      // Decision rules:
      // Mandatory update:
      //   - force_update == true AND the installed version is older than latest_version.
      //   - OR the installed version is below min_required_version (or local safeguard).
      // Optional update:
      //   - force_update == false AND older than latest_version AND satisfies min_required_version.
      // No update:
      //   - If installed version is equal to or newer than latest_version, do not show update dialog,
      //     even if force_update == true.
      final bool hasUpdate;
      final bool isForceUpdate;

      if (playCheckSucceeded && !playStoreHasUpdate) {
        // Android + Play answered "no update for this device yet" (release in
        // review, staged rollout not reached this user, ...). Never prompt or
        // block: the user would open the store and find nothing to install,
        // and a forced update would lock them out.
        hasUpdate = false;
        isForceUpdate = false;
      } else if (isBelowMinimumVersion) {
        hasUpdate = true;
        isForceUpdate = true;
      } else if (playCheckSucceeded && playStoreHasUpdate) {
        // Play is the source of truth for "is there an update": offer it even
        // if latest_version in Firestore wasn't bumped. Firestore only
        // decides whether it is mandatory.
        hasUpdate = true;
        isForceUpdate = config.forceUpdate && isOlderThanLatest;
      } else if (isOlderThanLatest) {
        hasUpdate = true;
        isForceUpdate = config.forceUpdate;
      } else {
        hasUpdate = false;
        isForceUpdate = false;
      }

      // 5. Determine platform store URL
      final String updateUrl;
      if (!kIsWeb && !isAndroid) {
        updateUrl = config.updateUrlIos.isNotEmpty ? config.updateUrlIos : '';
      } else {
        updateUrl = config.updateUrlAndroid.isNotEmpty
            ? config.updateUrlAndroid
            : AppUpdateConfig.webPlayStoreUrl;
      }

      final String releaseNotes = config.releaseNotes.isNotEmpty
          ? config.releaseNotes
          : (isForceUpdate
              ? 'The installed version of Gym Buddy is no longer supported. Please update to the latest version on Google Play to continue.'
              : 'A new version of Gym Buddy is available on Google Play with new workouts, features, and improvements.');

      if (kDebugMode) {
        print('Update Check Result -> hasUpdate: $hasUpdate, isForceUpdate: $isForceUpdate (latest=${config.latestVersion}, min=${config.minRequiredVersion}, force=${config.forceUpdate}, playStoreHasUpdate=$playStoreHasUpdate)');
      }

      return AppUpdateInfo(
        hasUpdate: hasUpdate,
        isForceUpdate: isForceUpdate,
        updateUrl: updateUrl,
        releaseNotes: releaseNotes,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: config.latestVersion,
        minimumRequiredVersion: config.minRequiredVersion,
        availableVersionCode: playStoreVersionCode,
        canUsePlayStoreImmediateUpdate: playStoreImmediateAllowed,
        canUsePlayStoreFlexibleUpdate: playStoreFlexibleAllowed,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error in checkForUpdates: $e');
      }
      final isAndroid = _customIsAndroid ?? (!kIsWeb && Platform.isAndroid);
      return AppUpdateInfo(
        hasUpdate: false,
        isForceUpdate: false,
        updateUrl: isAndroid ? AppUpdateConfig.webPlayStoreUrl : '',
        releaseNotes: '',
      );
    }
  }

  /// Starts native Google Play immediate update (AppUpdateType.immediate).
  /// Prevents multiple simultaneous immediate update requests.
  Future<play.AppUpdateResult> performNativeImmediateUpdate({
    String? fallbackUrl,
  }) async {
    if (_isImmediateUpdateInProgress) {
      if (kDebugMode) {
        print('Native immediate update is already in progress, skipping duplicate call.');
      }
      return play.AppUpdateResult.inAppUpdateFailed;
    }

    _isImmediateUpdateInProgress = true;
    try {
      if (_customImmediateResult != null) {
        return _customImmediateResult!;
      }

      final isAndroid = _customIsAndroid ?? (!kIsWeb && Platform.isAndroid);
      if (!isAndroid) {
        return play.AppUpdateResult.inAppUpdateFailed;
      }

      final result = await play.InAppUpdate.performImmediateUpdate();
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Google Play native immediate update failed or unavailable: $e');
      }
      if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
        await openStore(customUrl: fallbackUrl);
      }
      return play.AppUpdateResult.inAppUpdateFailed;
    } finally {
      _isImmediateUpdateInProgress = false;
    }
  }

  /// Starts native Google Play flexible update (AppUpdateType.flexible).
  /// Allows the user to continue using Gym Buddy while the update downloads in the background.
  /// When download completes, updates session state and notifies listener without auto-restarting.
  Future<play.AppUpdateResult> startNativeFlexibleUpdate({
    String? fallbackUrl,
    VoidCallback? onDownloaded,
  }) async {
    if (_isFlexibleUpdateInProgress) {
      if (kDebugMode) {
        print('Native flexible update is already in progress, skipping duplicate call.');
      }
      return play.AppUpdateResult.inAppUpdateFailed;
    }

    _isFlexibleUpdateInProgress = true;
    try {
      if (_customFlexibleResult != null) {
        if (_customFlexibleResult == play.AppUpdateResult.success) {
          markOptionalUpdateDownloaded();
          _mockFlexibleUpdateCompleted = false;
          onDownloaded?.call();
          notifyUpdateReady();
        }
        return _customFlexibleResult!;
      }

      final isAndroid = _customIsAndroid ?? (!kIsWeb && Platform.isAndroid);
      if (!isAndroid) {
        return play.AppUpdateResult.inAppUpdateFailed;
      }

      final result = await play.InAppUpdate.startFlexibleUpdate();
      if (result == play.AppUpdateResult.success) {
        markOptionalUpdateDownloaded();
        onDownloaded?.call();
        notifyUpdateReady();
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Google Play native flexible update failed or unavailable: $e');
      }
      return play.AppUpdateResult.inAppUpdateFailed;
    } finally {
      _isFlexibleUpdateInProgress = false;
    }
  }

  /// Completes a downloaded flexible update and restarts the application.
  Future<bool> completeNativeFlexibleUpdate() async {
    if (_isFlexibleCompletionInProgress) {
      if (kDebugMode) {
        print('Native flexible update completion already in progress, ignoring duplicate call.');
      }
      return false;
    }

    _isFlexibleCompletionInProgress = true;
    try {
      if (_simulateFlexibleCompletionFailure) {
        return false;
      }
      if (_customFlexibleResult != null) {
        _mockFlexibleUpdateCompleted = true;
        return true;
      }
      await play.InAppUpdate.completeFlexibleUpdate();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error completing native flexible update: $e');
      }
      return false;
    } finally {
      _isFlexibleCompletionInProgress = false;
    }
  }

  /// Opens the store listing on Android or iOS.
  Future<bool> openStore({
    String? customUrl,
    String packageName = AppUpdateConfig.playStorePackageName,
  }) async {
    if (_mockStoreLaunchResult != null) {
      return _mockStoreLaunchResult!;
    }
    try {
      final isAndroid = _customIsAndroid ?? (!kIsWeb && Platform.isAndroid);
      if (isAndroid) {
        final marketUri = Uri.parse('market://details?id=$packageName');
        if (await canLaunchUrl(marketUri)) {
          return await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        }

        final targetUrl = (customUrl != null &&
                customUrl.isNotEmpty &&
                customUrl != 'https://play.google.com/store')
            ? customUrl
            : 'https://play.google.com/store/apps/details?id=$packageName';
        final webUri = Uri.parse(targetUrl);
        if (await canLaunchUrl(webUri)) {
          return await launchUrl(webUri, mode: LaunchMode.externalApplication);
        }
        return false;
      } else {
        // iOS or non-Android: never fallback to Google Play!
        if (customUrl != null &&
            customUrl.isNotEmpty &&
            !customUrl.contains('play.google.com') &&
            !customUrl.startsWith('market://')) {
          final webUri = Uri.parse(customUrl);
          if (await canLaunchUrl(webUri)) {
            return await launchUrl(webUri, mode: LaunchMode.externalApplication);
          }
        }
        if (kDebugMode) {
          print('iOS update URL not configured or invalid Google Play URL: $customUrl');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error launching store: $e');
      }
      return false;
    }
  }
}
