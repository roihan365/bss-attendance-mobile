import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AttendanceHistoryCard extends StatelessWidget {
  final String type; // 'checkin' | 'checkout'
  final DateTime timestamp;
  final String locationName;
  final bool isSynced;

  const AttendanceHistoryCard({
    super.key,
    required this.type,
    required this.timestamp,
    required this.locationName,
    required this.isSynced,
  });

  @override
  Widget build(BuildContext context) {
    final isCheckIn = type.toLowerCase().contains('in');
    final color = isCheckIn ? AppColors.emeraldGreen : AppColors.safetyAmber;
    final bgColor = isCheckIn ? AppColors.emeraldGreenLight : AppColors.safetyAmberLight;
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final label = isCheckIn ? 'Presensi Masuk' : 'Presensi Pulang';

    final timeStr = DateFormat('HH:mm:ss').format(timestamp);
    final dateStr = DateFormat('d MMM yyyy').format(timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Type
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      timeStr,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.slateNavy,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationName,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Sync Status Pill & Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      dateStr,
                      style: AppTextStyles.bodySmall,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isSynced ? AppColors.emeraldGreenLight : AppColors.safetyAmberLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSynced ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                            size: 12,
                            color: isSynced ? AppColors.emeraldGreen : AppColors.safetyAmber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isSynced ? 'Tersinkronisasi' : 'Menunggu Sinyal',
                            style: AppTextStyles.badgeText.copyWith(
                              color: isSynced ? AppColors.emeraldGreen : AppColors.safetyAmber,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
