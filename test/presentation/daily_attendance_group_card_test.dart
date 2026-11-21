import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/domain/entities/attendance_record.dart';
import 'package:bss_attendance_new/presentation/components/cards/daily_attendance_group_card.dart';

void main() {
  testWidgets('DailyAttendanceGroupCard displays checkin, checkout, and work duration', (tester) async {
    final now = DateTime(2026, 11, 21, 8, 0, 0);
    final checkoutTime = DateTime(2026, 11, 21, 17, 30, 0);

    final records = [
      AttendanceRecord(
        id: 'rec-1',
        userId: '1',
        type: 'checkin',
        timestamp: now,
        latitude: '-1.269160',
        longitude: '116.825264',
        locationName: 'Kantor Site Balikpapan',
        syncStatus: true,
      ),
      AttendanceRecord(
        id: 'rec-2',
        userId: '1',
        type: 'checkout',
        timestamp: checkoutTime,
        latitude: '-1.269160',
        longitude: '116.825264',
        locationName: 'Kantor Site Balikpapan',
        syncStatus: false,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DailyAttendanceGroupCard(
            date: now,
            records: records,
          ),
        ),
      ),
    );

    // Verify presence of check-in and check-out labels
    expect(find.text('Presensi Masuk'), findsOneWidget);
    expect(find.text('Presensi Pulang'), findsOneWidget);

    // Verify times rendered
    expect(find.text('08:00:00'), findsOneWidget);
    expect(find.text('17:30:00'), findsOneWidget);

    // Verify duration calculation (9 hours 30 mins)
    expect(find.text('Total 9j 30m'), findsOneWidget);

    // Verify sync statuses
    expect(find.text('Tersinkron Server'), findsOneWidget);
    expect(find.text('Tersimpan Offline'), findsOneWidget);
  });
}
