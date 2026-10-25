import 'package:flutter/material.dart';

import '../models/transport_license.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'requirement_tag.dart';

/// Warning banner shown when the passenger-transport license is about to
/// expire or has expired (NFR-04).
class LicenseBanner extends StatelessWidget {
  final TransportLicense license;
  final DateTime today;
  final VoidCallback? onDetails;

  const LicenseBanner({
    super.key,
    required this.license,
    required this.today,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (!license.needsWarning(today)) return const SizedBox.shrink();

    final days = license.daysLeft(today);
    final expired = license.isExpired(today);
    final color = expired ? AppColors.danger : const Color(0xFF9A6A00);
    final bg = expired ? AppColors.dangerBg : AppColors.warningBg;
    final title = expired
        ? 'Passenger-transport license EXPIRED ${-days} day(s) ago'
        : 'Passenger-transport license expires in $days day(s)';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
                    const RequirementTags(['NFR-04']),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'License ${license.number} · valid until ${Fmt.date(license.expiresOn)}. '
                  'Renew it before expiry to keep running shuttles legally.',
                  style: const TextStyle(color: Color(0xFF4A3B12)),
                ),
              ],
            ),
          ),
          if (onDetails != null)
            TextButton(onPressed: onDetails, child: const Text('Details')),
        ],
      ),
    );
  }
}
