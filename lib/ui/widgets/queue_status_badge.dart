import 'package:flutter/material.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';

class QueueStatusBadge extends StatelessWidget {
  final QueueStatus status;
  final bool isLarge;

  const QueueStatusBadge({
    super.key,
    required this.status,
    this.isLarge = false,
  });

  Color _getBadgeColor() {
    switch (status) {
      case QueueStatus.joined:
        return AppColors.statusJoined;
      case QueueStatus.waiting:
        return AppColors.statusWaiting;
      case QueueStatus.approaching:
        return AppColors.statusApproaching;
      case QueueStatus.called:
        return AppColors.statusCalled;
      case QueueStatus.serving:
        return AppColors.statusServing;
      case QueueStatus.completed:
        return AppColors.statusCompleted;
      case QueueStatus.cancelled:
      case QueueStatus.missed:
        return AppColors.statusCancelled;
      case QueueStatus.waitlisted:
        return Colors.orange;
      case QueueStatus.expired:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getBadgeColor();
    final isUrgent = status == QueueStatus.called || status == QueueStatus.approaching;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 8,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isLarge ? 8 : 6,
            height: isLarge ? 8 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: isUrgent
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.displayName.toUpperCase(),
            style: (isLarge ? AppTypography.labelMedium : AppTypography.labelSmall).copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
