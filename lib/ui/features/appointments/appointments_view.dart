import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/core/utils/date_formatter.dart';
import 'package:easyqueue/data/models/appointment_model.dart';
import 'package:easyqueue/ui/view_models/appointment_view_model.dart';
import 'package:easyqueue/ui/features/queue/digital_ticket_screen.dart';

class AppointmentsView extends StatelessWidget {
  const AppointmentsView({super.key});

  @override
  Widget build(BuildContext context) {
    final aptVm = context.watch<AppointmentViewModel>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Appointments',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMutedLight,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Past / History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildUpcomingTab(context, aptVm),
            _buildPastTab(context, aptVm),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingTab(BuildContext context, AppointmentViewModel aptVm) {
    final upcoming = aptVm.upcomingAppointments;

    if (upcoming.isEmpty) {
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
                child: const Icon(Icons.calendar_today_outlined, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No Upcoming Appointments',
                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Book an appointment slot for clinics, labs, or bank services to skip the physical line.',
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
      itemCount: upcoming.length,
      itemBuilder: (context, index) {
        final apt = upcoming[index];
        return _buildAppointmentCard(context, aptVm, apt);
      },
    );
  }

  Widget _buildPastTab(BuildContext context, AppointmentViewModel aptVm) {
    final past = aptVm.pastAppointments;

    if (past.isEmpty) {
      return Center(
        child: Text(
          'No past appointment history.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
      itemCount: past.length,
      itemBuilder: (context, index) {
        final apt = past[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(apt.serviceName, style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text('${apt.businessName} • ${DateFormatter.formatDateTime(apt.appointmentTime)}'),
            trailing: Chip(
              label: Text(apt.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.backgroundLight,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    AppointmentViewModel aptVm,
    AppointmentModel apt,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.event_available_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      apt.serviceName,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${apt.businessName} • ${apt.branchName}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CONFIRMED',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.dividerLight),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    DateFormatter.formatDateTime(apt.appointmentTime),
                    style: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (apt.beneficiaryName != null)
                Text(
                  'Patient: ${apt.beneficiaryName}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.secondary, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          if (apt.preparationNotes != null) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${apt.preparationNotes}',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
          const SizedBox(height: 16),

          // Check-In Action (UC-050: Arrival Check-in -> generates queue token!)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(40),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.how_to_reg_outlined, size: 18),
                  label: const Text('Arrived? Check In to Queue', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    final entryId = await aptVm.checkInAppointment(apt.id);
                    if (context.mounted && entryId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DigitalTicketScreen(entryId: entryId),
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                tooltip: 'Cancel Appointment',
                onPressed: () => _confirmCancel(context, aptVm, apt.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmCancel(BuildContext context, AppointmentViewModel aptVm, String aptId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to release this booked slot?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              aptVm.cancelAppointment(aptId);
            },
            child: const Text('Cancel Slot'),
          ),
        ],
      ),
    );
  }
}
