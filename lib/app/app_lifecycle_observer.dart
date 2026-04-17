import 'package:flutter/widgets.dart';

/// Observes app lifecycle changes (foreground, background, etc.)
/// to update user online/offline status in Firestore.
class AppLifecycleObserver extends WidgetsBindingObserver {
  final void Function(bool isOnline) onStatusChanged;

  AppLifecycleObserver({required this.onStatusChanged});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onStatusChanged(true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        onStatusChanged(false);
        break;
    }
  }
}
