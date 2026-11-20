import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';

class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle, width: 1),
      ),
      child: IconButton(
        onPressed: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        tooltip: tooltip,
        icon: Icon(
          icon,
          size: size * 0.5,
          color: color ?? AppColors.textPrimary,
        ),
        padding: EdgeInsets.zero,
        splashRadius: size * 0.5,
      ),
    );
  }
}
