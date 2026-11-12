import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/queue_entry_model.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';
import 'package:easyqueue/ui/widgets/digital_token_card.dart';
import 'package:easyqueue/ui/widgets/queue_stepper_widget.dart';
import 'package:easyqueue/ui/widgets/counter_call_alert_widget.dart';
import 'package:easyqueue/ui/features/queue/feedback_dialog.dart';
import 'package:easyqueue/ui/features/auth/guest_onboarding_view.dart';

class DigitalTicketScreen extends StatelessWidget {
  final String entryId;

  const DigitalTicketScreen({
    super.key,
    required this.entryId,
  });

  @override
  Widget build(BuildContext context) {
    final queueVm = context.watch<QueueViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final ticket = queueVm.getTicketById(entryId);

    if (ticket == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Queue Ticket')),
        body: const Center(child: Text('Ticket not found.')),
      );
    }

    final isGuest = authVm.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          ticket.businessName,
          style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share Ticket',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Secure tracking link copied: https://easyq.app/t/${ticket.id}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Request Assistance',
            onPressed: () => _showAssistanceDialog(context, ticket),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, AppConstants.bottomNavPadding),
        children: [
          // Guest Ticket Claiming Banner (UC-004: Universal Ticket)
          if (isGuest) ...[
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Temporary Guest Ticket',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Save this ticket across devices with your phone number.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.primaryDark),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => const GuestOnboardingSheet(),
                      );
                    },
                    child: const Text('Claim Ticket', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ],

          // Counter Call or Approaching Alert
          CounterCallAlertWidget(ticket: ticket),

          // Stepper Visual
          QueueStepperWidget(currentStatus: ticket.status),
          const SizedBox(height: 12),

          // Digital Token Card
          DigitalTokenCard(ticket: ticket, showQr: true),
          const SizedBox(height: 16),

          // Real-time Queue Live Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live Queue Sync Connected',
                        style: AppTypography.labelMedium.copyWith(
                          color: Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Your position updates in real-time. You will be alerted when called.',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.green.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Service Feedback Button if Completed
          if (ticket.status == QueueStatus.completed) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.star_outline),
              label: const Text('Leave Service Feedback & Rating'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => FeedbackDialog(ticket: ticket),
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // Cancel or Leave Queue Button (UC-038, UC-039)
          if (ticket.isActive) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
              ),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Cancel / Leave Queue'),
              onPressed: () => _showCancelDialog(context, queueVm, ticket),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, QueueViewModel queueVm, QueueEntryModel ticket) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Queue Ticket?'),
        content: Text(
          'Are you sure you want to cancel token ${ticket.tokenNumber} for ${ticket.serviceName}? Your spot in line will be released.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Ticket'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await queueVm.cancelTicket(ticket.id, reason: 'Customer requested departure');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket cancelled successfully.')),
                );
              }
            },
            child: const Text('Yes, Cancel Ticket'),
          ),
        ],
      ),
    );
  }

  void _showAssistanceDialog(BuildContext context, QueueEntryModel ticket) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Customer Assistance & Support',
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Need help with your visit at ${ticket.businessName}?',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.accessible_forward, color: AppColors.primary),
              title: const Text('Request Accessibility Assistance'),
              subtitle: const Text('Notify receptionist for wheelchair or physical assistance'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Accessibility assistance request transmitted to front desk.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.directions_walk, color: AppColors.primary),
              title: const Text('Report: I Have Arrived at Location'),
              subtitle: const Text('Confirms your physical presence in waiting lobby'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Arrival confirmed with receptionist.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: AppColors.primary),
              title: const Text('Call Front Desk / Receptionist'),
              subtitle: const Text('Speak directly with the venue operator'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dialing venue reception desk...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
