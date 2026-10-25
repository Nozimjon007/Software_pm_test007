import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'requirement_tag.dart';

/// Title block at the top of each page: title, short subtitle,
/// requirement IDs and optional action buttons on the right.
class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> requirementIds;
  final List<Widget> actions;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.requirementIds = const [],
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
            ),
            if (requirementIds.isNotEmpty) RequirementTags(requirementIds),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppColors.textMuted)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: LayoutBuilder(
        builder: (context, c) {
          if (c.maxWidth < 640 || actions.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleBlock,
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleBlock),
              Wrap(spacing: 8, children: actions),
            ],
          );
        },
      ),
    );
  }
}
