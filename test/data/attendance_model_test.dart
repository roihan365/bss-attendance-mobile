import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/data/models/attendance_model.dart';

void main() {
  group('AttendanceModel Tests', () {
    test('fromServerJson parses Laravel API response correctly', () {
      final json = {
        'id': 12,
        'uuid': 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        'user_id': 1,
        'type': 'checkin',
        'timestamps': '2026-11-20T08:02:15.000000Z',
        'latitude': -6.2145,
        'longitude': 106.8451,
        'location_name': 'Site Proyek BSS - Sektor Utara',
        'sync_status': true,
      };

      final model = AttendanceModel.fromServerJson(json);

      expect(model.serverId, '12');
      expect(model.uuid, 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d');
      expect(model.userId, '1');
      expect(model.type, 'checkin');
      expect(model.latitude, '-6.2145');
      expect(model.longitude, '106.8451');
      expect(model.locationName, 'Site Proyek BSS - Sektor Utara');
      expect(model.syncStatus, isTrue);
    });

    test('toApiSyncJson formats payload matching backend sync-offline expectation', () {
      final model = AttendanceModel(
        id: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        uuid: 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d',
        userId: '1',
        type: 'checkin',
        timestamp: DateTime.parse('2026-11-20T08:00:00Z'),
        latitude: '-6.2145',
        longitude: '106.8451',
        locationName: 'Site Proyek BSS',
        syncStatus: false,
      );

      final apiJson = model.toApiSyncJson();

      expect(apiJson['uuid'], 'a1b2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d');
      expect(apiJson['type'], 'checkin');
      expect(apiJson['latitude'], -6.2145);
      expect(apiJson['longitude'], 106.8451);
      expect(apiJson['location_name'], 'Site Proyek BSS');
    });
  });
}
