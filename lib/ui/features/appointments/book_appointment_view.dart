import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easyqueue/core/constants/app_constants.dart';
import 'package:easyqueue/core/theme/app_colors.dart';
import 'package:easyqueue/core/theme/app_typography.dart';
import 'package:easyqueue/data/models/business_model.dart';
import 'package:easyqueue/data/models/branch_model.dart';
import 'package:easyqueue/data/models/service_model.dart';
import 'package:easyqueue/data/models/family_member_model.dart';
import 'package:easyqueue/ui/view_models/appointment_view_model.dart';
import 'package:easyqueue/ui/view_models/auth_view_model.dart';
import 'package:easyqueue/ui/view_models/family_view_model.dart';

class BookAppointmentView extends StatefulWidget {
  final BusinessModel business;
  final BranchModel branch;
  final ServiceModel service;

  const BookAppointmentView({
    super.key,
    required this.business,
    required this.branch,
    required this.service,
  });

  @override
  State<BookAppointmentView> createState() => _BookAppointmentViewState();
}

class _BookAppointmentViewState extends State<BookAppointmentView> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedSlot = '10:30 AM';
  FamilyMemberModel? _selectedBeneficiary;
  final TextEditingController _notesController = TextEditingController();

  final List<String> _slots = [
    '09:00 AM',
    '09:45 AM',
    '10:30 AM',
    '11:15 AM',
    '02:00 PM',
    '02:45 PM',
    '03:30 PM',
    '04:15 PM',
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aptVm = context.watch<AppointmentViewModel>();
    final authVm = context.watch<AuthViewModel>();
    final familyVm = context.watch<FamilyViewModel>();
    final user = authVm.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, AppConstants.bottomNavPadding),
        children: [
          // Service Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service.name,
                  style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.business.name} • ${widget.branch.name}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Select Date
          Text('Select Date', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildDateChoice(
                'Tomorrow',
                DateTime.now().add(const Duration(days: 1)),
              ),
              const SizedBox(width: 8),
              _buildDateChoice(
                'Day After',
                DateTime.now().add(const Duration(days: 2)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_month, size: 16),
                label: const Text('Pick Date'),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Select Slot
          Text('Available Time Slots', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _slots.map((slot) {
              final isSel = _selectedSlot == slot;
              return ChoiceChip(
                label: Text(slot),
                selected: isSel,
                onSelected: (_) => setState(() => _selectedSlot = slot),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Who is this for?
          Text('Who is this appointment for?', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Myself (${user?.displayName.split(' ').first ?? 'Self'})'),
                  selected: _selectedBeneficiary == null,
                  onSelected: (_) => setState(() => _selectedBeneficiary = null),
                ),
                const SizedBox(width: 8),
                ...familyVm.familyMembers.map((fam) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${fam.name} (${fam.relationship})'),
                      selected: _selectedBeneficiary?.id == fam.id,
                      onSelected: (_) => setState(() => _selectedBeneficiary = fam),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Special Notes
          Text('Special Requests / Notes', style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Any symptoms, accessibility needs, or notes for the staff...',
            ),
          ),
          const SizedBox(height: 28),

          // Book Button
          ElevatedButton(
            onPressed: (user != null && !aptVm.isLoading)
                ? () async {
                    // Combine date and time
                    final parts = _selectedSlot.split(' ');
                    final timeParts = parts[0].split(':');
                    int hour = int.parse(timeParts[0]);
                    int minute = int.parse(timeParts[1]);
                    if (parts[1] == 'PM' && hour < 12) hour += 12;
                    if (parts[1] == 'AM' && hour == 12) hour = 0;

                    final appointmentDateTime = DateTime(
                      _selectedDate.year,
                      _selectedDate.month,
                      _selectedDate.day,
                      hour,
                      minute,
                    );

                    await aptVm.bookAppointment(
                      customerId: user.id,
                      businessId: widget.business.id,
                      businessName: widget.business.name,
                      businessLogo: widget.business.logoUrl,
                      branchId: widget.branch.id,
                      branchName: widget.branch.name,
                      branchAddress: widget.branch.address,
                      serviceId: widget.service.id,
                      serviceName: widget.service.name,
                      appointmentTime: appointmentDateTime,
                      beneficiaryId: _selectedBeneficiary?.id,
                      beneficiaryName: _selectedBeneficiary?.name,
                      preparationNotes: _notesController.text.trim().isNotEmpty
                          ? _notesController.text.trim()
                          : widget.service.preparationInstructions,
                    );

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Appointment confirmed successfully!')),
                    );
                  }
                : null,
            child: aptVm.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Confirm Appointment Booking', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDateChoice(String label, DateTime date) {
    final isSel = _selectedDate.day == date.day && _selectedDate.month == date.month;
    return ChoiceChip(
      label: Text(label),
      selected: isSel,
      onSelected: (_) => setState(() => _selectedDate = date),
    );
  }
}
