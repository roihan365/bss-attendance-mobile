import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/presentation/components/cards/location_info_card.dart';

void main() {
  testWidgets('LocationInfoCard renders site info, accuracy badge, and expands on tap', (tester) async {
    bool calibrated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LocationInfoCard(
              locationName: 'Kantor Pusat PT BSS',
              latitude: '-1.269160',
              longitude: '116.825264',
              accuracy: 12.5,
              isRefreshing: false,
              onRefreshLocation: () {},
              onCalibrateLocation: () async => calibrated = true,
            ),
          ),
        ),
      ),
    );

    // Initial check
    expect(find.text('Kantor Pusat PT BSS'), findsOneWidget);
    expect(find.text('Sangat Akurat (±12m)'), findsOneWidget);
    expect(find.text('Lihat Peta & Kalibrasi Akurasi GPS'), findsOneWidget);

    // Initially collapsed: action buttons not yet rendered
    expect(find.text('Buka Maps'), findsNothing);

    // Tap to expand
    await tester.tap(find.text('Lihat Peta & Kalibrasi Akurasi GPS'));
    await tester.pumpAndSettle();

    // Now expanded: buttons visible
    expect(find.text('Sembunyikan Peta & Kalibrasi'), findsOneWidget);
    expect(find.text('Buka Maps'), findsOneWidget);
    expect(find.text('Kalibrasi GPS'), findsOneWidget);

    // Tap Calibrate GPS
    await tester.tap(find.text('Kalibrasi GPS'));
    await tester.pumpAndSettle();

    expect(calibrated, isTrue);
  });
}
