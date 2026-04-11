// ============================================================
// service: connectivity_service.dart
// Auto network switching – wraps connectivity_plus.
// Exposes:
//   • isOnline  – single async check
//   • onlineStream – broadcast stream of connectivity changes
// ============================================================

import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();

  /// One-shot check: returns true if any network is available.
  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _resultIsOnline(result);
  }

  /// Continuous stream; emits `true` when online, `false` when offline.
  Stream<bool> get onlineStream =>
      _connectivity.onConnectivityChanged.map(_resultIsOnline);

  static bool _resultIsOnline(ConnectivityResult result) =>
      result != ConnectivityResult.none;
}
