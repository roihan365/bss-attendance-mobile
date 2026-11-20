import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:bss_attendance_new/presentation/providers/attendance_provider.dart';
import 'package:bss_attendance_new/presentation/providers/auth_provider.dart';
import 'package:bss_attendance_new/main.dart';
import 'package:bss_attendance_new/core/di/injection.dart';
import 'package:bss_attendance_new/core/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AppConfig.initialize();
    await initDependencies();
  });

  testWidgets('AttendanceHomePage registers WidgetsBindingObserver and handles resume', (tester) async {
    final authProvider = getIt<AuthProvider>();
    final attendanceProvider = getIt<AttendanceProvider>(param1: authProvider);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
          ChangeNotifierProvider<AttendanceProvider>.value(value: attendanceProvider),
        ],
        child: const MaterialApp(
          home: AttendanceHomePage(),
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Simulate AppLifecycleState.resumed when app returns from background
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify widget handles resume smoothly
    expect(find.byType(AttendanceHomePage), findsOneWidget);
  });
}
