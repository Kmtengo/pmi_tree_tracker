import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  bool _isOnline = true;
  final _connectivityController = StreamController<bool>.broadcast();
  
  bool get isOnline => _isOnline;
  Stream<bool> get connectivityStream => _connectivityController.stream;

  ConnectivityService() {
    // Constructor is empty since we now initialize explicitly
  }

  // Initialize connectivity service
  Future<void> initialize() async {
    await initConnectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  // Initialize connectivity method
  Future<void> initConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _isOnline = false;
      _connectivityController.add(false);
      notifyListeners();
    }
  }

  // Update connection status based on connectivity result
  void _updateConnectionStatus(ConnectivityResult result) {
    _isOnline = (result != ConnectivityResult.none);
    notifyListeners();
  }

  @override
  void dispose() {    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
