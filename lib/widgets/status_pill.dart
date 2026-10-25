import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PillTone { ok, warning, danger, neutral, info }

/// Rounded label like "Active", "Over limit", "Cancelled".
class StatusPill extends StatelessWidget {
  final String text;
  final PillTone tone;
  final IconData? icon;

  const StatusPill(this.text, {super.key, this.tone = PillTone.neutral, this.icon});

  @override
  Widget build(BuildContext context) {
    final (Color fg, Color bg) = switch (tone) {
      PillTone.ok => (AppColors.accent, AppColors.successBg),
      PillTone.warning => (const Color(0xFF9A6A00), AppColors.warningBg),
      PillTone.danger => (AppColors.danger, AppColors.dangerBg),
      PillTone.info => (AppColors.primary, const Color(0xFFE6EEF7)),
      PillTone.neutral => (AppColors.textMuted, const Color(0xFFEFF2F6)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
