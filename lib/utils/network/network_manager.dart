import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkManager extends ChangeNotifier {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  bool _isFirstCheck = true;
  bool get isFirstCheck => _isFirstCheck;

  StreamSubscription? _subscription;

  void initialize() {
    if (_subscription != null) return; // Prevent multiple subscriptions!

    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // In newer versions of connectivity_plus, it returns a List of results
      final connected = !results.contains(ConnectivityResult.none);

      if (_isConnected != connected || _isFirstCheck) {
        _isConnected = connected;
        _isFirstCheck = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

