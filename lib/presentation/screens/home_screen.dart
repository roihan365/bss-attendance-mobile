import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../components/components.dart';
import '../providers/attendance_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRefreshingGps = false;

  Future<void> _handleRefreshGps(AttendanceProvider provider) async {
    setState(() => _isRefreshingGps = true);
    await provider.refreshLocation();
    if (mounted) setState(() => _isRefreshingGps = false);
  }

  Future<void> _handleCheckIn(BuildContext context, AttendanceProvider provider) async {
    try {
      final record = await provider.checkIn();
      if (context.mounted) {
        if (record.syncStatus) {
          _showFeedbackSnackBar(
            context,
            'Presensi Masuk berhasil dikirim ke server (Online)',
            AppColors.emeraldGreen,
          );
        } else {
          _showFeedbackSnackBar(
            context,
            '⏳ Presensi Masuk disimpan offline (Menunggu sinyal / tersimpan di antrean)',
            AppColors.safetyAmber,
          );
        }
        AttendanceResultSheet.show(
          context,
          type: record.type,
          timestamp: record.timestamp,
          locationName: record.locationName,
          isSynced: record.syncStatus,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _handleCheckOut(BuildContext context, AttendanceProvider provider) async {
    try {
      final record = await provider.checkOut();
      if (context.mounted) {
        if (record.syncStatus) {
          _showFeedbackSnackBar(
            context,
            'Presensi Pulang berhasil dikirim ke server (Online)',
            AppColors.emeraldGreen,
          );
        } else {
          _showFeedbackSnackBar(
            context,
            '⏳ Presensi Pulang disimpan offline (Menunggu sinyal / tersimpan di antrean)',
            AppColors.safetyAmber,
          );
        }
        AttendanceResultSheet.show(
          context,
          type: record.type,
          timestamp: record.timestamp,
          locationName: record.locationName,
          isSynced: record.syncStatus,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> _handleManualSync(BuildContext context, AttendanceProvider provider) async {
    try {
      final result = await provider.syncPending();
      if (context.mounted && result != null) {
        if (result.totalSaved > 0) {
          _showFeedbackSnackBar(
            context,
            'Berhasil sinkronisasi: ${result.totalSaved} presensi tersimpan di server.',
            AppColors.emeraldGreen,
          );
        } else if (result.totalSkipped > 0) {
          _showFeedbackSnackBar(
            context,
            '${result.totalSkipped} data dilewati server (sudah ada di database).',
            AppColors.steelBlue,
          );
        } else {
          _showFeedbackSnackBar(
            context,
            'Semua antrean offline sudah sinkron.',
            AppColors.steelBlue,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Gagal sinkronisasi antrean: ${e.toString()}');
      }
    }
  }

  void _showFeedbackSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message.replaceFirst('Exception: ', '')),
        backgroundColor: AppColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    final userName = authProvider.currentUser?.name ?? 'Karyawan PT BSS';
    final canCheckIn = attendanceProvider.canCheckIn;
    final canCheckOut = attendanceProvider.canCheckOut;
    final isCheckedIn = attendanceProvider.isCheckedIn;
    final isCheckedOut = attendanceProvider.isCheckedOut;

    final checkInRecord = attendanceProvider.currentCheckIn;
    final checkOutRecord = attendanceProvider.currentCheckOut;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Offline & Pending Banner
            OfflineStatusBanner(
              isOffline: false,
              pendingCount: attendanceProvider.pendingSyncCount,
              isSyncing: attendanceProvider.isSyncing,
              onSyncPressed: () => _handleManualSync(context, attendanceProvider),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await attendanceProvider.refreshAll();
                  await attendanceProvider.refreshLocation();
                },
                color: AppColors.steelBlue,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App Bar Header (Industrial Title + BSS Logo)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.borderSubtle),
                                  ),
                                  child: Image.asset(
                                    'assets/images/bss_logo.png',
                                    height: 30,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'PT BARITO SAMUDRA SEJAHTERA',
                                        style: AppTextStyles.badgeText.copyWith(
                                          color: AppColors.steelBlue,
                                          letterSpacing: 0.8,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Presensi Karyawan',
                                        style: AppTextStyles.h1.copyWith(fontSize: 20),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (attendanceProvider.pendingSyncCount > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => attendanceProvider.syncPending(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.safetyAmberLight,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.safetyAmber.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.sync_rounded, size: 14, color: AppColors.safetyAmber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${attendanceProvider.pendingSyncCount} Antrean',
                                      style: AppTextStyles.badgeText.copyWith(color: AppColors.safetyAmber),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Hero Attendance Card dengan Jam Digital Live & Swipe Action
                      HeroAttendanceCard(
                        isCheckedIn: isCheckedIn,
                        isCheckedOut: isCheckedOut,
                        greetingName: userName,
                        actionWidget: _buildActionWidget(
                          context,
                          attendanceProvider,
                          canCheckIn: canCheckIn,
                          canCheckOut: canCheckOut,
                          isCheckedOut: isCheckedOut,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Location Card dengan Validasi GPS & Tombol Refresh + Peta & Kalibrasi
                      LocationInfoCard(
                        locationName: attendanceProvider.currentLocationName,
                        latitude: attendanceProvider.currentLatitude,
                        longitude: attendanceProvider.currentLongitude,
                        accuracy: attendanceProvider.currentAccuracy,
                        isRefreshing: _isRefreshingGps,
                        onRefreshLocation: () => _handleRefreshGps(attendanceProvider),
                        onCalibrateLocation: () => _handleRefreshGps(attendanceProvider),
                      ),

                      const SizedBox(height: 20),

                      // Today Summary Header
                      Text(
                        'Ringkasan Kehadiran Hari Ini',
                        style: AppTextStyles.h3,
                      ),
                      const SizedBox(height: 12),

                      // Check-in & Check-out Status Grid Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildAttendanceSummaryCard(
                              title: 'Presensi Masuk',
                              timeStr: checkInRecord != null
                                  ? DateFormat('HH:mm:ss').format(checkInRecord.timestamp)
                                  : '--:--:--',
                              statusLabel: checkInRecord != null ? 'Tercatat' : 'Belum Masuk',
                              color: AppColors.emeraldGreen,
                              bgColor: AppColors.emeraldGreenLight,
                              icon: Icons.login_rounded,
                              isCompleted: checkInRecord != null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildAttendanceSummaryCard(
                              title: 'Presensi Pulang',
                              timeStr: checkOutRecord != null
                                  ? DateFormat('HH:mm:ss').format(checkOutRecord.timestamp)
                                  : '--:--:--',
                              statusLabel: checkOutRecord != null ? 'Selesai' : 'Belum Pulang',
                              color: AppColors.safetyAmber,
                              bgColor: AppColors.safetyAmberLight,
                              icon: Icons.logout_rounded,
                              isCompleted: checkOutRecord != null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionWidget(
    BuildContext context,
    AttendanceProvider provider, {
    required bool canCheckIn,
    required bool canCheckOut,
    required bool isCheckedOut,
  }) {
    if (provider.isLoading) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.steelBlue),
          ),
        ),
      );
    }

    if (provider.todayStatus.onLeave) {
      final leaveTitle = provider.todayStatus.leave?.leaveTypeName ?? 'Izin / Cuti';
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.safetyAmberLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.safetyAmber.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_available_rounded, color: AppColors.safetyAmber, size: 22),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Sedang Dalam Masa $leaveTitle',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.safetyAmber,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (isCheckedOut) {
      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.lightBlueBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.steelBlue, size: 22),
            const SizedBox(width: 8),
            Text(
              'Presensi hari ini telah lengkap',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.steelBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    if (!provider.isWithinWorkRadius && (canCheckIn || canCheckOut)) {
      final eval = provider.geofenceEvaluation;
      final distText = eval?.distanceMeters != null ? '${eval!.distanceMeters!.round()}m' : 'jauh';
      final locName = eval?.nearestLocation?.name ?? 'Lokasi Kerja';
      final maxRadius = eval?.nearestLocation?.radiusMeters ?? 0;

      return Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.errorRedLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.errorRed, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Di luar radius $locName ($distText / maks ${maxRadius}m)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    if (canCheckIn) {
      return SwipeActionButton(
        text: 'Geser untuk Presensi Masuk',
        isCheckIn: true,
        onSwipeComplete: () => _handleCheckIn(context, provider),
      );
    }

    if (canCheckOut) {
      return SwipeActionButton(
        text: 'Geser untuk Presensi Pulang',
        isCheckIn: false,
        onSwipeComplete: () => _handleCheckOut(context, provider),
      );
    }

    return SwipeActionButton(
      text: 'Presensi Selesai',
      enabled: false,
      onSwipeComplete: () {},
    );
  }

  Widget _buildAttendanceSummaryCard({
    required String title,
    required String timeStr,
    required String statusLabel,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required bool isCompleted,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted ? bgColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: isCompleted ? color : AppColors.textMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompleted ? bgColor : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.badgeText.copyWith(
                    color: isCompleted ? color : AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            timeStr,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
