import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/queue_entry_model.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';

class FeedbackDialog extends StatefulWidget {
  final QueueEntryModel ticket;

  const FeedbackDialog({
    super.key,
    required this.ticket,
  });

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  double _overallRating = 5;
  double _waitRating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queueVm = context.watch<QueueViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          const Icon(Icons.rate_review_outlined, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            'Rate Service',
            style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How was your experience at ${widget.ticket.businessName}?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),

            // Overall Experience
            Text('Overall Experience', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    starIndex <= _overallRating ? Icons.star : Icons.star_border,
                    color: AppColors.warning,
                    size: 32,
                  ),
                  onPressed: () => setState(() => _overallRating = starIndex.toDouble()),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Wait time experience
            Text('Waiting Time Satisfaction', style: AppTypography.labelMedium),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    starIndex <= _waitRating ? Icons.star : Icons.star_border,
                    color: AppColors.secondary,
                    size: 26,
                  ),
                  onPressed: () => setState(() => _waitRating = starIndex.toDouble()),
                );
              }),
            ),
            const SizedBox(height: 14),

            // Comment Field
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Share feedback or compliments for the staff...',
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Skip'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(100, 40),
          ),
          onPressed: () async {
            if (user != null) {
              await queueVm.submitFeedback(
                customerId: user.id,
                customerName: user.displayName,
                businessId: widget.ticket.businessId,
                branchId: widget.ticket.branchId,
                serviceId: widget.ticket.serviceId,
                entryId: widget.ticket.id,
                rating: _overallRating,
                waitTimeRating: _waitRating,
                comment: _commentController.text.trim(),
              );
            }
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            }
          },
          child: const Text('Submit Review'),
        ),
      ],
    );
  }
}
