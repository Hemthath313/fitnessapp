import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isToastVisible = false;

  @visibleForTesting
  static Future<bool> Function()? internetAccessCheckerForTesting;

  @visibleForTesting
  static Stream<List<ConnectivityResult>>? connectivityStreamForTesting;

  @visibleForTesting
  static Future<List<ConnectivityResult>> Function()? connectivityCheckerForTesting;

  @visibleForTesting
  static void resetTestingOverrides() {
    internetAccessCheckerForTesting = null;
    connectivityStreamForTesting = null;
    connectivityCheckerForTesting = null;
  }

  /// Stream of network interface connectivity changes
  static Stream<List<ConnectivityResult>> get onConnectivityChanged {
    if (connectivityStreamForTesting != null) {
      return connectivityStreamForTesting!;
    }
    return _connectivity.onConnectivityChanged;
  }

  /// Verifies actual internet access (distinguishing active Wi-Fi/mobile data from real uplink).
  static Future<bool> hasInternetAccess() async {
    if (internetAccessCheckerForTesting != null) {
      return internetAccessCheckerForTesting!();
    }

    try {
      final results = connectivityCheckerForTesting != null
          ? await connectivityCheckerForTesting!()
          : await _connectivity.checkConnectivity();

      final hasInterface = results.any((r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet);

      if (!hasInterface) return false;

      return _probeUplink();
    } catch (_) {
      return false;
    }
  }

  /// Checks for a real uplink (DNS / TCP), independent of what the OS reports
  /// about network interfaces. Used to double-check before telling the user
  /// they are offline, because the OS can briefly report "none" at cold start.
  static Future<bool> _probeUplink() async {
    if (internetAccessCheckerForTesting != null) {
      return internetAccessCheckerForTesting!();
    }
    try {
      // Distinguish actual internet access from merely having Wi-Fi or mobile data enabled
      try {
        final lookup = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}

      try {
        final fallback = await InternetAddress.lookup('cloudflare.com')
            .timeout(const Duration(seconds: 2));
        if (fallback.isNotEmpty && fallback[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {}

      try {
        final socket = await Socket.connect('8.8.8.8', 53,
            timeout: const Duration(seconds: 2));
        socket.destroy();
        return true;
      } catch (_) {
        try {
          final socket = await Socket.connect('1.1.1.1', 53,
              timeout: const Duration(seconds: 2));
          socket.destroy();
          return true;
        } catch (_) {
          return false;
        }
      }
    } catch (_) {
      return false;
    }
  }

  static StreamSubscription<List<ConnectivityResult>>? _toastSubscription;
  static Timer? _offlineConfirmTimer;

  /// How long we wait, and re-verify, before telling the user they are offline.
  /// The OS often reports "no connection" for a moment right after launch or
  /// while switching between Wi-Fi and mobile data; that is not a real outage.
  @visibleForTesting
  static Duration offlineConfirmDelay = const Duration(seconds: 3);

  // Initialize the network check. Safe to call more than once: it replaces the
  // previous listener instead of stacking another one.
  static Future<void> initialize() async {
    await _toastSubscription?.cancel();
    _toastSubscription = null;
    _offlineConfirmTimer?.cancel();

    final List<ConnectivityResult> initialResults =
        connectivityCheckerForTesting != null
            ? await connectivityCheckerForTesting!()
            : await _connectivity.checkConnectivity();

    if (!_hasInternet(initialResults)) {
      _confirmOfflineThenToast();
    }

    _toastSubscription = onConnectivityChanged.listen((results) {
      if (_hasInternet(results)) {
        // Back online (or never really left): drop any pending warning.
        _offlineConfirmTimer?.cancel();
      } else {
        _confirmOfflineThenToast();
      }
    });
  }

  @visibleForTesting
  static Future<void> disposeForTesting() async {
    await _toastSubscription?.cancel();
    _toastSubscription = null;
    _offlineConfirmTimer?.cancel();
    _offlineConfirmTimer = null;
    _isToastVisible = false;
    offlineConfirmDelay = const Duration(seconds: 3);
  }

  /// Waits a moment, then verifies there is genuinely no uplink before showing
  /// the toast. A transient "none" at startup is ignored.
  static void _confirmOfflineThenToast() {
    _offlineConfirmTimer?.cancel();
    _offlineConfirmTimer = Timer(offlineConfirmDelay, () async {
      final reachable = await _probeUplink();
      if (!reachable) _showNoConnectionToast();
    });
  }

  // Utility to check internet presence. VPN / "other" transports are treated
  // as connected here: they are real routes and the OS reports them instead of
  // wifi/mobile on some devices and emulators.
  static bool _hasInternet(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.other);
  }

  static void _showNoConnectionToast() {
    if (!_isToastVisible) {
      _isToastVisible = true;
      Fluttertoast.showToast(
        msg: "Please check your internet connection.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor:
            Colors.red.withValues(alpha: 0.6), // Soft red styling
        textColor: Colors.white,
      ).then((_) => _isToastVisible = false); // Reset flag after toast
    }
  }
}
