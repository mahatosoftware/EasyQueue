import 'package:flutter/material.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/queue_entry_model.dart';

class CounterCallAlertWidget extends StatelessWidget {
  final QueueEntryModel ticket;

  const CounterCallAlertWidget({
    super.key,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final isCalled = ticket.status == QueueStatus.called;
    final isApproaching = ticket.status == QueueStatus.approaching;

    if (!isCalled && !isApproaching) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCalled ? AppColors.calledGradient : AppColors.approachingGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isCalled ? AppColors.statusCalled : AppColors.statusApproaching).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCalled ? Icons.campaign_rounded : Icons.directions_walk_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCalled ? 'YOUR TOKEN IS CALLED!' : 'APPROACHING YOUR TURN',
                  style: AppTypography.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  isCalled
                      ? 'Proceed immediately to ${ticket.assignedCounterNumber ?? "Counter 3"}'
                      : 'You are next in line! Make your way to the waiting area.',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isCalled && ticket.assignedCounterFloor != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.white),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          ticket.assignedCounterFloor!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
