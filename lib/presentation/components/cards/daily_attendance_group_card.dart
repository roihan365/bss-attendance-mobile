import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../domain/entities/attendance_record.dart';

class DailyAttendanceGroupCard extends StatelessWidget {
  final DateTime date;
  final List<AttendanceRecord> records;

  const DailyAttendanceGroupCard({
    super.key,
    required this.date,
    required this.records,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDayHeader(DateTime d) {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    String prefix = '';
    if (_isSameDay(d, now)) {
      prefix = 'Hari Ini • ';
    } else if (_isSameDay(d, yesterday)) {
      prefix = 'Kemarin • ';
    }

    try {
      final dayName = DateFormat('EEEE, d MMM yyyy', 'id_ID').format(d);
      return '$prefix$dayName';
    } catch (_) {
      final dayName = DateFormat('EEEE, d MMM yyyy').format(d);
      return '$prefix$dayName';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort records in ascending order for daily timeline flow (checkin first, checkout second)
    final sortedRecords = List<AttendanceRecord>.from(records)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    AttendanceRecord? checkInRecord;
    AttendanceRecord? checkOutRecord;

    for (final r in sortedRecords) {
      if (r.type.toLowerCase().contains('in') && checkInRecord == null) {
        checkInRecord = r;
      } else if (r.type.toLowerCase().contains('out') && checkOutRecord == null) {
        checkOutRecord = r;
      }
    }

    // Work duration calculation
    String? workDurationText;
    if (checkInRecord != null && checkOutRecord != null) {
      final diff = checkOutRecord.timestamp.difference(checkInRecord.timestamp);
      final hours = diff.inHours;
      final minutes = diff.inMinutes.remainder(60);
      workDurationText = '${hours}j ${minutes}m';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 15, color: AppColors.steelBlue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _formatDayHeader(date),
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slateNavy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (workDurationText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreenLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: AppColors.emeraldGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Total $workDurationText',
                          style: AppTextStyles.badgeText.copyWith(
                            color: AppColors.emeraldGreen,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (checkInRecord != null && checkOutRecord == null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlueBackground,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sedang Bekerja',
                      style: AppTextStyles.badgeText.copyWith(
                        color: AppColors.steelBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.safetyAmberLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Hanya Pulang',
                      style: AppTextStyles.badgeText.copyWith(
                        color: AppColors.safetyAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Body: Timeline View
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Check-in entry
                if (checkInRecord != null)
                  _buildTimelineRow(
                    isCheckIn: true,
                    record: checkInRecord,
                    isFirst: true,
                    isLast: checkOutRecord == null,
                  )
                else
                  _buildMissingRow(
                    label: 'Presensi Masuk',
                    hint: 'Tidak ada data presensi masuk tercatat.',
                    isCheckIn: true,
                  ),

                // Connecting line if both exist or if checkout is missing
                if (checkInRecord != null && checkOutRecord == null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 17),
                    child: Row(
                      children: [
                        Container(
                          width: 2,
                          height: 24,
                          color: AppColors.borderSubtle,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Menunggu presensi pulang...',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Check-out entry
                if (checkOutRecord != null) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 17),
                    child: Container(
                      width: 2,
                      height: 14,
                      color: AppColors.borderSubtle,
                    ),
                  ),
                  _buildTimelineRow(
                    isCheckIn: false,
                    record: checkOutRecord,
                    isFirst: false,
                    isLast: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow({
    required bool isCheckIn,
    required AttendanceRecord record,
    required bool isFirst,
    required bool isLast,
  }) {
    final color = isCheckIn ? AppColors.emeraldGreen : AppColors.safetyAmber;
    final bgColor = isCheckIn ? AppColors.emeraldGreenLight : AppColors.safetyAmberLight;
    final icon = isCheckIn ? Icons.login_rounded : Icons.logout_rounded;
    final label = isCheckIn ? 'Presensi Masuk' : 'Presensi Pulang';
    final timeStr = DateFormat('HH:mm:ss').format(record.timestamp);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Icon Node
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),

        // Record Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    timeStr,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.slateNavy,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      record.locationName,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: record.syncStatus ? AppColors.emeraldGreenLight : AppColors.safetyAmberLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      record.syncStatus ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                      size: 11,
                      color: record.syncStatus ? AppColors.emeraldGreen : AppColors.safetyAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      record.syncStatus ? 'Tersinkron Server' : 'Tersimpan Offline',
                      style: AppTextStyles.badgeText.copyWith(
                        fontSize: 10,
                        color: record.syncStatus ? AppColors.emeraldGreen : AppColors.safetyAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMissingRow({
    required String label,
    required String hint,
    required bool isCheckIn,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade300, width: 1.5),
          ),
          child: const Icon(Icons.remove_circle_outline_rounded, color: Colors.grey, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
