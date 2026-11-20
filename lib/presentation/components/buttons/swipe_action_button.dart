import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SwipeActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onSwipeComplete;
  final bool isCheckIn;
  final bool enabled;

  const SwipeActionButton({
    super.key,
    required this.text,
    required this.onSwipeComplete,
    this.isCheckIn = true,
    this.enabled = true,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> {
  double _dragPosition = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = widget.isCheckIn ? AppColors.emeraldGreen : AppColors.safetyAmber;
    const double buttonHeight = 56.0;
    const double thumbSize = 48.0;
    const double padding = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - thumbSize - (padding * 2);

        return Container(
          height: buttonHeight,
          width: double.infinity,
          decoration: BoxDecoration(
            color: widget.enabled
                ? (widget.isCheckIn ? AppColors.emeraldGreenLight : AppColors.safetyAmberLight)
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.enabled ? activeColor.withValues(alpha: 0.3) : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Progress track
              Container(
                width: _dragPosition + thumbSize + (padding * 2),
                height: buttonHeight,
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),

              // Instructional Text
              Center(
                child: Text(
                  widget.enabled ? widget.text : 'Presensi Dinonaktifkan',
                  style: AppTextStyles.buttonText.copyWith(
                    color: widget.enabled ? activeColor : Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              // Draggable Thumb
              Positioned(
                left: padding + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: widget.enabled && !_isCompleted
                      ? (details) {
                          setState(() {
                            _dragPosition = (_dragPosition + details.delta.dx)
                                .clamp(0.0, maxDrag);
                          });
                        }
                      : null,
                  onHorizontalDragEnd: widget.enabled && !_isCompleted
                      ? (details) {
                          if (_dragPosition >= maxDrag * 0.85) {
                            setState(() {
                              _dragPosition = maxDrag;
                              _isCompleted = true;
                            });
                            HapticFeedback.heavyImpact();
                            widget.onSwipeComplete();
                            // Reset state after completion
                            Future.delayed(const Duration(milliseconds: 600), () {
                              if (mounted) {
                                setState(() {
                                  _dragPosition = 0.0;
                                  _isCompleted = false;
                                });
                              }
                            });
                          } else {
                            setState(() {
                              _dragPosition = 0.0;
                            });
                          }
                        }
                      : null,
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: widget.enabled ? activeColor : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isCompleted
                          ? Icons.check_rounded
                          : (widget.isCheckIn
                              ? Icons.login_rounded
                              : Icons.logout_rounded),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
