import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  Timer? _pollingTimer;
  bool _isOffline = false;
  bool _isSlow = false;

  // Global key for ScaffoldMessenger to show snackbars
  static final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  void initialize() {
    _pollingTimer?.cancel();
    // Start polling every 10 seconds (standard frequency)
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkConnection();
    });
    
    // Check initial connection immediately
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    bool hasConnection = false;
    Stopwatch stopwatch = Stopwatch()..start();
    
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 5));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        hasConnection = true;
      }
    } on SocketException catch (_) {
      hasConnection = false;
    } on TimeoutException catch (_) {
      hasConnection = false;
    } catch (_) {
      hasConnection = false;
    }
    
    stopwatch.stop();
    final int responseMs = stopwatch.elapsedMilliseconds;

    // 1. Check for total disconnect
    if (!hasConnection) {
      if (!_isOffline) {
        _isOffline = true;
        _showErrorSnackBar('🚫 No internet connection properly');
      }
    } else if (_isOffline) {
      _isOffline = false;
      _showSuccessSnackBar('📶 Back online!');
    }

    // 2. Check for slow network (if connected but taking > 2 seconds)
    if (hasConnection) {
      if (responseMs > 2000) {
        if (!_isSlow) {
          _isSlow = true;
          _showWarningSnackBar('🐌 Slow network connection');
        }
      } else {
        _isSlow = false;
      }
    }
  }

  void _showErrorSnackBar(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
  }
}
