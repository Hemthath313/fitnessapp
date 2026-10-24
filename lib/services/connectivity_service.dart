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

  // Initialize the network check
  static Future<void> initialize() async {
    // Perform an initial connectivity check
    final List<ConnectivityResult> initialResults =
        await _connectivity.checkConnectivity();

    if (!_hasInternet(initialResults)) {
      _showNoConnectionToast();
    }

    // Listen for connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (!_hasInternet(results)) {
        _showNoConnectionToast();
      }
    });
  }

  // Utility to check internet presence
  static bool _hasInternet(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet);
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
