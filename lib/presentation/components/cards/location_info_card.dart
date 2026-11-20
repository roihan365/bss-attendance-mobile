import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/app_icon_button.dart';

class LocationInfoCard extends StatelessWidget {
  final String locationName;
  final String? latitude;
  final String? longitude;
  final bool isRefreshing;
  final VoidCallback onRefreshLocation;

  const LocationInfoCard({
    super.key,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.isRefreshing,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoords = latitude != null && longitude != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.lightBlueBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.steelBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lokasi Site / Proyek',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (hasCoords)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emeraldGreenLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'GPS Aktif',
                          style: AppTextStyles.badgeText.copyWith(color: AppColors.emeraldGreen),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  locationName,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasCoords) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Koordinat: $latitude, $longitude',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          AppIconButton(
            icon: Icons.my_location_rounded,
            onPressed: isRefreshing ? null : onRefreshLocation,
            tooltip: 'Segarkan Lokasi',
            color: AppColors.steelBlue,
          ),
        ],
      ),
    );
  }
}
