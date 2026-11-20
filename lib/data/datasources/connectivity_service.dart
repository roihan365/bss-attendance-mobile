import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Future<bool> hasInternet() async {
    final result = await _connectivity.checkConnectivity();
    // In newer versions, result is a List<ConnectivityResult>
    // Check if any connection type is active
    return result.any((r) => r != ConnectivityResult.none);
  }

  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  // Convenience method to get a single ConnectivityResult (first non-none, or none)
  Future<ConnectivityResult> get firstActiveConnection async {
    final results = await _connectivity.checkConnectivity();
    return results.firstWhere(
      (r) => r != ConnectivityResult.none,
      orElse: () => ConnectivityResult.none,
    );
  }
}