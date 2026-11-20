import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class OfflineStatusBanner extends StatelessWidget {
  final bool isOffline;
  final int pendingCount;
  final bool isSyncing;

  const OfflineStatusBanner({
    super.key,
    required this.isOffline,
    required this.pendingCount,
    this.isSyncing = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline && pendingCount == 0 && !isSyncing) {
      return const SizedBox.shrink();
    }

    String message;
    Color bgColor;
    Color textColor;
    IconData icon;

    if (isSyncing) {
      message = 'Menyinkronkan $pendingCount data ke server...';
      bgColor = AppColors.lightBlueBackground;
      textColor = AppColors.steelBlue;
      icon = Icons.sync_rounded;
    } else if (isOffline) {
      message = pendingCount > 0
          ? 'Mode Offline: $pendingCount presensi tersimpan di perangkat'
          : 'Mode Offline: Presensi akan tersimpan di perangkat';
      bgColor = AppColors.safetyAmberLight;
      textColor = AppColors.safetyAmber;
      icon = Icons.wifi_off_rounded;
    } else {
      message = '$pendingCount presensi menunggu sinkronisasi online';
      bgColor = AppColors.lightBlueBackground;
      textColor = AppColors.steelBlue;
      icon = Icons.cloud_upload_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(color: textColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
