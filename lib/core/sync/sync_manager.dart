import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/datasources/connectivity_service.dart';
import '../../domain/entities/sync_batch_result.dart';
import '../../domain/usecases/sync_batch_offline.dart';

class SyncManager {
  final ConnectivityService connectivityService;
  final SyncBatchOfflineUseCase syncBatchOfflineUseCase;

  StreamSubscription? _connectivitySubscription;
  bool _isSyncing = false;
  Timer? _debounceTimer;

  final _syncStatusController = StreamController<bool>.broadcast();
  Stream<bool> get onSyncStatusChanged => _syncStatusController.stream;

  SyncManager({
    required this.connectivityService,
    required this.syncBatchOfflineUseCase,
  });

  void startListening({Function(SyncBatchResult result)? onSyncSuccess}) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = connectivityService.onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) {
        // Debounce 2 detik untuk menghindari trigger berulang saat sinyal flapping
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(seconds: 2), () async {
          final result = await triggerSync();
          if (result != null && result.totalSaved > 0) {
            onSyncSuccess?.call(result);
          }
        });
      }
    });
  }

  Future<SyncBatchResult?> triggerSync() async {
    if (_isSyncing) return null;

    final hasInternet = await connectivityService.hasInternet();
    if (!hasInternet) return null;

    _isSyncing = true;
    _syncStatusController.add(true);

    try {
      final result = await syncBatchOfflineUseCase();
      return result;
    } catch (_) {
      return null;
    } finally {
      _isSyncing = false;
      _syncStatusController.add(false);
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncStatusController.close();
  }
}
