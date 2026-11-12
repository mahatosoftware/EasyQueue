import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/core/utils/date_formatter.dart';
import 'package:easyqueue/ui/view_models/queue_view_model.dart';
import 'package:easyqueue/ui/view_models/home_view_model.dart';
import 'package:easyqueue/ui/widgets/digital_token_card.dart';
import 'package:easyqueue/ui/features/queue/digital_ticket_screen.dart';
import 'package:easyqueue/ui/widgets/queue_status_badge.dart';

class MyTicketsScreen extends StatelessWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queueVm = context.watch<QueueViewModel>();
    final homeVm = context.watch<HomeViewModel>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Tickets',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMutedLight,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'History'),
              Tab(text: 'Notifications'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Active Tickets
            _buildActiveTab(context, queueVm),

            // Tab 2: History
            _buildHistoryTab(context, queueVm),

            // Tab 3: Notifications
            _buildNotificationsTab(context, homeVm),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(BuildContext context, QueueViewModel queueVm) {
    final active = queueVm.activeTickets;

    if (active.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.confirmation_number_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No Active Queue Tickets',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Join a queue from the Home or Explore tab, or scan a business QR code to get a token.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
      itemCount: active.length,
      itemBuilder: (context, index) {
        final ticket = active[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DigitalTokenCard(
            ticket: ticket,
            showQr: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DigitalTicketScreen(entryId: ticket.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab(BuildContext context, QueueViewModel queueVm) {
    final past = queueVm.pastTickets;

    if (past.isEmpty) {
      return Center(
        child: Text(
          'No completed tickets yet.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
      itemCount: past.length,
      itemBuilder: (context, index) {
        final ticket = past[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                ticket.tokenNumber,
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              ticket.serviceName,
              style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${ticket.businessName} • ${DateFormatter.formatDate(ticket.joinedAt)}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
            ),
            trailing: QueueStatusBadge(status: ticket.status),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DigitalTicketScreen(entryId: ticket.id),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNotificationsTab(BuildContext context, HomeViewModel homeVm) {
    final notifs = homeVm.notifications;

    if (notifs.isEmpty) {
      return Center(
        child: Text(
          'No notifications yet.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
      itemCount: notifs.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final notif = notifs[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: notif.type == 'called'
                  ? AppColors.success.withValues(alpha: 0.15)
                  : AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              notif.type == 'called'
                  ? Icons.campaign_rounded
                  : Icons.notifications_active_outlined,
              color: notif.type == 'called' ? AppColors.success : AppColors.primary,
              size: 20,
            ),
          ),
          title: Text(
            notif.title,
            style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(notif.message, style: AppTypography.bodySmall),
              const SizedBox(height: 4),
              Text(
                DateFormatter.formatDateTime(notif.createdAt),
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedLight,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
