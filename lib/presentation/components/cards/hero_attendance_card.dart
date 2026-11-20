import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class HeroAttendanceCard extends StatefulWidget {
  final bool isCheckedIn;
  final bool isCheckedOut;
  final String greetingName;
  final Widget actionWidget;

  const HeroAttendanceCard({
    super.key,
    required this.isCheckedIn,
    required this.isCheckedOut,
    required this.greetingName,
    required this.actionWidget,
  });

  @override
  State<HeroAttendanceCard> createState() => _HeroAttendanceCardState();
}

class _HeroAttendanceCardState extends State<HeroAttendanceCard> {
  late DateTime _currentTime;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    final hour = _currentTime.hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm:ss');
    final dateFormat = DateFormat('EEEE, d MMMM yyyy');

    String statusText;
    Color statusBgColor;
    Color statusTextColor;
    IconData statusIcon;

    if (widget.isCheckedOut) {
      statusText = 'Presensi Selesai';
      statusBgColor = AppColors.lightBlueBackground;
      statusTextColor = AppColors.steelBlue;
      statusIcon = Icons.task_alt_rounded;
    } else if (widget.isCheckedIn) {
      statusText = 'Sedang Bekerja';
      statusBgColor = AppColors.emeraldGreenLight;
      statusTextColor = AppColors.emeraldGreen;
      statusIcon = Icons.work_outline_rounded;
    } else {
      statusText = 'Belum Presensi Masuk';
      statusBgColor = AppColors.safetyAmberLight;
      statusTextColor = AppColors.safetyAmber;
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Greeting & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getGreeting()},',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      widget.greetingName,
                      style: AppTextStyles.h2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusTextColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusTextColor),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: AppTextStyles.badgeText.copyWith(color: statusTextColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Digital Live Clock
          Center(
            child: Column(
              children: [
                Text(
                  timeFormat.format(_currentTime),
                  style: AppTextStyles.digitalClock,
                ),
                const SizedBox(height: 2),
                Text(
                  dateFormat.format(_currentTime),
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Widget (Swipe to Check-in/out or Info)
          widget.actionWidget,
        ],
      ),
    );
  }
}
