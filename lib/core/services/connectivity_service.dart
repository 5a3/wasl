import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Singleton Service to continuously monitor internet connectivity status
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void initialize() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _updateStatus(results);
    });

    _connectivity.checkConnectivity().then((results) {
      _updateStatus(results);
    });
  }

  void _updateStatus(List<ConnectivityResult> results) {
    bool hasConnection = results.any((result) => result != ConnectivityResult.none);
    if (_isOnline != hasConnection) {
      _isOnline = hasConnection;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
