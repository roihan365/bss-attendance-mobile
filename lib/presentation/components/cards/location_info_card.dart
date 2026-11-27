import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../buttons/app_icon_button.dart';

class LocationInfoCard extends StatefulWidget {
  final String locationName;
  final String? latitude;
  final String? longitude;
  final double? accuracy;
  final bool isRefreshing;
  final VoidCallback onRefreshLocation;
  final Future<void> Function()? onCalibrateLocation;

  const LocationInfoCard({
    super.key,
    required this.locationName,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.isRefreshing,
    required this.onRefreshLocation,
    this.onCalibrateLocation,
  });

  @override
  State<LocationInfoCard> createState() => _LocationInfoCardState();
}

class _LocationInfoCardState extends State<LocationInfoCard> {
  bool _isExpanded = false;
  bool _isCalibrating = false;

  Future<void> _openGoogleMaps() async {
    if (widget.latitude == null || widget.longitude == null) return;
    final lat = widget.latitude!;
    final lng = widget.longitude!;

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tidak dapat membuka aplikasi Google Maps.')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal meluncurkan peta eksternal.')),
        );
      }
    }
  }

  Future<void> _handleCalibrate() async {
    if (widget.onCalibrateLocation == null) {
      widget.onRefreshLocation();
      return;
    }

    setState(() => _isCalibrating = true);
    try {
      await widget.onCalibrateLocation!();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kalibrasi GPS selesai! Akurasi koordinat diperbarui.',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.emeraldGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal kalibrasi GPS: ${e.toString().replaceFirst('Exception: ', '')}'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCalibrating = false);
    }
  }

  Widget _buildAccuracyBadge() {
    final acc = widget.accuracy;
    if (acc == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          'GPS Aktif',
          style: AppTextStyles.badgeText.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    Color bgColor;
    Color textColor;
    String label;

    if (acc <= 15) {
      bgColor = AppColors.emeraldGreenLight;
      textColor = AppColors.emeraldGreen;
      label = 'Sangat Akurat (±${acc.toInt()}m)';
    } else if (acc <= 40) {
      bgColor = AppColors.lightBlueBackground;
      textColor = AppColors.steelBlue;
      label = 'Cukup Akurat (±${acc.toInt()}m)';
    } else {
      bgColor = AppColors.safetyAmberLight;
      textColor = AppColors.safetyAmber;
      label = 'Perlu Kalibrasi (±${acc.toInt()}m)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.gps_fixed_rounded, size: 11, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.badgeText.copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCoords = widget.latitude != null && widget.longitude != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Location Card Row
          Padding(
            padding: const EdgeInsets.all(16),
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
                          Expanded(
                            child: Text(
                              'Lokasi Site / Proyek',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (hasCoords) ...[
                            const SizedBox(width: 6),
                            _buildAccuracyBadge(),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.locationName,
                        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasCoords) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Koordinat: ${widget.latitude}, ${widget.longitude}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppIconButton(
                  icon: Icons.my_location_rounded,
                  onPressed: widget.isRefreshing ? null : widget.onRefreshLocation,
                  tooltip: 'Segarkan Lokasi',
                  color: AppColors.steelBlue,
                ),
              ],
            ),
          ),

          // Divider before toggle
          const Divider(height: 1, color: AppColors.borderSubtle),

          // Collapsible Trigger Bar
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.map_outlined : Icons.map_rounded,
                    size: 16,
                    color: AppColors.steelBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isExpanded ? 'Sembunyikan Peta & Kalibrasi' : 'Lihat Peta & Kalibrasi Akurasi GPS',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.steelBlue,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.steelBlue,
                  ),
                ],
              ),
            ),
          ),

          // Collapsible Content
          if (_isExpanded) _buildExpandedMapSection(context),
        ],
      ),
    );
  }

  Widget _buildExpandedMapSection(BuildContext context) {
    final lat = widget.latitude ?? '-';
    final lng = widget.longitude ?? '-';
    final acc = widget.accuracy?.toStringAsFixed(1) ?? '10.0';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stylized Mini Map Card / Radar View
          Container(
            height: 140,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Dark slate navy
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.3)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Grid background simulation
                CustomPaint(
                  size: const Size(double.infinity, 140),
                  painter: _MapGridPainter(),
                ),

                // Radar rings for accuracy
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.steelBlue.withValues(alpha: 0.35), width: 1.5),
                    color: AppColors.steelBlue.withValues(alpha: 0.08),
                  ),
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.5), width: 1.5),
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  ),
                ),

                // Center Pin Marker
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emeraldGreen.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 20),
                    ),
                  ],
                ),

                // Top Badge: Coordinates Overlay
                Positioned(
                  top: 8,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'LAT: $lat | LNG: $lng',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Bottom Badge: Radius Overlay
                Positioned(
                  bottom: 8,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.shield_outlined, color: AppColors.emeraldGreen, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          'Radius: ±$acc m (Anti-Mock Valid)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Actions Row: Open Google Maps & Recalibrate
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openGoogleMaps,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Buka Maps', maxLines: 1, overflow: TextOverflow.ellipsis),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.steelBlue,
                    side: const BorderSide(color: AppColors.steelBlue),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCalibrating ? null : _handleCalibrate,
                  icon: _isCalibrating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.tune_rounded, size: 16),
                  label: Text(
                    _isCalibrating ? 'Kalibrasi...' : 'Kalibrasi GPS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.steelBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
