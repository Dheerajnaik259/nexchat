import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

/// Connectivity status enum
enum ConnectivityStatus { connected, disconnected }

/// Provider that watches network connectivity in real-time
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier() : super(ConnectivityStatus.connected) {
    _init();
  }

  void _init() {
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        state = ConnectivityStatus.disconnected;
      } else {
        state = ConnectivityStatus.connected;
      }
    });

    // Check initial status
    _checkInitial();
  }

  Future<void> _checkInitial() async {
    final results = await Connectivity().checkConnectivity();
    if (results.contains(ConnectivityResult.none) || results.isEmpty) {
      state = ConnectivityStatus.disconnected;
    } else {
      state = ConnectivityStatus.connected;
    }
  }

  /// Whether the device is currently connected
  bool get isConnected => state == ConnectivityStatus.connected;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
