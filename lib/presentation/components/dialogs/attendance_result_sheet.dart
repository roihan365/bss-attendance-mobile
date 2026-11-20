import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/app_button.dart';

class AttendanceResultSheet extends StatelessWidget {
  final String type; // 'checkin' | 'checkout'
  final DateTime timestamp;
  final String locationName;
  final bool isSynced;

  const AttendanceResultSheet({
    super.key,
    required this.type,
    required this.timestamp,
    required this.locationName,
    required this.isSynced,
  });

  static Future<void> show(
    BuildContext context, {
    required String type,
    required DateTime timestamp,
    required String locationName,
    required bool isSynced,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AttendanceResultSheet(
        type: type,
        timestamp: timestamp,
        locationName: locationName,
        isSynced: isSynced,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCheckIn = type.toLowerCase().contains('in');
    final title = isCheckIn ? 'Presensi Masuk Berhasil' : 'Presensi Pulang Berhasil';
    final activeColor = isCheckIn ? AppColors.emeraldGreen : AppColors.safetyAmber;
    final timeStr = DateFormat('HH:mm:ss').format(timestamp);
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(timestamp);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Success Icon Badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCheckIn ? AppColors.emeraldGreenLight : AppColors.safetyAmberLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCheckIn ? Icons.login_rounded : Icons.logout_rounded,
              color: activeColor,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),

          Text(title, style: AppTextStyles.h1, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(dateStr, style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),

          const SizedBox(height: 20),

          // Detail Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                _buildRow(Icons.access_time_rounded, 'Waktu Tercatat', '$timeStr WIB'),
                const Divider(height: 20, color: AppColors.borderSubtle),
                _buildRow(Icons.location_on_outlined, 'Lokasi', locationName),
                const Divider(height: 20, color: AppColors.borderSubtle),
                _buildRow(
                  isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                  'Status Penyimpanan',
                  isSynced ? 'Tersimpan di Cloud' : 'Tersimpan di Perangkat (Offline)',
                  textColor: isSynced ? AppColors.emeraldGreen : AppColors.safetyAmber,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          AppButton(
            text: 'Tutup',
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor ?? AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
