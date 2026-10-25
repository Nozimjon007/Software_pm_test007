import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "7 / 12 seats" with a progress bar. Turns amber when almost full,
/// red when full.
class SeatBar extends StatelessWidget {
  final int taken;
  final int capacity;

  const SeatBar({super.key, required this.taken, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final ratio = capacity == 0 ? 0.0 : taken / capacity;
    final left = capacity - taken;
    final color = left <= 0
        ? AppColors.danger
        : ratio >= 0.8
            ? AppColors.warning
            : AppColors.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('$taken / $capacity seats booked', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Spacer(),
            Text(
              left <= 0 ? 'Full' : '$left open',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0).toDouble(),
            minHeight: 8,
            color: color,
            backgroundColor: AppColors.border,
          ),
        ),
      ],
    );
  }
}
