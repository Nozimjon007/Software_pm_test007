import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small "FR-02" style chips so every screen ties back to the requirements
/// document and Jira tickets during the demo.
class RequirementTags extends StatelessWidget {
  final List<String> ids;
  const RequirementTags(this.ids, {super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final id in ids)
          Tooltip(
            message: 'Requirement $id',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.primary.withAlpha(60)),
              ),
              child: Text(
                id,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
