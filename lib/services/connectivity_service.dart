import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class NetworkService {
  static final Connectivity _connectivity = Connectivity();
  static bool _isToastVisible = false;

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
        results.contains(ConnectivityResult.wifi);
  }

  static void _showNoConnectionToast() {
    if (!_isToastVisible) {
      _isToastVisible = true;
      Fluttertoast.showToast(
        msg: "Please check your internet connection.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor:
            Colors.red.withOpacity(0.6), // Lower opacity for a softer look
        textColor: Colors.white,
      ).then((_) => _isToastVisible = false); // Reset flag after toast
    }
  }
}
