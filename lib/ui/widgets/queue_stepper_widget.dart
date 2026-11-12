import 'package:flutter/material.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';

class QueueStepperWidget extends StatelessWidget {
  final QueueStatus currentStatus;

  const QueueStepperWidget({
    super.key,
    required this.currentStatus,
  });

  static const List<QueueStatus> _steps = [
    QueueStatus.joined,
    QueueStatus.waiting,
    QueueStatus.approaching,
    QueueStatus.called,
    QueueStatus.serving,
    QueueStatus.completed,
  ];

  int _getStepIndex(QueueStatus status) {
    switch (status) {
      case QueueStatus.joined:
        return 0;
      case QueueStatus.waiting:
        return 1;
      case QueueStatus.approaching:
        return 2;
      case QueueStatus.called:
        return 3;
      case QueueStatus.serving:
        return 4;
      case QueueStatus.completed:
        return 5;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getStepIndex(currentStatus);
    final isCancelled = currentStatus == QueueStatus.cancelled;

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'This ticket has been cancelled.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(_steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Connecting line
                final stepIndex = index ~/ 2;
                final isPassed = stepIndex < currentIndex;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isPassed ? AppColors.primary : AppColors.borderLight,
                  ),
                );
              } else {
                // Circle node
                final stepIndex = index ~/ 2;
                final isCurrent = stepIndex == currentIndex;
                final isPassed = stepIndex < currentIndex;

                Color nodeColor = AppColors.borderLight;
                if (isPassed) {
                  nodeColor = AppColors.primary;
                } else if (isCurrent) {
                  nodeColor = (currentStatus == QueueStatus.called)
                      ? AppColors.statusCalled
                      : AppColors.primary;
                }

                return Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: (isPassed || isCurrent) ? nodeColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: nodeColor,
                      width: 2.5,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: nodeColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isPassed
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : isCurrent
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Joined',
                style: AppTypography.labelSmall.copyWith(
                  color: currentIndex >= 0 ? AppColors.textPrimaryLight : AppColors.textMutedLight,
                ),
              ),
              Text(
                'Waiting',
                style: AppTypography.labelSmall.copyWith(
                  color: currentIndex >= 1 ? AppColors.textPrimaryLight : AppColors.textMutedLight,
                ),
              ),
              Text(
                'Approaching',
                style: AppTypography.labelSmall.copyWith(
                  color: currentIndex >= 2 ? AppColors.textPrimaryLight : AppColors.textMutedLight,
                ),
              ),
              Text(
                'Called',
                style: AppTypography.labelSmall.copyWith(
                  color: currentIndex >= 3 ? AppColors.statusCalled : AppColors.textMutedLight,
                  fontWeight: currentIndex == 3 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Text(
                'Serving',
                style: AppTypography.labelSmall.copyWith(
                  color: currentIndex >= 4 ? AppColors.textPrimaryLight : AppColors.textMutedLight,
                ),
              ),
              Text(
                'Done',
                style: AppTypography.labelSmall.copyWith(
                  color: currentIndex >= 5 ? AppColors.textPrimaryLight : AppColors.textMutedLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
