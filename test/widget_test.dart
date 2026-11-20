import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bss_attendance_new/presentation/components/components.dart';

void main() {
  group('UI Components Smoke Tests', () {
    testWidgets('AppButton renders text and triggers callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Presensi Masuk',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Presensi Masuk'), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('AppButton displays loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppButton(
              text: 'Simpan',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Simpan'), findsNothing);
    });

    testWidgets('LocationInfoCard renders site information', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationInfoCard(
              locationName: 'Site Proyek BSS - Sektor Utara',
              latitude: '-6.2145',
              longitude: '106.8451',
              isRefreshing: false,
              onRefreshLocation: () {},
            ),
          ),
        ),
      );

      expect(find.text('Site Proyek BSS - Sektor Utara'), findsOneWidget);
      expect(find.text('GPS Aktif'), findsOneWidget);
      expect(find.text('Koordinat: -6.2145, 106.8451'), findsOneWidget);
    });

    testWidgets('OfflineStatusBanner renders proper offline message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineStatusBanner(
              isOffline: true,
              pendingCount: 3,
            ),
          ),
        ),
      );

      expect(
        find.text('Mode Offline: 3 presensi tersimpan di perangkat'),
        findsOneWidget,
      );
    });
  });
}
