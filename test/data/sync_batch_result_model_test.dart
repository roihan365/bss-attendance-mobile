import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/data/models/sync_batch_result_model.dart';

void main() {
  group('SyncBatchResultModel Tests', () {
    test('fromJson parses batch sync response with saved and skipped entries', () {
      final json = {
        'total_received': 2,
        'total_saved': 1,
        'total_skipped': 1,
        'data': [
          {
            'id': 101,
            'uuid': 'uuid-saved-01',
            'user_id': 1,
            'type': 'checkin',
            'timestamps': '2026-11-20T08:00:00.000000Z',
            'latitude': -6.2,
            'longitude': 106.8,
            'location_name': 'Site Office',
            'sync_status': true,
          }
        ],
        'skipped': [
          {
            'uuid': 'uuid-dup-02',
            'type': 'checkout',
            'reason': 'UUID sudah terdaftar.',
          }
        ],
      };

      final result = SyncBatchResultModel.fromJson(json);

      expect(result.totalReceived, 2);
      expect(result.totalSaved, 1);
      expect(result.totalSkipped, 1);

      expect(result.savedRecords.length, 1);
      expect(result.savedRecords.first.uuid, 'uuid-saved-01');
      expect(result.savedRecords.first.syncStatus, isTrue);

      expect(result.skippedRecords.length, 1);
      expect(result.skippedRecords.first.uuid, 'uuid-dup-02');
      expect(result.skippedRecords.first.reason, 'UUID sudah terdaftar.');
    });
  });
}
